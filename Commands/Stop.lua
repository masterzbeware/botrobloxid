-- Stop.lua
-- Command !stop: Menghentikan semua aksi bot, termasuk Barrier, Wedge, Square, dsb.

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}

        -- Nonaktifkan semua mode utama
        vars.FollowAllowed = false
        vars.ShieldActive = false
        vars.RowActive = false
        vars.SquareActive = false
        vars.WedgeActive = false
        vars.BarrierActive = false
        vars.SyncActive = false
        vars.PushupActive = false
        vars.FrontlineActive = false
        vars.CircleMoveActive = false
        vars.ReportingActive = false
        vars.RoomVIPActive = false
        vars.CurrentFormasiTarget = nil

        -- Fungsi bantu untuk memutus koneksi aman
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

        -- Daftar koneksi utama yang akan dihentikan
        local disconnectList = {
            "FollowConnection",
            "ShieldConnection",
            "RowConnection",
            "SquareConnection",
            "WedgeConnection",
            "BarrierConnection",
            "PushupConnection",
            "SyncConnection",
            "CircleMoveConnection",
            "ModeBuayaChatConnection",
            "RoomVIPConnection",
        }

        for _, name in ipairs(disconnectList) do
            safeDisconnect(name)
        end

        -- Hentikan task async tambahan
        local cancelList = { "RoomVIPTask" }
        for _, name in ipairs(cancelList) do
            if vars[name] then
                pcall(function() task.cancel(vars[name]) end)
                vars[name] = nil
            end
        end

        -- Stop animasi Push Up jika masih berjalan
        pcall(function()
            local args = { "stopAnimation", "Push Up" }
            local animationHandler = game:GetService("ReplicatedStorage")
                :WaitForChild("Connections")
                :WaitForChild("dataProviders")
                :WaitForChild("animationHandler")
            animationHandler:InvokeServer(unpack(args))
        end)

        -- Leave Sync jika masih aktif
        pcall(function()
            local args = { "leaveSync" }
            local animationHandler = game:GetService("ReplicatedStorage")
                :WaitForChild("Connections")
                :WaitForChild("dataProviders")
                :WaitForChild("animationHandler")
            animationHandler:InvokeServer(unpack(args))
        end)

        -- Matikan listener LogChat.lua jika aktif
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
        end

        -- Reset whitelist target
        if vars.WhitelistTargets then
            vars.WhitelistTargets = {}
        end

        -- Reset flag RoomVIP
        vars.RoomVIPActive = false

        -- Log output
        print("[COMMAND] Semua aktivitas bot dihentikan oleh:", client and client.Name or "Unknown")
    end
}
