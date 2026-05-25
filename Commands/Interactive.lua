-- Commands/Interactive.lua
-- Admin-only interactive system
-- Supports: !interactive
-- Function: enable interactive mode

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

        local mapState = dataProviders:WaitForChild("mapState")
        local playerReplication = dataProviders:WaitForChild("playerReplication")

        ----------------------------------------------------------------
        -- SEND CHAT
        ----------------------------------------------------------------
        local function sendChat(msg)
            pcall(function()
                if TextChatService and TextChatService.TextChannels then
                    local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                    if ch then
                        ch:SendAsync(msg)
                        return
                    end
                end

                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
                    :FireServer(msg, "All")
            end)
        end

        ----------------------------------------------------------------
        -- ENABLE INTERACTIVE
        ----------------------------------------------------------------
        local function enableInteractive()
            -- Ambil state door interactive
            pcall(function()
                mapState:InvokeServer("getInteractiveDoorState")
            end)

            -- Aktifkan interactive
            pcall(function()
                playerReplication:FireServer("setInteractive", true)
            end)

            sendChat("Interactive enabled!")
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)
            if not Admin:IsAdmin(sender) then return end

            local lower = msg:lower()

            if lower == "!interactive" then
                enableInteractive()
                return
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