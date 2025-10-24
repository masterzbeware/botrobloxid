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

        -- Get services
        local localPlayer = game:GetService("Players").LocalPlayer
        local camera = workspace.CurrentCamera
        local runService = game:GetService("RunService")

        -- Cache untuk NPC yang valid
        local validNPCCache = {}
        local cacheValid = false

        -- Function to check if model has AI_ child (optimized)
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
            return localPlayer.Character and model == localPlayer.Character
        end

        -- Update cache secara realtime
        local function updateNPCCache()
            if cacheValid then return end
            
            validNPCCache = {}
            
            -- Scan hanya models Male yang langsung di workspace
            for _, male in pairs(workspace:GetChildren()) do
                if male:IsA("Model") and male.Name == "Male" and male:FindFirstChild("Head") then
                    if hasAIChild(male) and not isLocalPlayer(male) then
                        table.insert(validNPCCache, male)
                    end
                end
            end
            
            cacheValid = true
        end

        -- Invalidate cache ketika ada perubahan di workspace
        workspace.ChildAdded:Connect(function(child)
            if child:IsA("Model") and child.Name == "Male" then
                cacheValid = false
            end
        end)

        workspace.ChildRemoved:Connect(function(child)
            if child:IsA("Model") and child.Name == "Male" then
                cacheValid = false
            end
        end)
  
        -- Find closest Male NPC secara realtime
        local function getClosestMaleNPC()
            updateNPCCache() -- Update cache jika diperlukan

            local closestNPC = nil
            local closestDistance = vars.FOV
            local mousePos = camera.ViewportSize / 2
            local cameraPos = camera.CFrame.Position
            
            for _, male in pairs(validNPCCache) do
                -- Cek cepat apakah model masih valid
                if male.Parent and male:FindFirstChild("Head") then
                    local head = male.Head
                    local headPos = head.Position
                    
                    -- Cek distance dari player terlebih dahulu (lebih cepat)
                    local distanceFromPlayer = (headPos - cameraPos).Magnitude
                    if distanceFromPlayer > vars.MaxDistance then
                        continue
                    end
                    
                    -- Cek jika di dalam viewport
                    local screenPos, onScreen = camera:WorldToViewportPoint(headPos)
                    if not onScreen then
                        continue
                    end
                    
                    -- Hitung distance dari crosshair
                    local distanceFromCrosshair = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    
                    if distanceFromCrosshair < closestDistance then
                        closestDistance = distanceFromCrosshair
                        closestNPC = male
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
                        local headPos = targetNPC.Head.Position
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

        -- Real-time target tracking info
        local targetInfo = {
            active = false,
            distance = 0,
            aiCount = 0
        }

        -- Real-time update system
        runService.Heartbeat:Connect(function()
            -- Update circle position
            circle.Position = camera.ViewportSize / 2
            
            -- Update target info realtime
            if vars.SilentAim then
                local target = getClosestMaleNPC()
                if target and target:FindFirstChild("Head") then
                    targetInfo.active = true
                    targetInfo.distance = (target.Head.Position - camera.CFrame.Position).Magnitude
                    
                    -- Hitung AI components
                    targetInfo.aiCount = 0
                    for _, child in pairs(target:GetChildren()) do
                        if string.sub(child.Name, 1, 3) == "AI_" then
                            targetInfo.aiCount = targetInfo.aiCount + 1
                        end
                    end
                else
                    targetInfo.active = false
                end
            else
                targetInfo.active = false
            end
        end)

        -- Real-time debug display (opsional)
        local debugText = Drawing.new("Text")
        debugText.Visible = false
        debugText.Color = Color3.fromRGB(255, 255, 255)
        debugText.Size = 18
        debugText.Position = Vector2.new(10, 50)
        debugText.Text = ""

        runService.Heartbeat:Connect(function()
            if vars.SilentAim then
                if targetInfo.active then
                    debugText.Text = string.format("🎯 LOCKED | Distance: %.1f | AI: %d", 
                        targetInfo.distance, targetInfo.aiCount)
                    debugText.Color = Color3.fromRGB(0, 255, 0)
                else
                    debugText.Text = "🔍 SEARCHING..."
                    debugText.Color = Color3.fromRGB(255, 255, 0)
                end
                debugText.Visible = true
            else
                debugText.Visible = false
            end
        end)

        -- Toggle untuk debug display
        Group:AddToggle("ShowDebug", {
            Text = "Show Debug Info",
            Default = false,
            Callback = function(v)
                debugText.Visible = v and vars.SilentAim
            end
        })
  
        print("✅ [Silent Aim NPC Male AI] Sistem REAL-TIME aktif.")
        
        -- Cleanup
        Group:AddButton("Cleanup", {
            Text = "Cleanup Cache",
            Func = function()
                validNPCCache = {}
                cacheValid = false
                print("🧹 Cache dibersihkan")
            end
        })

        -- Auto cleanup ketika window ditutup
        CombatTab:OnDestroy(function()
            if circle then
                circle:Remove()
            end
            if debugText then
                debugText:Remove()
            end
        end)
    end
}