-- Absen.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = vars.Players or game:GetService("Players")
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")
        local localPlayer = vars.LocalPlayer or Players.LocalPlayer

        -- Toggle aktif
        if not vars.ToggleAktif then return end

        -- Ambil semua bot yang online
        local onlineBots = {}
        for idStr, name in pairs(vars.BotMapping or {}) do
            local player = Players:GetPlayerByUserId(tonumber(idStr))
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(onlineBots, player)
            end
        end

        if #onlineBots == 0 then return end

        -- Fungsi chat global
        local function sendGlobalMessage(text)
            local channel = TextChatService.TextChannels.RBXGeneral
            if channel then
                channel:SendAsync(text)
            end
        end

        -- Bot pertama akan memulai
        if localPlayer == onlineBots[1] then
            spawn(function()
                sendGlobalMessage("Siap laksanakan! Mulai Berhitung")
                wait(1.5)
                for i, bot in ipairs(onlineBots) do
                    sendGlobalMessage(tostring(i))
                    wait(1.5)
                end
            end)
        end
    end
}
