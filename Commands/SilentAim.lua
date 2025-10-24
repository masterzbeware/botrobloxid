return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local CombatTab = tab or Tabs.Combat

        if not CombatTab then
            warn("[Aimbot System] Tab Combat tidak ditemukan!")
            return
        end

        local Group = CombatTab:AddLeftGroupbox("Aimbot System")

        vars.AimbotEnabled = vars.AimbotEnabled or false

        local localPlayer = game:GetService("Players").LocalPlayer
        local camera = workspace.CurrentCamera
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local UnreliableRemoteEvent = ReplicatedStorage.Events.UnreliableRemoteEvent

        -- DEBUG: Cek apakah BulletService ada
        local BulletService
        local success, err = pcall(function()
            BulletService = require(game:GetService("ReplicatedStorage").Shared.Services.BulletService)
        end)
        
        if not success then
            warn("[DEBUG] BulletService tidak ditemukan: " .. tostring(err))
            return
        else
            print("[DEBUG] BulletService berhasil di-load")
        end

        -- Cache system
        local validTargets = {}
        local lastCacheUpdate = 0
        local CACHE_UPDATE_INTERVAL = 1

        local function updateTargetCache()
            local currentTime = tick()
            if currentTime - lastCacheUpdate < CACHE_UPDATE_INTERVAL then
                return
            end
            
            lastCacheUpdate = currentTime
            table.clear(validTargets)
            
            -- Cari semua Male kecuali diri sendiri
            for _, male in pairs(workspace:GetChildren()) do
                if male:IsA("Model") and male.Name == "Male" then
                    local isLocalPlayerChar = localPlayer.Character and male == localPlayer.Character
                    
                    if not isLocalPlayerChar and male:FindFirstChild("Head") and male:FindFirstChild("HumanoidRootPart") then
                        table.insert(validTargets, male)
                    end
                end
            end
            
            print("[DEBUG] Found " .. #validTargets .. " Male targets")
        end

        local function getClosestTarget()
            updateTargetCache()
            
            local closestTarget = nil
            local closestDistance = 100  -- Fixed FOV
            
            for _, target in pairs(validTargets) do
                local head = target:FindFirstChild("Head")
                if head then
                    local headPos = head.Position
                    local screenPos, onScreen = camera:WorldToViewportPoint(headPos)
                    
                    local distanceFromPlayer = (headPos - camera.CFrame.Position).Magnitude
                    
                    if onScreen and distanceFromPlayer <= 400 then
                        local mousePos = workspace.CurrentCamera.ViewportSize / 2
                        local distanceFromCrosshair = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        
                        if distanceFromCrosshair < closestDistance then
                            closestDistance = distanceFromCrosshair
                            closestTarget = target
                        end
                    end
                end
            end
            
            if closestTarget then
                print("[DEBUG] Closest target: " .. closestTarget.Name .. " | Distance: " .. closestDistance)
            else
                print("[DEBUG] No target found")
            end
            
            return closestTarget
        end

        -- SILENT AIM SYSTEM (BulletService Hook)
        local originalDischarge
        if BulletService and not getgenv().SilentAimHooked then
            getgenv().SilentAimHooked = true
            
            -- Cek apakah fungsi Discharge ada
            if BulletService.Discharge then
                originalDischarge = BulletService.Discharge
                
                BulletService.Discharge = function(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                    if vars.AimbotEnabled then
                        local target = getClosestTarget()
                        
                        if target and target:FindFirstChild("Head") then
                            local headPos = target.Head.Position
                            local newCFrame = CFrame.lookAt(originCFrame.Position, headPos)
                            
                            print("[DEBUG] Silent Aim activated! Targeting: " .. target.Name)
                            return originalDischarge(self, newCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                        else
                            print("[DEBUG] No target for Silent Aim")
                        end
                    end
                    
                    return originalDischarge(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                end
                
                print("[DEBUG] Silent Aim hook berhasil dipasang")
            else
                warn("[DEBUG] Fungsi Discharge tidak ditemukan di BulletService")
            end
        end

        -- MOVEMENT AIMBOT SYSTEM (ReplicateMovement)
        local function applyMovementAimbot()
            if not vars.AimbotEnabled then return end
            
            local target = getClosestTarget()
            if not target or not target:FindFirstChild("Head") then return end
            
            local localChar = localPlayer.Character
            if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return end
            
            local rootPart = localChar.HumanoidRootPart
            local headPos = target.Head.Position
            
            -- Calculate rotation to target
            local targetCF = CFrame.new(rootPart.Position, Vector3.new(headPos.X, rootPart.Position.Y, headPos.Z))
            
            -- Extract position and rotation
            local x, y, z = rootPart.Position.X, rootPart.Position.Y, rootPart.Position.Z
            local rx, ry, rz = targetCF:ToEulerAnglesXYZ()
            
            -- Send modified movement to server
            local movementData = string.format(
                "[\"ReplicateMovement\",\"%s\",%.6f,%.6f,%.6f,%.6f,false,0,%.6f,%.6f,0]",
                tostring(rootPart:GetAttribute("ActorId") or "default"),
                x, y, z,
                rz, ry, rx
            )
            
            UnreliableRemoteEvent:FireServer(movementData)
        end

        -- MOVEMENT AIMBOT LOOP
        local movementAimbotConnection
        local function toggleAimbot(state)
            if movementAimbotConnection then
                movementAimbotConnection:Disconnect()
                movementAimbotConnection = nil
            end
            
            if state then
                movementAimbotConnection = game:GetService("RunService").Heartbeat:Connect(applyMovementAimbot)
                print("[DEBUG] Movement Aimbot diaktifkan")
            else
                print("[DEBUG] Movement Aimbot dimatikan")
            end
        end

        -- UI ELEMENTS
        Group:AddToggle("ToggleAimbot", {
            Text = "Aimbot",
            Default = vars.AimbotEnabled,
            Callback = function(v)
                vars.AimbotEnabled = v
                toggleAimbot(v)
                print("[DEBUG] Aimbot toggle: " .. tostring(v))
            end
        })

        -- Auto-enable jika sudah aktif
        if vars.AimbotEnabled then
            toggleAimbot(true)
        end

        print("Aimbot System loaded dengan debug info!")
    end
}