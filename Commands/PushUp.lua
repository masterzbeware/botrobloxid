-- Commands/PushUp.lua
-- Admin-only push up system, bot otomatis memainkan animasi ketika admin mengetik !pushup
return {
    Execute = function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end

        -- 🔗 Load Admin module
        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        local humanoid
        local myHRP

        -- Update references karakter
        local function updateCharacter()
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            humanoid = char:WaitForChild("Humanoid")
            myHRP = char:WaitForChild("HumanoidRootPart")
        end

        updateCharacter()
        LocalPlayer.CharacterAdded:Connect(updateCharacter)

        -- Fungsi kirim chat satu kali
        local function sendChat(msg)
            local sent = false
            if TextChatService and TextChatService.TextChannels then
                local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if channel then
                    pcall(function()
                        channel:SendAsync(msg)
                    end)
                    sent = true
                end
            end
            if not sent then
                pcall(function()
                    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
                end)
            end
        end

        -- Fungsi mainkan animasi Push Up
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
            msg = msg:lower()
            if Admin:IsAdmin(sender) then
                if msg == "!pushup" then
                    -- Chat satu kali
                    sendChat("Siap, Laksanakan!")
                    playPushUpAnimation()
                end
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

        -- Fallback lama pakai Chatted
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

        print("[DEBUG] PushUp.lua siap mendengar !pushup dari admin")
    end
}
