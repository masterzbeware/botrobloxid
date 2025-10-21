-- Bullet.lua
-- 💥 Headshot Auto: Tembak semua NPC Male AI_ langsung ke kepala, tanpa log

return {
    Execute = function()
        local vars = _G.BotVars
        local Window = vars.MainWindow
        local ReplicatedFirst = game:GetService("ReplicatedFirst")
        local Camera = workspace.CurrentCamera
        local UserInputService = game:GetService("UserInputService")

        -- Cari Remote Bullet
        local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent", true)
        if not BulletEvent then
            warn("[Bullet] BulletEvent tidak ditemukan!")
            return
        end

        -- UI
        local Tabs = { Bullet = Window:AddTab("BULLET", "zap") }
        local Group = Tabs.Bullet:AddLeftGroupbox("Burst Control")

        Group:AddToggle("EnableBurst", {
            Text = "Aktifkan Burst Headshot (Semua NPC)",
            Default = false,
            Callback = function(Value)
                vars.ToggleBurst = Value
            end
        })

        -- Ambil semua kepala NPC Male AI_
        local function getAllNPCHeads()
            local result = {}
            for _, model in ipairs(workspace:GetDescendants()) do
                if model:IsA("Model") and model.Name == "Male" then
                    for _, c in ipairs(model:GetChildren()) do
                        if string.sub(c.Name,1,3) == "AI_" then
                            local head = model:FindFirstChild("Head")
                            if head then table.insert(result, head) end
                            break
                        end
                    end
                end
            end
            return result
        end

        -- Fungsi menembak semua kepala NPC
        local function shootAllNPCHeads()
            if not vars.ToggleBurst then return end
            local heads = getAllNPCHeads()
            if #heads == 0 then return end

            local origin = Camera.CFrame.Position

            for _, head in ipairs(heads) do
                local targetPos = head.Position
                local direction = (targetPos - origin).Unit
                local args = {nil, origin, targetPos, nil, direction, nil, nil, true}
                BulletEvent:Fire(unpack(args))
            end
        end

        -- Klik kiri untuk tembak semua kepala NPC
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                shootAllNPCHeads()
            end
        end)
    end
}
