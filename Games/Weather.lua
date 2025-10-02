-- Weather.lua
-- Command: !cuaca {daerah}
-- Semua pemain bisa menjalankan
-- Hanya bot dengan ToggleGames aktif yang mengeksekusi
-- Delay global 6 detik (untuk semua pemain)
-- Mengambil data cuaca real dari api.met.no (tanpa API key)

local HttpService = game:GetService("HttpService")
local lastWeatherCheck = 0 -- global timestamp

-- 🗺️ Mapping nama kota → koordinat (lat, lon)
local lokasi = {
    jakarta = { lat = -6.2, lon = 106.8 },
    depok   = { lat = -6.4, lon = 106.8 },
    bandung = { lat = -6.9, lon = 107.6 },
    surabaya= { lat = -7.2, lon = 112.7 },
    medan   = { lat = 3.6, lon = 98.7 },
    bali    = { lat = -8.6, lon = 115.2 },
    sumatera= { lat = -0.9, lon = 100.4 }
}

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

        local daerah = args[2]:lower()
        local pos = lokasi[daerah]
        if not pos then
            local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                pcall(function()
                    channel:SendAsync("Daerah '" .. daerah .. "' belum terdaftar.")
                end)
            end
            return
        end

        -- 🌍 URL API MET Norway
        local url = string.format(
            "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=%s&lon=%s",
            pos.lat, pos.lon
        )

        local success, response = pcall(function()
            return HttpService:GetAsync(url)
        end)

        local hasil = nil
        if success then
            local data = HttpService:JSONDecode(response)
            if data and data.properties and data.properties.timeseries and data.properties.timeseries[1] then
                local current = data.properties.timeseries[1].data
                local temp = current.instant.details.air_temperature or "?"
                local wind = current.instant.details.wind_speed or "?"
                hasil = string.format("Cuaca di %s: Suhu %.1f°C, Angin %.1f m/s", daerah, temp, wind)
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
