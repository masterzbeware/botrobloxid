return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local CombatTab = tab or Tabs.Combat
  
        if not CombatTab then
            warn("[Silent Aim] Tab Combat tidak ditemukan!")
            return
        end
  
        local Group = CombatTab:AddLeftGroupbox("Silent Aim")
  
        vars.SilentAim = vars.SilentAim or false
        vars.FOV = vars.FOV or 100
        vars.MaxDistance = vars.MaxDistance or 400
  
        local circle = Drawing.new("Circle")
        circle.Visible = false
        circle.Radius = vars.FOV
        circle.Color = Color3.fromRGB(255, 255, 255)
        circle.Thickness = 2
        circle.Position = workspace.CurrentCamera.ViewportSize / 2

        local localPlayer = game:GetService("Players").LocalPlayer
        local camera = workspace.CurrentCamera
  
        local validMaleNPCs = {}
        local lastCacheUpdate = 0
        local CACHE_UPDATE_INTERVAL = 2
  
        local function updateMaleNPCCache()
            local currentTime = tick()
            if currentTime - lastCacheUpdate < CACHE_UPDATE_INTERVAL then
                return
            end
            
            lastCacheUpdate = currentTime
            table.clear(validMaleNPCs)
            
            for _, male in pairs(workspace:GetChildren()) do
                if male:IsA("Model") and male.Name == "Male" then
                    local isLocalPlayerChar = localPlayer.Character and male == localPlayer.Character
                    
                    if not isLocalPlayerChar and male:FindFirstChild("Head") then
                        for _, child in pairs(male:GetChildren()) do
                            if string.sub(child.Name, 1, 3) == "AI_" then
                                table.insert(validMaleNPCs, male)
                                break
                            end
                        end
                    end
                end
            end
        end
  
        local function getClosestMaleNPC()
            updateMaleNPCCache()
            
            local closestNPC = nil
            local closestDistance = vars.FOV
            local mousePos = workspace.CurrentCamera.ViewportSize / 2
            
            for _, male in pairs(validMaleNPCs) do
                local head = male:FindFirstChild("Head")
                if head then
                    local headPos = head.Position
                    local screenPos, onScreen = camera:WorldToViewportPoint(headPos)
                    
                    local distanceFromPlayer = (headPos - camera.CFrame.Position).Magnitude
                    
                    if onScreen and distanceFromPlayer <= vars.MaxDistance then
                        local distanceFromCrosshair = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        
                        if distanceFromCrosshair < closestDistance then
                            closestDistance = distanceFromCrosshair
                            closestNPC = male
                        end
                    end
                end
            end
            
            return closestNPC
        end
  
        local originalDischarge
        local BulletService = require(game:GetService("ReplicatedStorage").Shared.Services.BulletService)
        
        if BulletService and not getgenv().SilentAimHooked then
            getgenv().SilentAimHooked = true
            originalDischarge = BulletService.Discharge
            
            BulletService.Discharge = function(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                if vars.SilentAim then
                    local targetNPC = getClosestMaleNPC()
                    
                    if targetNPC and targetNPC:FindFirstChild("Head") then
                        local headPos = targetNPC.Head.Position
                        local newCFrame = CFrame.lookAt(originCFrame.Position, headPos)
                        
                        return originalDischarge(self, newCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                    end
                end
                
                return originalDischarge(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
            end
        end
  
        Group:AddToggle("ToggleSilentAim", {
            Text = "Silent Aim",
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
  
        local lastRenderTime = 0
        game:GetService("RunService").RenderStepped:Connect(function()
            local currentTime = tick()
            if currentTime - lastRenderTime > 0.033 then
                circle.Position = workspace.CurrentCamera.ViewportSize / 2
                lastRenderTime = currentTime
            end
        end)
  
        coroutine.wrap(function()
            while wait(10) do
                if vars.SilentAim then
                    local target = getClosestMaleNPC()
                    if target then
                        local distance = (target.Head.Position - camera.CFrame.Position).Magnitude
                        
                        local aiCount = 0
                        for _, child in pairs(target:GetChildren()) do
                            if string.sub(child.Name, 1, 3) == "AI_" then
                                aiCount = aiCount + 1
                            end
                        end
                        
                        print(string.format("Silent Aim Target | Distance: %.1f studs | AI Components: %d", distance, aiCount))
                    else
                        print("Searching for Male NPC with AI components...")
                        print("Total cached Male with AI: " .. #validMaleNPCs)
                    end
                end
            end
        end)()
  
        print("Silent Aim NPC Male AI sistem aktif.")
    end
}