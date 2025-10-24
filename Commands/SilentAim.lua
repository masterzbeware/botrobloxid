return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local CombatTab = tab or Tabs.Combat
        if not CombatTab then return end

        local Group = CombatTab:AddLeftGroupbox("Silent Aim")
        vars.SilentAim = vars.SilentAim or false
        vars.FOV = vars.FOV or 100
        vars.MaxDistance = vars.MaxDistance or 400

        local camera = workspace.CurrentCamera
        local localPlayer = game:GetService("Players").LocalPlayer
        local runService = game:GetService("RunService")

        local circle = Drawing.new("Circle")
        circle.Visible = false
        circle.Radius = vars.FOV
        circle.Color = Color3.fromRGB(255, 255, 255)
        circle.Thickness = 2
        circle.Position = camera.ViewportSize / 2

        local validMaleNPCs = {}
        local function updateNPC(npc)
            if npc:IsA("Model") and npc.Name == "Male" and npc:FindFirstChild("Head") then
                for _, child in ipairs(npc:GetChildren()) do
                    if string.sub(child.Name, 1, 3) == "AI_" then
                        validMaleNPCs[npc] = true
                        return
                    end
                end
            end
            validMaleNPCs[npc] = nil
        end

        for _, npc in ipairs(workspace:GetChildren()) do
            updateNPC(npc)
        end

        workspace.ChildAdded:Connect(updateNPC)
        workspace.ChildRemoved:Connect(function(npc)
            validMaleNPCs[npc] = nil
        end)

        local function getClosestNPC()
            local closestNPC, closestDist = nil, vars.FOV
            local mousePos = camera.ViewportSize / 2
            for npc in pairs(validMaleNPCs) do
                if npc and npc:FindFirstChild("Head") then
                    local head = npc.Head
                    local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        local distanceFromPlayer = (head.Position - camera.CFrame.Position).Magnitude
                        if dist < closestDist and distanceFromPlayer <= vars.MaxDistance then
                            closestDist = dist
                            closestNPC = npc
                        end
                    end
                end
            end
            return closestNPC
        end

        local BulletService = require(game:GetService("ReplicatedStorage").Shared.Services.BulletService)
        if BulletService and not getgenv().SilentAimHooked then
            getgenv().SilentAimHooked = true
            local originalDischarge = BulletService.Discharge
            BulletService.Discharge = function(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                if vars.SilentAim then
                    local npc = getClosestNPC()
                    if npc and npc:FindFirstChild("Head") then
                        local headPos = npc.Head.Position
                        local newCFrame = CFrame.lookAt(originCFrame.Position, headPos)
                        return originalDischarge(self, newCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                    end
                end
                return originalDischarge(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
            end
        end

        Group:AddToggle("SilentAimToggle", {
            Text = "Silent Aim",
            Default = vars.SilentAim,
            Callback = function(v)
                vars.SilentAim = v
                circle.Visible = v
            end
        })

        Group:AddSlider("FOVSlider", {
            Text = "FOV",
            Default = vars.FOV,
            Min = 5,
            Max = 500,
            Callback = function(v)
                vars.FOV = v
                circle.Radius = v
            end
        })

        Group:AddSlider("MaxDistanceSlider", {
            Text = "Max Distance",
            Default = vars.MaxDistance,
            Min = 50,
            Max = 1000,
            Callback = function(v)
                vars.MaxDistance = v
            end
        })

        runService.RenderStepped:Connect(function()
            circle.Position = camera.ViewportSize / 2
        end)
    end
}
