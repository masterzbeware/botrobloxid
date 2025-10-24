return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local CombatTab = tab or Tabs.Combat
  
        if not CombatTab then
            warn("[Silent Aim] Tab Combat tidak ditemukan!")
            return
        end
  
        local Group = CombatTab:AddLeftGroupbox("Silent Aim Prediction")
  
        vars.SilentAim = vars.SilentAim or false
        vars.FOV = vars.FOV or 100
        vars.MaxDistance = vars.MaxDistance or 400
        vars.Prediction = vars.Prediction or 0.1

        local circle = Drawing.new("Circle")
        circle.Visible = false
        circle.Radius = vars.FOV
        circle.Color = Color3.fromRGB(255, 255, 255)
        circle.Thickness = 2
        circle.Position = workspace.CurrentCamera.ViewportSize / 2

        local localPlayer = game:GetService("Players").LocalPlayer
        local camera = workspace.CurrentCamera
  
        local validTargets = {}
        local targetVelocities = {}
        local lastCacheUpdate = 0
        local CACHE_UPDATE_INTERVAL = 0.1
  
        local function updateTargetCache()
            local currentTime = tick()
            if currentTime - lastCacheUpdate < CACHE_UPDATE_INTERVAL then
                return
            end
            
            lastCacheUpdate = currentTime
            table.clear(validTargets)
            
            for _, male in pairs(workspace:GetChildren()) do
                if male:IsA("Model") and male.Name == "Male" then
                    local isLocalPlayerChar = localPlayer.Character and male == localPlayer.Character
                    
                    if not isLocalPlayerChar and male:FindFirstChild("Head") and male:FindFirstChild("HumanoidRootPart") then
                        local rootPart = male.HumanoidRootPart
                        
                        -- Simpan velocity untuk prediction
                        if not targetVelocities[male] then
                            targetVelocities[male] = {
                                position = rootPart.Position,
                                time = currentTime,
                                velocity = Vector3.new(0, 0, 0)
                            }
                        else
                            local oldData = targetVelocities[male]
                            local deltaTime = currentTime - oldData.time
                            
                            if deltaTime > 0 then
                                local displacement = rootPart.Position - oldData.position
                                local velocity = displacement / deltaTime
                                
                                targetVelocities[male] = {
                                    position = rootPart.Position,
                                    time = currentTime,
                                    velocity = velocity
                                }
                            end
                        end
                        
                        table.insert(validTargets, male)
                    end
                end
            end
        end
  
        local function getClosestTarget()
            updateTargetCache()
            
            local closestTarget = nil
            local closestDistance = vars.FOV
            local mousePos = workspace.CurrentCamera.ViewportSize / 2
            
            for _, target in pairs(validTargets) do
                local head = target:FindFirstChild("Head")
                if head then
                    local headPos = head.Position
                    local screenPos, onScreen = camera:WorldToViewportPoint(headPos)
                    
                    local distanceFromPlayer = (headPos - camera.CFrame.Position).Magnitude
                    
                    if onScreen and distanceFromPlayer <= vars.MaxDistance then
                        local distanceFromCrosshair = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        
                        if distanceFromCrosshair < closestDistance then
                            closestDistance = distanceFromCrosshair
                            closestTarget = target
                        end
                    end
                end
            end
            
            return closestTarget
        end

        local function predictTargetPosition(target)
            if not target or not target:FindFirstChild("Head") then
                return nil
            end
            
            local head = target.Head
            local currentPos = head.Position
            
            -- Jika tidak ada data velocity, return posisi saat ini
            if not targetVelocities[target] then
                return currentPos
            end
            
            local velocityData = targetVelocities[target]
            local velocity = velocityData.velocity
            
            -- Prediksi posisi berdasarkan velocity dan waktu
            local predictedPos = currentPos + (velocity * vars.Prediction)
            
            return predictedPos
        end
  
        local originalDischarge
        local BulletService = require(game:GetService("ReplicatedStorage").Shared.Services.BulletService)
        
        if BulletService and not getgenv().SilentAimHooked then
            getgenv().SilentAimHooked = true
            originalDischarge = BulletService.Discharge
            
            BulletService.Discharge = function(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                if vars.SilentAim then
                    local target = getClosestTarget()
                    
                    if target and target:FindFirstChild("Head") then
                        -- Gunakan predicted position bukan current position
                        local predictedHeadPos = predictTargetPosition(target)
                        
                        if predictedHeadPos then
                            local newCFrame = CFrame.lookAt(originCFrame.Position, predictedHeadPos)
                            
                            -- Debug info
                            local currentPos = target.Head.Position
                            local velocityData = targetVelocities[target]
                            if velocityData then
                                local speed = velocityData.velocity.Magnitude
                                print(string.format("Silent Aim Prediction | Speed: %.1f | Prediction: %.2f", speed, vars.Prediction))
                            end
                            
                            return originalDischarge(self, newCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                        end
                    end
                end
                
                return originalDischarge(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
            end
        end
  
        Group:AddToggle("ToggleSilentAim", {
            Text = "Silent Aim Prediction",
            Default = vars.SilentAim,
            Callback = function(v)
                vars.SilentAim = v
                circle.Visible = v
            end
        })
  
        Group:AddSlider("FOVSlider", {
            Text = "FOV Size",
            Default = vars.FOV,
            Min = 5,
            Max = 500,
            Rounding = 0,
            Callback = function(v)
                vars.FOV = v
                circle.Radius = v
            end
        })
  
        Group:AddSlider("MaxDistanceSlider", {
            Text = "Max Distance",
            Default = vars.MaxDistance,
            Min = 50,
            Max = 400,
            Rounding = 0,
            Callback = function(v)
                vars.MaxDistance = v
            end
        })

        Group:AddSlider("PredictionSlider", {
            Text = "Prediction Amount",
            Default = vars.Prediction,
            Min = 0,
            Max = 0.5,
            Rounding = 2,
            Callback = function(v)
                vars.Prediction = v
            end
        })
  
        local lastRenderTime = 0
        game:GetService("RunService").RenderStepped:Connect(function()
            local currentTime = tick()
            if currentTime - lastRenderTime > 0.033 then
                circle.Position = workspace.CurrentCamera.ViewportSize / 2
                lastRenderTime = currentTime
            end
        end)
  
        coroutine.wrap(function()
            while wait(5) do
                if vars.SilentAim then
                    local target = getClosestTarget()
                    if target then
                        local distance = (target.Head.Position - camera.CFrame.Position).Magnitude
                        local velocityData = targetVelocities[target]
                        local speed = velocityData and velocityData.velocity.Magnitude or 0
                        
                        print(string.format("Target | Distance: %.1f | Speed: %.1f | Prediction: %.2f", distance, speed, vars.Prediction))
                    end
                end
            end
        end)()
  
        print("Silent Aim dengan Prediction System aktif!")
    end
}