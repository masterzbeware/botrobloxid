-- Commands/Sync.lua
-- Admin-only sync + real stop (leaveSync)

return {
    Execute = function()
        -- SERVICES
        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end

        -- LOAD ADMIN MODULE
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

        ----------------------------------------------------------------
        -- SYNC
        ----------------------------------------------------------------
        local function startSync(targetPlayer)
            if not targetPlayer then return end
            syncing = true

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

            pcall(function()
                animationHandler:InvokeServer("leaveSync")
            end)
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)
            msg = msg:lower()
            if not Admin:IsAdmin(sender) then return end

            if msg == "!sync" then
                startSync(sender)

            elseif msg == "!stop" then
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
