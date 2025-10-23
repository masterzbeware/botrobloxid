return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local CombatTab = tab or Tabs.Combat
  
        if not CombatTab then
            warn("[Silent Aim] Tab Combat tidak ditemukan!")
            return
        end
  
        local Group = CombatTab:AddLeftGroupbox("Silent Aim NPC Male AI")
  
        -- Settings
        vars.SilentAim = vars.SilentAim or false
        vars.FOV = vars.FOV or 100
        vars.MaxDistance = vars.MaxDistance or 500
  
        -- FOV Circle (Visual)
        local circle = Drawing.new("Circle")
        circle.Visible = false
        circle.Radius = vars.FOV
        circle.Color = Color3.fromRGB(255, 255, 255)
        circle.Thickness = 2
        circle.Position = workspace.CurrentCamera.ViewportSize / 2

        -- Get local player
        local localPlayer = game:GetService("Players").LocalPlayer
  
        -- Function to check if model has AI_ child
        local function hasAIChild(model)
            for _, child in pairs(model:GetChildren()) do
                if string.sub(child.Name, 1, 3) == "AI_" then
                    return true
                end
            end
            return false
        end

        -- Function to check if model is local player
        local function isLocalPlayer(model)
            if model:FindFirstChild("Head") and localPlayer.Character then
                return model == localPlayer.Character
            end
            return false
        end
  
        -- Find closest Male NPC dengan filter AI_ dan exclude local player
        local function getClosestMaleNPC()
            local closestNPC = nil
            local closestDistance = vars.FOV
            local mousePos = workspace.CurrentCamera.ViewportSize / 2
            local camera = workspace.CurrentCamera
            
            -- Cari semua model Male di workspace yang memiliki child AI_ dan bukan local player
            for _, male in pairs(workspace:GetDescendants()) do
                if male:IsA("Model") and male.Name == "Male" and male:FindFirstChild("Head") then
                    
                    -- Filter: hanya yang memiliki child dengan nama diawali "AI_" dan bukan local player
                    if hasAIChild(male) and not isLocalPlayer(male) then
                        local headPos = male.Head.Position
                        local screenPos, onScreen = camera:WorldToViewportPoint(headPos)
                        
                        -- Check distance from player
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
            end
            
            return closestNPC
        end
  
        -- Hook BulletService untuk silent aim
        local originalDischarge
        local BulletService = require(game:GetService("ReplicatedStorage").Shared.Services.BulletService)
        
        if BulletService and not getgenv().SilentAimHooked then
            getgenv().SilentAimHooked = true
            originalDischarge = BulletService.Discharge
            
            BulletService.Discharge = function(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                if vars.SilentAim then
                    local targetNPC = getClosestMaleNPC()
                    
                    if targetNPC and targetNPC:FindFirstChild("Head") then
                        -- Calculate direction to head
                        local headPos = targetNPC.Head.Position
                        
                        -- Create new CFrame pointing to head
                        local newCFrame = CFrame.lookAt(originCFrame.Position, headPos)
                        
                        -- Get AI child names for debug
                        local aiChildren = {}
                        for _, child in pairs(targetNPC:GetChildren()) do
                            if string.sub(child.Name, 1, 3) == "AI_" then
                                table.insert(aiChildren, child.Name)
                            end
                        end
                        
                        print("🎯 Silent Aim: Targeting Male NPC with AI")
                        print("   Head Position: " .. tostring(headPos))
                        print("   Distance: " .. math.floor((headPos - originCFrame.Position).Magnitude))
                        print("   AI Children: " .. table.concat(aiChildren, ", "))
                        
                        return originalDischarge(self, newCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                    else
                        if vars.SilentAim then
                            print("❌ No valid Male NPC with AI found in FOV (excluding self)")
                        end
                    end
                end
                
                return originalDischarge(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
            end
        end
  
        -- UI Elements
        Group:AddToggle("ToggleSilentAim", {
            Text = "Silent Aim NPC Male AI",
            Default = vars.SilentAim,
            Callback = function(v)
                vars.SilentAim = v
                circle.Visible = v
            end
        })
  
        Group:AddSlider("FOVSlider", {
            Text = "FOV Size",
            Default = vars.FOV,
            Min = 10,
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
  
        -- Update FOV circle position
        game:GetService("RunService").RenderStepped:Connect(function()
            circle.Position = workspace.CurrentCamera.ViewportSize / 2
        end)
  
        -- Debug info dengan detil AI
        coroutine.wrap(function()
            while wait(3) do
                if vars.SilentAim then
                    local target = getClosestMaleNPC()
                    if target then
                        local distance = (target.Head.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                        
                        -- Count AI children
                        local aiCount = 0
                        local aiNames = {}
                        for _, child in pairs(target:GetChildren()) do
                            if string.sub(child.Name, 1, 3) == "AI_" then
                                aiCount = aiCount + 1
                                table.insert(aiNames, child.Name)
                            end
                        end
                        
                        print(string.format("🎯 Male NPC AI Target | Distance: %.1f studs | AI Components: %d (%s)", 
                            distance, aiCount, table.concat(aiNames, ", ")))
                    else
                        print("🔍 Searching for Male NPC with AI components (excluding self)...")
                        
                        -- Debug: list semua Male dengan AI di workspace (exclude self)
                        local maleWithAI = 0
                        for _, male in pairs(workspace:GetDescendants()) do
                            if male:IsA("Model") and male.Name == "Male" and hasAIChild(male) and not isLocalPlayer(male) then
                                maleWithAI = maleWithAI + 1
                            end
                        end
                        print("   Total valid Male with AI in workspace: " .. maleWithAI)
                    end
                end
            end
        end)()
  
        print("✅ [Silent Aim NPC Male AI] Sistem aktif. Target hanya Male dengan komponen AI (tidak termasuk diri sendiri).")
    end
}