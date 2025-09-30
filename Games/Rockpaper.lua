-- Rockpaper.lua
-- Command: Semua pemain bisa menjalankan
-- Hanya bot dengan ToggleGameActive aktif yang mengeksekusi
-- Delay global 15 detik per pemain
local lastUsed = {} -- Menyimpan waktu terakhir tiap pemain menjalankan command

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")
        local plrName = client.Name

        -- Cek ToggleGameActive
        if vars.ToggleGameActive ~= true then
            return
        end

        -- Cek delay 15 detik
        local currentTime = tick()
        if lastUsed[plrName] and currentTime - lastUsed[plrName] < 15 then
            return -- Lewati jika belum 15 detik
        end
        lastUsed[plrName] = currentTime

        -- Pilihan: Batu, Kertas, Gunting
        local options = { "Batu", "Kertas", "Gunting" }

        -- Pilihan pemain
        local playerChoice = options[math.random(1, #options)]

        -- Pilihan bot berdasarkan chance kemenangan
        local resultRoll = math.random() -- 0.0 - 1.0 untuk menentukan hasil
        local botChoice
        if resultRoll < 0.33 then
            -- Bot menang
            if playerChoice == "Batu" then botChoice = "Kertas"
            elseif playerChoice == "Kertas" then botChoice = "Gunting"
            else botChoice = "Batu"
            end
        elseif resultRoll < 0.66 then
            -- Bot kalah
            if playerChoice == "Batu" then botChoice = "Gunting"
            elseif playerChoice == "Kertas" then botChoice = "Batu"
            else botChoice = "Kertas"
            end
        else
            -- Seri
            botChoice = playerChoice
        end

        -- Kirim hasil ke RBXGeneral dalam satu pesan
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            pcall(function()
                channel:SendAsync(plrName .. " memilih: " .. playerChoice .. ". Saya memilih: " .. botChoice)
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
