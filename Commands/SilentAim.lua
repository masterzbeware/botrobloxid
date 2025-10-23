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
        vars.BodyPart = vars.BodyPart or "Head"  -- Default target: Head
        vars.MaxDistance = 300
  
        -- Cek apakah model punya child "AI_"
        local function hasAIChild(model)
            for _, child in pairs(model:GetChildren()) do
                if string.sub(child.Name, 1, 3) == "AI_" then
                    return true
                end
            end
            return false
        end
  
        -- Cek apakah target terlihat (tidak terhalang tembok)
        local function isTargetVisible(targetPart, originPosition)
            if not targetPart or not targetPart:IsA("BasePart") then return false end
            local rayOrigin = originPosition
            local rayDirection = (targetPart.Position - originPosition)
            local rayDistance = rayDirection.Magnitude
            rayDirection = rayDirection.Unit
  
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            raycastParams.FilterDescendantsInstances = {
                workspace.CurrentCamera,
                game.Players.LocalPlayer.Character
            }
            raycastParams.IgnoreWater = true
  
            local rayResult = workspace:Raycast(rayOrigin, rayDirection * rayDistance, raycastParams)
  
            if rayResult then
                local hitInstance = rayResult.Instance
                if hitInstance and hitInstance:IsDescendantOf(targetPart.Parent) then
                    return true
                else
                    return false
                end
            end
  
            return true
        end
  
        -- Cari NPC Male terdekat dengan AI_
        local function getClosestMaleNPC()
            local closestNPC = nil
            local closestDistance = vars.MaxDistance
            local camera = workspace.CurrentCamera
            local playerPos = camera.CFrame.Position
  
            for _, male in pairs(workspace:GetDescendants()) do
                if male:IsA("Model") and male.Name == "Male" and male:FindFirstChild("Head") then
                    if hasAIChild(male) then
                        local head = male.Head
                        local distance = (head.Position - playerPos).Magnitude
                        if distance <= vars.MaxDistance then
                            if isTargetVisible(head, playerPos) then
                                if distance < closestDistance then
                                    closestDistance = distance
                                    closestNPC = male
                                end
                            end
                        end
                    end
                end
            end
  
            return closestNPC
        end
  
        -- Ambil part target
        local function getTargetBodyPart(targetNPC)
            local bodyPart = vars.BodyPart
            if bodyPart == "Head" and targetNPC:FindFirstChild("Head") then
                return targetNPC.Head
            elseif bodyPart == "UpperTorso" and targetNPC:FindFirstChild("UpperTorso") then
                return targetNPC.UpperTorso
            elseif bodyPart == "HumanoidRootPart" and targetNPC:FindFirstChild("HumanoidRootPart") then
                return targetNPC.HumanoidRootPart
            elseif bodyPart == "Torso" and targetNPC:FindFirstChild("Torso") then
                return targetNPC.Torso
            else
                return targetNPC:FindFirstChild("Head") or targetNPC:FindFirstChild("HumanoidRootPart")
            end
        end
  
        -- Hook BulletService
        local BulletService = require(game:GetService("ReplicatedStorage").Shared.Services.BulletService)
        if BulletService and not getgenv().SilentAimHooked then
            getgenv().SilentAimHooked = true
            local originalDischarge = BulletService.Discharge
  
            BulletService.Discharge = function(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                if vars.SilentAim then
                    local targetNPC = getClosestMaleNPC()
                    if targetNPC then
                        local targetPart = getTargetBodyPart(targetNPC)
                        if targetPart and targetPart:IsA("BasePart") then
                            local partPos = targetPart.Position
                            local direction = (partPos - originCFrame.Position).Unit
  
                            -- Pastikan arah peluru dan velocity sinkron
                            local newCFrame = CFrame.lookAt(originCFrame.Position, partPos)
                            local newVelocity = direction * velocity.Magnitude
  
                            -- Hindari kena karakter sendiri
                            local newIgnore = table.clone(ignore or {})
                            table.insert(newIgnore, game.Players.LocalPlayer.Character)
  
                            local distance = (partPos - originCFrame.Position).Magnitude
                            print(string.format("🎯 Silent Aim: %s (%s) | Dist: %.1f", 
                                targetNPC.Name, targetPart.Name, distance))
  
                            return originalDischarge(self, newCFrame, caliber, newVelocity, replicate, localShooter, newIgnore, tracer, ...)
                        end
                    else
                        print("❌ Tidak ada target valid dalam jangkauan atau terhalang.")
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
                if v then
                    print("✅ Silent Aim: ON | Body Part: " .. vars.BodyPart)
                else
                    print("❌ Silent Aim: OFF")
                end
            end
        })
  
        Group:AddDropdown("BodyPartDropdown", {
            Text = "Target Body",
            Default = vars.BodyPart,
            Values = {"Head", "UpperTorso", "HumanoidRootPart", "Torso"},
            Callback = function(v)
                vars.BodyPart = v
                print("🎯 Body Part changed to: " .. v)
            end
        })
  
        -- Debug info loop
        coroutine.wrap(function()
            while task.wait(3) do
                if vars.SilentAim then
                    local target = getClosestMaleNPC()
                    if target then
                        local targetPart = getTargetBodyPart(target)
                        if targetPart then
                            local distance = (targetPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                            local aiCount = 0
                            for _, c in pairs(target:GetChildren()) do
                                if string.sub(c.Name, 1, 3) == "AI_" then
                                    aiCount += 1
                                end
                            end
                            print(string.format("🎯 Locked: %s | Part: %s | Dist: %.1f | AI: %d",
                                target.Name, targetPart.Name, distance, aiCount))
                        end
                    else
                        print("🔍 Searching for Male NPC with AI...")
                    end
                end
            end
        end)()
  
        print("✅ [Silent Aim NPC Male AI] Sistem aktif.")
        print("   Target: Male dengan komponen AI")
        print("   Max Distance: " .. vars.MaxDistance .. " studs")
        print("   Default Body Part: " .. vars.BodyPart)
    end
  }
  