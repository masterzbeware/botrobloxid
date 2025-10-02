-- Weather.lua
-- Command: !cuaca {daerah}
-- Semua pemain bisa menjalankan
-- Hanya bot dengan ToggleGames aktif yang mengeksekusi
-- Delay global 6 detik (untuk semua pemain)
-- Mengambil data cuaca real dari wttr.in (tanpa API Key)

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

        -- gabung semua argumen jadi nama daerah (supaya bisa support nama lebih dari 1 kata, contoh: "jawa barat")
        local daerah = table.concat(args, " ", 2)

        -- 🌍 URL API wttr.in
        local url = string.format("https://wttr.in/%s?format=j1", HttpService:UrlEncode(daerah))

        local success, response = pcall(function()
            return HttpService:GetAsync(url)
        end)

        local hasil = nil
        if success then
            local data = HttpService:JSONDecode(response)
            if data and data.current_condition and data.current_condition[1] then
                local kondisi = data.current_condition[1].weatherDesc[1].value or "Tidak diketahui"
                local suhu = data.current_condition[1].temp_C or "?"
                hasil = string.format("Cuaca di %s: %s, suhu %s°C", daerah, kondisi, suhu)
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
