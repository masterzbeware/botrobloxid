-- Weather.lua
-- Command: !cuaca {daerah}
-- Semua pemain bisa menjalankan
-- Hanya bot dengan ToggleGames aktif yang mengeksekusi
-- Delay global 6 detik (untuk semua pemain)
-- Mengambil data cuaca real dari OpenWeatherMap

local HttpService = game:GetService("HttpService")
local lastWeatherCheck = 0 -- global timestamp

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- ✅ Cek ToggleGames (harus true)
        if vars.ToggleGames ~= true then
            return
        end

        -- ✅ Cek API Key
        local apiKey = vars.OpenWeatherKey
        if not apiKey or apiKey == "" then
            warn("OpenWeatherMap API Key belum diset di _G.BotVars.OpenWeatherKey")
            return
        end

        -- ⏳ Cek cooldown global 6 detik
        local now = os.time()
        if now - lastWeatherCheck < 6 then
            return
        end
        lastWeatherCheck = now

        -- 🔡 Ambil argumen
        local args = {}
        for word in msg:gmatch("%S+") do
            table.insert(args, word)
        end
        if #args < 2 then
            return -- tidak ada daerah
        end

        local daerah = args[2]

        -- 🌍 URL API OpenWeather
        local url = string.format(
            "https://api.openweathermap.org/data/2.5/weather?q=%s&appid=%s&units=metric&lang=id",
            HttpService:UrlEncode(daerah),
            apiKey
        )

        local success, response = pcall(function()
            return HttpService:GetAsync(url)
        end)

        local hasil = nil
        if success then
            local data = HttpService:JSONDecode(response)
            if data and data.weather and data.main then
                local kondisi = data.weather[1].description or "Tidak diketahui"
                local suhu = data.main.temp or "?"
                hasil = string.format("Cuaca di %s: %s, suhu %.1f°C", daerah, kondisi, suhu)
            else
                hasil = "Gagal membaca data cuaca untuk " .. daerah
            end
        else
            hasil = "Gagal mengambil data cuaca untuk " .. daerah
        end

        -- 💬 Kirim pesan
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel and hasil then
            pcall(function()
                channel:SendAsync(hasil)
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
