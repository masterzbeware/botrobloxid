-- BulletHeadshot.lua
-- 💥 Auto Headshot: Semua NPC Male (Head) langsung kena tanpa peduli tembok

return {
    Execute = function()
        local vars = _G.BotVars
        local Window = vars.MainWindow
        local ReplicatedFirst = game:GetService("ReplicatedFirst")
        local Camera = workspace.CurrentCamera
        local UserInputService = game:GetService("UserInputService")

        -- Cari event tembakan
        local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent", true)
        if not BulletEvent then
            warn("[Bullet] Tidak menemukan BulletEvent di ReplicatedFirst!")
            return
        end

        -- 🔘 UI Control
        local Tabs = { Bullet = Window:AddTab("BULLET", "zap") }
        local Group = Tabs.Bullet:AddLeftGroupbox("Headshot Control")

        Group:AddToggle("EnableAutoHeadshot", {
            Text = "Aktifkan Auto Headshot Semua NPC",
            Default = false,
            Callback = function(Value)
                vars.ToggleBulletHeadshot = Value
                print(Value and "[Bullet] Auto Headshot aktif ✅" or "[Bullet] Auto Headshot nonaktif ❌")
            end
        })

        -- 🔍 Ambil semua kepala NPC valid
        local function getAllHeads()
            local heads = {}
            for _, model in ipairs(workspace:GetDescendants()) do
                if model:IsA("Model") and model.Name == "Male" then
                    for _, child in ipairs(model:GetChildren()) do
                        if string.sub(child.Name, 1, 3) == "AI_" then
                            local head = model:FindFirstChild("Head")
                            if head then
                                table.insert(heads, head)
                            end
                            break
                        end
                    end
                end
            end
            return heads
        end

        -- 🎯 Fungsi tembak ke semua kepala
        local function shootHeads()
            if not vars.ToggleBulletHeadshot then return end
            if not BulletEvent then return end

            local heads = getAllHeads()
            if #heads == 0 then return end

            for _, head in ipairs(heads) do
                local origin = Camera.CFrame.Position
                local direction = (head.Position - origin).Unit
                local args = {nil, origin, head.Position, nil, direction, nil, nil, true}
                BulletEvent:Fire(unpack(args))
            end
        end

        -- 🔫 Klik kiri untuk menembak semua kepala
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                shootHeads()
            end
        end)

        -- 🔁 Auto fire loop (opsional)
        task.spawn(function()
            while task.wait(0.05) do
                if vars.ToggleBulletHeadshot then
                    shootHeads()
                end
            end
        end)

        print("✅ BulletHeadshot.lua aktif — semua NPC pasti kena kepala, menembus tembok")
    end
}
