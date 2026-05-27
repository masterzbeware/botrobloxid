-- Commands/Broadcast.lua
-- Command: !broadcast <text>
-- Contoh:
-- !broadcast halo semua
-- Bot akan mengirim: halo semua

return {
    Execute = function()
        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then
            return
        end

        ----------------------------------------------------------------
        -- LOAD ADMIN MODULE
        ----------------------------------------------------------------
        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- GLOBAL VARS
        ----------------------------------------------------------------
        _G.BotVars = _G.BotVars or {}
        local vars = _G.BotVars

        -- disconnect old listener
        if vars.BroadcastConnection then
            vars.BroadcastConnection:Disconnect()
            vars.BroadcastConnection = nil
        end

        if vars.BroadcastLegacyConnections then
            for _, conn in ipairs(vars.BroadcastLegacyConnections) do
                pcall(function()
                    conn:Disconnect()
                end)
            end
        end

        vars.BroadcastLegacyConnections = {}

        ----------------------------------------------------------------
        -- SEND CHAT
        ----------------------------------------------------------------
        local function sendChat(msg)
            local ok = false

            if TextChatService and TextChatService.TextChannels then
                local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")

                if ch then
                    pcall(function()
                        ch:SendAsync(msg)
                    end)

                    ok = true
                end
            end

            if not ok then
                pcall(function()
                    ReplicatedStorage.DefaultChatSystemChatEvents
                        .SayMessageRequest
                        :FireServer(msg, "All")
                end)
            end
        end

        ----------------------------------------------------------------
        -- HANDLE COMMAND
        ----------------------------------------------------------------
        local function handleChat(msg, sender)
            if not msg or not sender then
                return
            end

            if sender == LocalPlayer then
                return
            end

            -- hanya admin
            if not Admin:IsAdmin(sender) then
                return
            end

            local lower = msg:lower()

            -- cek command
            if lower:sub(1, 11) == "!broadcast" then
                local text = msg:sub(12)

                -- hapus spasi depan
                text = text:match("^%s*(.-)%s*$")

                if text ~= "" then
                    sendChat(text)
                end
            end
        end

        ----------------------------------------------------------------
        -- TEXTCHATSERVICE
        ----------------------------------------------------------------
        if TextChatService and TextChatService.MessageReceived then
            vars.BroadcastConnection =
                TextChatService.MessageReceived:Connect(function(message)

                local uid = message.TextSource
                    and message.TextSource.UserId

                local sender = uid
                    and Players:GetPlayerByUserId(uid)

                if sender then
                    handleChat(message.Text, sender)
                end
            end)

        else
            ----------------------------------------------------------------
            -- LEGACY CHAT
            ----------------------------------------------------------------
            local function connectPlayer(p)
                local conn = p.Chatted:Connect(function(msg)
                    handleChat(msg, p)
                end)

                table.insert(vars.BroadcastLegacyConnections, conn)
            end

            for _, p in ipairs(Players:GetPlayers()) do
                connectPlayer(p)
            end

            local addedConn = Players.PlayerAdded:Connect(function(p)
                connectPlayer(p)
            end)

            table.insert(vars.BroadcastLegacyConnections, addedConn)
        end
    end
}