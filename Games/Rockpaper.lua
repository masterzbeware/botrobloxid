-- Rockpaper.lua
-- Command: Semua pemain bisa menjalankan
-- Hanya bot dengan ToggleGames aktif yang mengeksekusi
-- Delay global 15 detik per pemain
-- Bisa !rockpaper [batu/kertas/gunting] atau !rockpaper
-- Pesan pertama: pilihan, tunggu 3 detik, pesan kedua: hasil

local lastPlayed = {} -- table untuk menyimpan waktu terakhir tiap pemain

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- ✅ Cek ToggleGames (harus true)
        if vars.ToggleGames ~= true then
            return
        end

        -- ⏳ Cek cooldown 15 detik per pemain
        local now = os.time()
        if lastPlayed[client.UserId] and now - lastPlayed[client.UserId] < 15 then
            return
        end
        lastPlayed[client.UserId] = now

        local options = { "Batu", "Kertas", "Gunting" }

        -- 🔡 Ambil argumen dari command
        local args = {}
        for word in msg:gmatch("%S+") do
            table.insert(args, word)
        end

        local playerChoice
        if #args >= 2 then
            -- Jika pemain menentukan pilihan
            local input = args[2]:lower()
            if input == "batu" then
                playerChoice = "Batu"
            elseif input == "kertas" then
                playerChoice = "Kertas"
            elseif input == "gunting" then
                playerChoice = "Gunting"
            else
                -- Pilihan tidak valid → random
                playerChoice = options[math.random(1, #options)]
            end
        else
            -- Tidak ada argumen → random
            playerChoice = options[math.random(1, #options)]
        end

        local botChoice = options[math.random(1, #options)]

        -- 🏆 Tentukan hasil
        local outcome
        if playerChoice == botChoice then
            outcome = "Seri!"
        elseif (playerChoice == "Batu" and botChoice == "Gunting")
            or (playerChoice == "Gunting" and botChoice == "Kertas")
            or (playerChoice == "Kertas" and botChoice == "Batu") then
            outcome = "Kamu menang!"
        else
            outcome = "Bot menang!"
        end

        -- 💬 Kirim pesan ke RBXGeneral
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            pcall(function()
                -- Pesan pertama: pilihan
                channel:SendAsync(client.Name .. " memilih: " .. playerChoice .. " ... Saya memilih: " .. botChoice .. "!")
                -- Tunggu 3 detik sebelum kirim hasil
                task.wait(3)
                -- Pesan kedua: hasil
                channel:SendAsync("Hasil: " .. outcome)
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
