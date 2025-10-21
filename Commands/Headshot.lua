return {
    Execute = function()
        local vars = _G.BotVars
        local Window = vars.MainWindow
        local Camera = workspace.CurrentCamera
        local RunService = game:GetService("RunService")
        local ReplicatedFirst = game:GetService("ReplicatedFirst")

        local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent", true)
        if not BulletEvent then
            warn("[Headshot] BulletEvent tidak ditemukan!")
            return
        end

        local Tabs = {
            Headshot = Window:AddTab("HEADSHOT", "target"),
        }
        local Group = Tabs.Headshot:AddLeftGroupbox("Headshot Control")

        Group:AddToggle("EnableAutoHeadshot", {
            Text = "Aktifkan Auto Headshot",
            Default = false,
            Callback = function(Value)
                vars.ToggleAutoHeadshot = Value
                print(Value and "[Headshot] Auto Headshot Aktif ✅" or "[Headshot] Nonaktif ❌")
            end
        })

        Group:AddSlider("AimSmoothness", {
            Text = "Kelembutan Aim",
            Default = 0.2,
            Min = 0.05,
            Max = 1,
            Rounding = 2,
            Callback = function(Value)
                vars.AimSmoothness = Value
            end
        })

        local function getNearestHead()
            local nearest, dist = nil, math.huge
            for _, model in ipairs(workspace:GetChildren()) do
                if model:IsA("Model") and model.Name == "Male" and model:FindFirstChildOfClass("Humanoid") then
                    for _, c in ipairs(model:GetChildren()) do
                        if string.sub(c.Name,1,3) == "AI_" then
                            local head = model:FindFirstChild("Head") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
                            if head then
                                local magnitude = (head.Position - Camera.CFrame.Position).Magnitude
                                if magnitude < dist then
                                    nearest = head
                                    dist = magnitude
                                end
                            end
                        end
                    end
                end
            end
            return nearest
        end

        -- 🎯 Smooth auto headshot tanpa blink
        task.spawn(function()
            while task.wait(0.05) do
                if not vars.ToggleAutoHeadshot then continue end
                local head = getNearestHead()
                if not head then continue end

                -- Smooth kamera ke kepala
                local currentCF = Camera.CFrame
                local targetCF = CFrame.lookAt(currentCF.Position, head.Position)
                local smoothness = vars.AimSmoothness or 0.2
                Camera.CFrame = currentCF:Lerp(targetCF, smoothness)

                -- Tembak otomatis
                local origin = Camera.CFrame.Position
                local direction = (head.Position - origin).Unit
                local args = {nil, origin, head.Position, nil, direction, nil, nil, true}
                BulletEvent:Fire(unpack(args))
            end
        end)

        print("✅ Headshot.lua aktif — Auto headshot halus, ESP tidak blink 🎯")
    end
}
