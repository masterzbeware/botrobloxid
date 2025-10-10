-- Location.lua
-- Command: !location {displayname/username}
-- Menampilkan apakah pemain ada di server yang sama

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = game:GetService("Players")

        -- Sistem chat seragam
        local TextChatService = game:GetService("TextChatService")
        local channel
        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        -- Ambil argumen setelah !location
        local args = string.split(msg, " ")
        local targetName = args[2]

        -- Cek player di server
        local foundPlayer = nil
        if targetName then
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower() == targetName:lower()
                or (player.DisplayName and player.DisplayName:lower() == targetName:lower()) then
                    foundPlayer = player
                    break
                end
            end
        end

        -- Fungsi kirim chat
        local function sendChat(text)
            if channel then
                pcall(function()
                    channel:SendAsync(text)
                end)
            else
                warn("Channel RBXGeneral tidak ditemukan!")
            end
        end

        -- Kirim hasil lokasi
        if foundPlayer then
            sendChat("Player " .. foundPlayer.DisplayName .. " (@" .. foundPlayer.Name .. ") ada di server yang sama.")
        else
            sendChat("Player " .. tostring(targetName) .. " tidak ada di server ini.")
        end
    end
}
