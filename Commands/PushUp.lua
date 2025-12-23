-- Commands/PushUp.lua
-- Bot otomatis melakukan animasi Push Up ketika admin mengetik !pushup (executor)
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

        -- Handle chat command
        local function handleCommand(msg, sender)
            print("[DEBUG] Pesan chat diterima:", msg, "dari:", sender.Name, "UserId:", sender.UserId)
            if not Admin:IsAdmin(sender) then 
                print("[DEBUG] Player bukan admin, abaikan command:", sender.Name)
                return 
            end
            msg = msg:lower()
            if msg == "!pushup" then
                print("[DEBUG] Command !pushup diterima dari admin:", sender.Name)
                playPushUpAnimation()
            end
        end

        -- Fallback lama pakai Chatted (stabil di executor)
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
