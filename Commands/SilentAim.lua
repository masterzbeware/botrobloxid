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
  
        -- Settings
        vars.SilentAim = vars.SilentAim or false
        vars.FOV = vars.FOV or 100
        vars.MaxDistance = vars.MaxDistance or 400
  
        -- FOV Circle (Visual)
        local circle = Drawing.new("Circle")
        circle.Visible = false
        circle.Radius = vars.FOV
        circle.Color = Color3.fromRGB(255, 255, 255)
        circle.Thickness = 2
        circle.Position = workspace.CurrentCamera.ViewportSize / 2

        -- Get local player
        local localPlayer = game:GetService("Players").LocalPlayer
        local camera = workspace.CurrentCamera
  
        -- Cache untuk Male NPC dengan AI
        local validMaleNPCs = {}
        local lastCacheUpdate = 0
        local CACHE_UPDATE_INTERVAL = 1 -- 1 detik
  
        -- Function untuk update cache Male NPC dengan AI
        local function updateMaleNPCCache()
            local currentTime = tick()
            if currentTime - lastCacheUpdate < CACHE_UPDATE_INTERVAL then
                return
            end
            
            lastCacheUpdate = currentTime
            table.clear(validMaleNPCs)
            
            -- Cari semua model Male yang valid sekali saja
            for _, male in pairs(workspace:GetChildren()) do
                if male:IsA("Model") and male.Name == "Male" then
                    -- Cek apakah memiliki child AI_ dan bukan local player
                    local hasAI = false
                    local isLocalPlayerChar = false
                    
                    -- Cek local player terlebih dahulu (lebih cepat)
                    if localPlayer.Character and male == localPlayer.Character then
                        isLocalPlayerChar = true
                    end
                    
                    if not isLocalPlayerChar and male:FindFirstChild("Head") then
                        -- Cek AI children
                        for _, child in pairs(male:GetChildren()) do
                            if string.sub(child.Name, 1, 3) == "AI_" then
                                hasAI = true
                                break
                            end
                        end
                        
                        if hasAI then
                            table.insert(validMaleNPCs, male)
                        end
                    end
                end
            end
        end
  
        -- Find closest Male NPC dari cache
        local function getClosestMaleNPC()
            updateMaleNPCCache() -- Update cache jika perlu
            
            local closestNPC = nil
            local closestDistance = vars.FOV
            local mousePos = workspace.CurrentCamera.ViewportSize / 2
            
            for _, male in pairs(validMaleNPCs) do
                local head = male:FindFirstChild("Head")
                if head then
                    local headPos = head.Position
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
                    
g                    if targetNPC and targetNPC:FindFirstChild("Head") then
                        -- Calculate direction to head
                        local headPos = targetNPC.Head.Position
                        
                        -- Create new CFrame pointing to head
                        local newCFrame = CFrame.lookAt(originCFrame.Position, headPos)
                        
                        return originalDischarge(self, newCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                    end
                end
                
                return originalDischarge(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
            end
        end
  
        -- UI Elements
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
  
        -- Update FOV circle position (dengan debounce)
        local lastRenderTime = 0
        game:GetService("RunService").RenderStepped:Connect(function()
            local currentTime = tick()
            if currentTime - lastRenderTime > 0.016 then -- ~60 FPS
                circle.Position = workspace.CurrentCamera.ViewportSize / 2
                lastRenderTime = currentTime
            end
        end)
  
        -- Debug info dengan interval lebih lama
        coroutine.wrap(function()
            while wait(5) do -- Diperpanjang dari 3 ke 5 detik
                if vars.SilentAim then
                    local target = getClosestMaleNPC()
                    if target then
                        local distance = (target.Head.Position - camera.CFrame.Position).Magnitude
                        
                        -- Count AI children
                        local aiCount = 0
                        local aiNames = {}
                        for _, child in pairs(target:GetChildren()) do
                            if string.sub(child.Name, 1, 3) == "AI_" then
                                aiCount = aiCount + 1
                                table.insert(aiNames, child.Name)
                                if #aiNames >= 3 then break end -- Batasi output
                            end
                        end
                        
                        print(string.format("🎯 Male NPC AI Target | Distance: %.1f studs | AI Components: %d", 
                            distance, aiCount))
                    else
                        print("🔍 Searching for Male NPC with AI components...")
                        print("   Total cached Male with AI: " .. #validMaleNPCs)
                    end
                end
            end
        end)()
  
        print("✅ [Silent Aim NPC Male AI] Sistem aktif. Target hanya Male dengan komponen AI (optimized).")
    end
}