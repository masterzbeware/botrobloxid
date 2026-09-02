-- Commands/Sync.lua
-- Admin-only sync system
-- Supports: !sync / !sync <username|displayname>
-- Real stop: leaveSync

return {
    Execute = function()
        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------
        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end

        ----------------------------------------------------------------
        -- LOAD ADMIN MODULE
        ----------------------------------------------------------------
        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- REMOTES
        ----------------------------------------------------------------
        local connections = ReplicatedStorage:WaitForChild("Connections")
        local dataProviders = connections:WaitForChild("dataProviders")

        local commandHandler = dataProviders:WaitForChild("commandHandler")
        local animationHandler = dataProviders:WaitForChild("animationHandler")

        ----------------------------------------------------------------
        -- SYNC STATE
        ----------------------------------------------------------------
        local syncing = false
        local currentTarget -- Player

        ----------------------------------------------------------------
        -- FIND PLAYER BY NAME / DISPLAY NAME
        ----------------------------------------------------------------
        local function findPlayerByName(name)
            name = name:lower()
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower() == name or p.DisplayName:lower() == name then
                    return p
                end
            end
            return nil
        end

        ----------------------------------------------------------------
        -- START SYNC
        ----------------------------------------------------------------
        local function startSync(targetPlayer)
            if not targetPlayer then return end

            -- prevent duplicate sync to same target
            if syncing and currentTarget == targetPlayer then
                return
            end

            syncing = true
            currentTarget = targetPlayer

            pcall(function()
                commandHandler:InvokeServer(
                    "sync",
                    targetPlayer.UserId
                )
            end)
        end

        ----------------------------------------------------------------
        -- STOP SYNC (REAL)
        ----------------------------------------------------------------
        local function stopSync()
            if not syncing then return end
            syncing = false
            currentTarget = nil

            pcall(function()
                animationHandler:InvokeServer("leaveSync")
            end)
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER (ADMIN ONLY)
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)
            if not Admin:IsAdmin(sender) then return end

            local lower = msg:lower()

            -- !sync
            if lower == "!sync" then
                startSync(sender)
                return
            end

            -- !sync <name>
            local targetName = lower:match("^!sync%s+(.+)$")
            if targetName then
                local target = findPlayerByName(targetName)
                if target then
                    startSync(target)
                end
                return
            end

            -- stop
            if lower == "!stop" or lower == "!unsync" then
                stopSync()
            end
        end

        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE
        ----------------------------------------------------------------
        if TextChatService and TextChatService.TextChannels then
            local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if ch then
                ch.OnIncomingMessage = function(message)
                    local uid = message.TextSource and message.TextSource.UserId
                    local sender = uid and Players:GetPlayerByUserId(uid)
                    if sender then
                        handleCommand(message.Text, sender)
                    end
                end
            end
        end

        ----------------------------------------------------------------
        -- FALLBACK CHAT
        ----------------------------------------------------------------
        for _, p in ipairs(Players:GetPlayers()) do
            p.Chatted:Connect(function(msg)
                handleCommand(msg, p)
            end)
        end

        Players.PlayerAdded:Connect(function(p)
            p.Chatted:Connect(function(msg)
                handleCommand(msg, p)
            end)
        end)
    end
}
