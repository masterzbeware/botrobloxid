-- Commands/PushUp.lua
-- Bot otomatis melakukan animasi Push Up ketika admin mengetik !pushup
return {
    Execute = function()
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end

        -- 🔗 Load Admin module
        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        local function playPushUpAnimation()
            print("[DEBUG] Mencoba memainkan animasi Push Up")
            local success, err = pcall(function()
                local connections = ReplicatedStorage:WaitForChild("Connections")
                local dataProviders = connections:WaitForChild("dataProviders")
                local animationHandler = dataProviders:WaitForChild("animationHandler")
                animationHandler:InvokeServer("playAnimation", "Push Up")
            end)
            if success then
                print("[DEBUG] Animasi Push Up berhasil dijalankan")
            else
                warn("[DEBUG] Gagal memainkan animasi Push Up:", err)
            end
        end

        local function handleCommand(msg, sender)
            msg = msg:lower()
            local isAdmin = Admin:IsAdmin(sender)
            print("[DEBUG] Player:", sender.Name, "UserId:", sender.UserId, "IsAdmin:", tostring(isAdmin), "Command:", msg)
            if not isAdmin then return end

            if msg == "!pushup" then
                playPushUpAnimation()
            end
        end

        -- TextChatService listener
        if TextChatService and TextChatService.TextChannels then
            local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                channel.OnIncomingMessage = function(message)
                    local userId = message.TextSource and message.TextSource.UserId
                    local sender = userId and Players:GetPlayerByUserId(userId)
                    if sender then
                        handleCommand(message.Text, sender)
                    end
                end
            end
        end

        -- Fallback lama
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
