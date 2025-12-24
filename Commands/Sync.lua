-- Commands/Sync.lua
-- Admin-only sync command with stop control

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
        -- REMOTE
        ----------------------------------------------------------------
        local commandHandler =
            ReplicatedStorage
                :WaitForChild("Connections")
                :WaitForChild("dataProviders")
                :WaitForChild("commandHandler")

        ----------------------------------------------------------------
        -- STATE
        ----------------------------------------------------------------
        local syncActive = false

        ----------------------------------------------------------------
        -- SYNC FUNCTION
        ----------------------------------------------------------------
        local function doSync(targetPlayer)
            if not targetPlayer then return end
            if not syncActive then return end

            pcall(function()
                commandHandler:InvokeServer(
                    "sync",
                    targetPlayer.UserId
                )
            end)
        end

        ----------------------------------------------------------------
        -- STOP SYNC
        ----------------------------------------------------------------
        local function stopSync()
            syncActive = false
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)
            msg = msg:lower()

            if not Admin:IsAdmin(sender) then
                return
            end

            if msg == "!sync" then
                syncActive = true
                doSync(sender)

            elseif msg == "!stop" then
                stopSync()
            end
        end

        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE (NEW CHAT)
        ----------------------------------------------------------------
        if TextChatService and TextChatService.TextChannels then
            local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                channel.OnIncomingMessage = function(message)
                    local uid = message.TextSource and message.TextSource.UserId
                    local sender = uid and Players:GetPlayerByUserId(uid)
                    if sender then
                        handleCommand(message.Text, sender)
                    end
                end
            end
        end

        ----------------------------------------------------------------
        -- FALLBACK CHAT (OLD CHAT)
        ----------------------------------------------------------------
        for _, player in ipairs(Players:GetPlayers()) do
            player.Chatted:Connect(function(msg)
                handleCommand(msg, player)
            end)
        end

        Players.PlayerAdded:Connect(function(player)
            player.Chatted:Connect(function(msg)
                handleCommand(msg, player)
            end)
        end)
    end
}
