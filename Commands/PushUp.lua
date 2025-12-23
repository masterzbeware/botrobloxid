-- Commands/PushUp.lua
-- Multi-bot executor: otomatis memainkan animasi Push Up ketika admin mengetik !pushup
return {
    Execute = function()
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

        -- Handle chat command dari admin
        local function handleCommand(msg, sender)
            msg = msg:lower()
            if Admin:IsAdmin(sender) and msg == "!pushup" then
                print("[DEBUG] Command !pushup diterima dari admin:", sender.Name)
                playPushUpAnimation()
            end
        end

        -- Listener untuk semua pemain (fallback stabil di executor)
        local function setupPlayerListener(player)
            player.Chatted:Connect(function(msg)
                handleCommand(msg, player)
            end)
        end

        -- Pasang listener ke semua pemain yang sudah ada
        for _, player in ipairs(Players:GetPlayers()) do
            setupPlayerListener(player)
        end

        -- Pasang listener ke pemain baru yang bergabung
        Players.PlayerAdded:Connect(function(player)
            setupPlayerListener(player)
        end)

        print("[DEBUG] PushUp.lua executor siap mendengar !pushup dari admin")
    end
}
