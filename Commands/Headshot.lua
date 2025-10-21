return {
    Execute = function()
        local vars = _G.BotVars
        local Window = vars.MainWindow
        local Camera = workspace.CurrentCamera
        local ReplicatedFirst = game:GetService("ReplicatedFirst")

        local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent", true)
        if not BulletEvent then
            warn("[Headshot] Tidak menemukan BulletEvent!")
            return
        end

        local Tabs = { Headshot = Window:AddTab("HEADSHOT", "target") }
        local Group = Tabs.Headshot:AddLeftGroupbox("Headshot Control")

        Group:AddToggle("EnableAutoHeadshot", {
            Text = "Aktifkan Auto Headshot",
            Default = false,
            Callback = function(Value)
                vars.ToggleAutoHeadshot = Value
            end
        })

        -- Cari kepala NPC terdekat
        local function getNearestHead()
            local nearest, dist = nil, math.huge
            for _, model in ipairs(workspace:GetChildren()) do
                if model:IsA("Model") and model.Name=="Male" and model:FindFirstChildOfClass("Humanoid") then
                    for _, c in ipairs(model:GetChildren()) do
                        if string.sub(c.Name,1,3)=="AI_" then
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

        -- Smooth headshot loop
        task.spawn(function()
            while true do
                task.wait(0.05)
                if not vars.ToggleAutoHeadshot then continue end
                local head = getNearestHead()
                if not head then continue end

                -- Smooth camera aim agar ESP tidak blink
                local targetCF = CFrame.lookAt(Camera.CFrame.Position, head.Position)
                Camera.CFrame = Camera.CFrame:Lerp(targetCF, 0.3)

                -- Tembak otomatis
                local origin = Camera.CFrame.Position
                local direction = (head.Position - origin).Unit
                local args = {nil, origin, head.Position, nil, direction, nil, nil, true}
                BulletEvent:Fire(unpack(args))
            end
        end)
    end
}
