-- Stop.lua
-- Command !stop: Menghentikan semua aksi bot (follow, shield, row, sync, pushup, frontline, circle, reporting, ModeBuaya, RoomVIP, logchat)
-- Termasuk mereset whitelist dan memutus semua koneksi aktif

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

        -- 🔹 Hentikan semua koneksi / loop utama
        local function safeDisconnect(connName)
            if vars[connName] then
                pcall(function()
                    if typeof(vars[connName]) == "RBXScriptConnection" then
                        vars[connName]:Disconnect()
                    elseif typeof(vars[connName]) == "thread" then
                        task.cancel(vars[connName])
                    end
                end)
                vars[connName] = nil
            end
        end

        local disconnectList = {
            "FollowConnection",
            "ShieldConnection",
            "RowConnection",
            "PushupConnection",
            "SyncConnection",
            "CircleMoveConnection",
            "ModeBuayaChatConnection",
            "RoomVIPConnection",
        }

        for _, name in ipairs(disconnectList) do
            safeDisconnect(name)
        end

        -- 🔹 Hentikan task async (spawn / loop) tambahan
        local cancelList = {
            "RoomVIPTask",
        }

        for _, name in ipairs(cancelList) do
            if vars[name] then
                pcall(function() task.cancel(vars[name]) end)
                vars[name] = nil
            end
        end

        -- 🔹 Stop animasi Push Up jika masih berjalan
        pcall(function()
            local args = { "stopAnimation", "Push Up" }
            local animationHandler = game:GetService("ReplicatedStorage")
                :WaitForChild("Connections")
                :WaitForChild("dataProviders")
                :WaitForChild("animationHandler")
            animationHandler:InvokeServer(unpack(args))
        end)

        -- 🔹 Leave Sync jika masih aktif
        pcall(function()
            local args = { "leaveSync" }
            local animationHandler = game:GetService("ReplicatedStorage")
                :WaitForChild("Connections")
                :WaitForChild("dataProviders")
                :WaitForChild("animationHandler")
            animationHandler:InvokeServer(unpack(args))
        end)

        -- 🔹 Matikan listener LogChat.lua jika aktif
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
            for _, playerObj in ipairs(Players:GetPlayers()) do
                if playerObj.Chatted then
                    pcall(function()
                        playerObj.Chatted:Connect(function() end)
                    end)
                end
            end

            print("[LogChat] Semua listener chat dimatikan oleh !stop.")
        end

        -- 🔹 Reset whitelist target
        if vars.WhitelistTargets then
            vars.WhitelistTargets = {}
            print("[Stop] Whitelist target telah di-reset.")
        end

        -- 🔹 Reset flag RoomVIP
        vars.RoomVIPActive = false

        -- 🔹 Log output
        print("[COMMAND] Semua aktivitas bot dihentikan oleh:", client and client.Name or "Unknown")
    end
}
