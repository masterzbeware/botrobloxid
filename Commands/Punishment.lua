-- Punishment.lua
return {
    Execute = function(msg, client)
        -- Pastikan command yang dimaksud
        if msg:lower() ~= "!pushup" then return end

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local localPlayer = Players.LocalPlayer
        local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral

        -- Mainkan animasi "Push Up" via RemoteFunction
        local success, err = pcall(function()
            local animationHandler = game:GetService("ReplicatedStorage")
                :WaitForChild("Connections")
                :WaitForChild("dataProviders")
                :WaitForChild("animationHandler")
            animationHandler:InvokeServer("playAnimation", "Push Up")
        end)
        if not success then
            warn("Gagal memicu animasi Push Up: " .. tostring(err))
        end

        -- Kirim chat "JAYA JAYA JAYA"
        if channel then
            pcall(function()
                channel:SendAsync("JAYA JAYA JAYA")
            end)
        end
    end
}
