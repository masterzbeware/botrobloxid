-- Bullet.lua
-- 💥 Burst Bullet System (tembakan otomatis ke semua NPC AI_)

return {
    Execute = function()
        local vars = _G.BotVars
        local Window = vars.MainWindow
        local ReplicatedFirst = game:GetService("ReplicatedFirst")
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera

        -- Cari event tembakan
        local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent", true)
        if not BulletEvent then
            warn("[Bullet] Tidak menemukan BulletEvent di ReplicatedFirst!")
            return
        end

        -- 🔘 UI Control
        local Tabs = {
            Bullet = Window:AddTab("BULLET", "zap"),
        }
        local Group = Tabs.Bullet:AddLeftGroupbox("Burst Control")

        Group:AddToggle("EnableBurst", {
            Text = "Aktifkan Burst Bullet (Semua NPC Mati)",
            Default = false,
            Callback = function(Value)
                vars.ToggleBurst = Value
                print(Value and "[Bullet] Burst aktif ✅" or "[Bullet] Burst nonaktif ❌")
            end
        })

        Group:AddSlider("BurstCount", {
            Text = "Jumlah Peluru per NPC",
            Default = 3,
            Min = 1,
            Max = 10,
            Rounding = 0,
            Callback = function(Value)
                vars.BurstCount = Value
            end
        })

        Group:AddSlider("BurstDelay", {
            Text = "Delay antar peluru (detik)",
            Default = 0.05,
            Min = 0.01,
            Max = 0.3,
            Rounding = 3,
            Callback = function(Value)
                vars.BurstDelay = Value
            end
        })

        -- 🔍 Cari semua NPC yang valid
        local function getAllNPCs()
            local result = {}
            for _, model in ipairs(workspace:GetDescendants()) do
                if model:IsA("Model") and model.Name == "Male" then
                    for _, child in ipairs(model:GetChildren()) do
                        if string.sub(child.Name, 1, 3) == "AI_" then
                            table.insert(result, model)
                            break
                        end
                    end
                end
            end
            return result
        end

        -- 🎯 Fungsi menembak ke semua NPC
        local function shootAllNPCs()
            if not vars.ToggleBurst then return end
            if not BulletEvent then return end

            local npcs = getAllNPCs()
            if #npcs == 0 then
                warn("[Bullet] Tidak ada NPC ditemukan.")
                return
            end

            print("[Bullet] Menembak ke semua NPC (jumlah:", #npcs, ")")

            for _, npc in ipairs(npcs) do
                local humanoidRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("UpperTorso")
                if humanoidRoot then
                    local targetPos = humanoidRoot.Position + Vector3.new(0, 0.05, 0)
                    local origin = Camera.CFrame.Position
                    local direction = (targetPos - origin).Unit

                    -- Burst fire
                    for i = 1, (vars.BurstCount or 3) do
                        local args = {nil, origin, targetPos, nil, direction, nil, nil, true}
                        BulletEvent:Fire(unpack(args))
                        task.wait(vars.BurstDelay or 0.05)
                    end
                end
            end
        end

        -- 🔫 Tekan klik kiri untuk menembak semua NPC
        game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                shootAllNPCs()
            end
        end)

        print("✅ Bullet.lua aktif — klik kiri = semua NPC langsung kena burst")
    end
}
