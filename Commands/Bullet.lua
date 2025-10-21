-- Bullet.lua
-- 💥 Burst Bullet System (tembakan otomatis ke kepala NPC Male)

return {
    Execute = function()
        local vars = _G.BotVars
        local Window = vars.MainWindow
        local ReplicatedFirst = game:GetService("ReplicatedFirst")
        local Camera = workspace.CurrentCamera

        -- Cari event tembakan
        local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent", true)
        if not BulletEvent then
            warn("[Bullet] Tidak menemukan BulletEvent di ReplicatedFirst!")
            return
        end

        -- 🔘 UI Control
        local Tabs = { Bullet = Window:AddTab("BULLET", "zap") }
        local Group = Tabs.Bullet:AddLeftGroupbox("Burst Control")

        Group:AddToggle("EnableBurst", {
            Text = "Aktifkan Burst Bullet (Headshot semua NPC)",
            Default = false,
            Callback = function(Value)
                vars.ToggleBurst = Value
                print(Value and "[Bullet] Burst Headshot aktif ✅" or "[Bullet] Burst nonaktif ❌")
            end
        })

        -- 🔍 Cari semua NPC yang valid (harus punya Head)
        local function getAllNPCHeads()
            local result = {}
            for _, model in ipairs(workspace:GetDescendants()) do
                if model:IsA("Model") and model.Name == "Male" then
                    for _, child in ipairs(model:GetChildren()) do
                        if string.sub(child.Name,1,3) == "AI_" then
                            local head = model:FindFirstChild("Head")
                            if head then
                                table.insert(result, head)
                            end
                            break
                        end
                    end
                end
            end
            return result
        end

        -- 🎯 Fungsi menembak ke semua kepala NPC
        local function shootAllNPCHeads()
            if not vars.ToggleBurst then return end
            if not BulletEvent then return end

            local heads = getAllNPCHeads()
            if #heads == 0 then
                warn("[Bullet] Tidak ada kepala NPC ditemukan.")
                return
            end

            print("[Bullet] Menembak semua kepala NPC (jumlah:", #heads, ")")

            for _, head in ipairs(heads) do
                local origin = Camera.CFrame.Position
                local targetPos = head.Position
                local direction = (targetPos - origin).Unit

                local args = {nil, origin, targetPos, nil, direction, nil, nil, true}
                BulletEvent:Fire(unpack(args))
            end
        end

        -- 🔫 Klik kiri untuk menembak semua kepala NPC
        game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                shootAllNPCHeads()
            end
        end)

        print("✅ Bullet.lua aktif — klik kiri = semua NPC pasti kena kepala")
    end
}
