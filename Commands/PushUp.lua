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
            print("[DEBUG] Memainkan animasi Push Up")
            local success, err = pcall(function()
                local animationHandler = ReplicatedStorage:WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                animationHandler:InvokeServer("playAnimation", "Push Up")
            end)
            if success then
                print("[DEBUG] Animasi Push Up berhasil dijalankan")
            else
                warn("[DEBUG] Gagal memainkan animasi Push Up:", err)
            end
        end

        -- Handle chat commands dari admin
        local function handleCommand(msg, sender)
            if not Admin:IsAdmin(sender) then 
                print("[DEBUG] Player bukan admin, abaikan command:", sender.Name)
                return 
            end
            msg = msg:lower()
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
                        print("[DEBUG] Pesan diterima:", message.Text, "dari:", sender.Name)
                        handleCommand(message.Text, sender)
                    end
                end
            end
        end

        -- Fallback lama
        for _, player in ipairs(Players:GetPlayers()) do
            player.Chatted:Connect(function(msg)
                print("[DEBUG] Pesan chat lama diterima:", msg, "dari:", player.Name)
                handleCommand(msg, player)
            end)
        end

        Players.PlayerAdded:Connect(function(player)
            player.Chatted:Connect(function(msg)
                print("[DEBUG] Player baru chat diterima:", msg, "dari:", player.Name)
                handleCommand(msg, player)
            end)
        end)
    end
}
