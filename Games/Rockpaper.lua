-- Rockpaper.lua
-- Semua pemain bisa menjalankan !rockpaper
-- Bot harus ToggleGames aktif
-- Delay global 6 detik (untuk semua pemain)
-- Bisa !rockpaper [batu/kertas/gunting] atau !rockpaper

local lastPlayed = 0 -- global timestamp (bukan per pemain)

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
        if now - lastPlayed < 6 then
            -- opsional: kirim pesan "Tunggu sebentar" ke pemain
            return
        end
        lastPlayed = now

        local options = { "Batu", "Kertas", "Gunting" }

        -- 🔡 Ambil argumen dari command
        local args = {}
        for word in msg:gmatch("%S+") do
            table.insert(args, word)
        end

        local playerChoice
        if #args >= 2 then
            local input = args[2]:lower()
            if input == "batu" then
                playerChoice = "Batu"
            elseif input == "kertas" then
                playerChoice = "Kertas"
            elseif input == "gunting" then
                playerChoice = "Gunting"
            else
                playerChoice = options[math.random(1, #options)]
            end
        else
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
                channel:SendAsync(client.Name .. " memilih: " .. playerChoice .. " ... Saya memilih: " .. botChoice .. "!")
                task.wait(3)
                channel:SendAsync("Hasil: " .. outcome)
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
