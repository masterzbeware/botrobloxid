-- Stop.lua
-- Command !stop: Menghentikan semua aksi bot (follow, shield, row, sync, pushup, frontline, circle, reporting, logchat)
-- Termasuk mereset whitelist target

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}

        -- 🔹 Nonaktifkan semua mode utama
        vars.FollowAllowed = false
        vars.ShieldActive = false
        vars.RowActive = false
        vars.SyncActive = false
        vars.PushupActive = false
        vars.FrontlineActive = false
        vars.CircleMoveActive = false
        vars.ReportingActive = false
        vars.CurrentFormasiTarget = nil

        -- 🔹 Hentikan semua koneksi / loop jika ada
        if vars.FollowConnection then
            pcall(function() vars.FollowConnection:Disconnect() end)
            vars.FollowConnection = nil
        end

        if vars.ShieldConnection then
            pcall(function() vars.ShieldConnection:Disconnect() end)
            vars.ShieldConnection = nil
        end

        if vars.RowConnection then
            pcall(function() vars.RowConnection:Disconnect() end)
            vars.RowConnection = nil
        end

        if vars.PushupConnection then
            pcall(function() task.cancel(vars.PushupConnection) end)
            vars.PushupConnection = nil
        end

        if vars.SyncConnection then
            pcall(function() task.cancel(vars.SyncConnection) end)
            vars.SyncConnection = nil
        end

        if vars.CircleMoveConnection then
            pcall(function() vars.CircleMoveConnection:Disconnect() end)
            vars.CircleMoveConnection = nil
        end

        -- 🔹 Stop animasi push-up kalau masih berjalan
        pcall(function()
            local args = { "stopAnimation", "Push Up" }
            local animationHandler = game:GetService("ReplicatedStorage")
                                        :WaitForChild("Connections")
                                        :WaitForChild("dataProviders")
                                        :WaitForChild("animationHandler")
            animationHandler:InvokeServer(unpack(args))
        end)

        -- 🔹 Kirim leaveSync supaya benar-benar unsync dari server
        pcall(function()
            local args = { "leaveSync" }
            local animationHandler = game:GetService("ReplicatedStorage")
                                        :WaitForChild("Connections")
                                        :WaitForChild("dataProviders")
                                        :WaitForChild("animationHandler")
            animationHandler:InvokeServer(unpack(args))
        end)

        -- 🔹 Matikan listener LogChat.lua
        if _G.ChatLogListenerSet then
            _G.ChatLogListenerSet = false

            local TextChatService = game:GetService("TextChatService")
            if TextChatService and TextChatService.TextChannels then
                local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if generalChannel and generalChannel.OnIncomingMessage then
                    generalChannel.OnIncomingMessage = nil
                end
            end

            local Players = game:GetService("Players")
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Chatted then
                    pcall(function()
                        player.Chatted:Connect(function() end)
                    end)
                end
            end

            print("[LogChat] Semua listener chat dimatikan oleh !stop.")
        end

        -- 🔹 Bersihkan whitelist target
        if vars.WhitelistTargets then
            vars.WhitelistTargets = {}
            print("[Stop] Whitelist target telah di-reset.")
        end

        -- 🔹 Log output
        print("[COMMAND] Bot stopped by client:", client and client.Name or "Unknown")
    end
}
