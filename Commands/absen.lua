-- Absen.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")

        local localPlayer = vars.LocalPlayer or Players.LocalPlayer
        local identity = vars.BotIdentity or "Unknown Bot"

        -- Daftar urutan bot fix
        local orderedBots = {
            "Bot1 - XBODYGUARDVIP01",
            "Bot2 - XBODYGUARDVIP02",
            "Bot3 - XBODYGUARDVIP03",
            "Bot4 - XBODYGUARDVIP04"
        }

        -- Tentukan index bot
        local index = 1
        for i, botName in ipairs(orderedBots) do
            if botName == identity then
                index = i
                break
            end
        end

        -- Kirim chat awal
        local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
        if channel then
            pcall(function()
                channel:SendAsync("Absen dimulai! " .. identity .. " hadir.")
            end)
        end

        -- Delay sebelum total hadir diumumkan
        task.delay(2, function()
            if channel then
                pcall(function()
                    channel:SendAsync(identity .. " berada di urutan ke-" .. tostring(index))
                end)
            end
        end)
    end
}
