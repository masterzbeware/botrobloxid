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
      vars.BodyPart = vars.BodyPart or "Head"
      vars.DamageBoost = vars.DamageBoost or false  -- New: Damage boost
      vars.RapidFire = vars.RapidFire or false      -- New: Rapid fire
      vars.MaxDistance = 400

      -- Function to check if model has AI_ child
      local function hasAIChild(model)
          for _, child in pairs(model:GetChildren()) do
              if string.sub(child.Name, 1, 3) == "AI_" then
                  return true
              end
          end
          return false
      end

      -- Function to check if target visible
      local function isTargetVisible(targetPart, originPosition)
          local rayOrigin = originPosition
          local rayDirection = (targetPart.Position - originPosition).Unit
          local rayDistance = (targetPart.Position - originPosition).Magnitude
          
          local raycastParams = RaycastParams.new()
          raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
          raycastParams.FilterDescendantsInstances = {workspace.CurrentCamera}
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

      -- Find closest Male NPC
      local function getClosestMaleNPC()
          local closestNPC = nil
          local closestDistance = vars.MaxDistance
          local camera = workspace.CurrentCamera
          local playerPosition = camera.CFrame.Position
          
          for _, male in pairs(workspace:GetDescendants()) do
              if male:IsA("Model") and male.Name == "Male" and male:FindFirstChild("Head") then
                  if hasAIChild(male) then
                      local head = male.Head
                      local headPos = head.Position
                      local distanceFromPlayer = (headPos - playerPosition).Magnitude
                      
                      if distanceFromPlayer <= vars.MaxDistance then
                          if isTargetVisible(head, playerPosition) then
                              if distanceFromPlayer < closestDistance then
                                  closestDistance = distanceFromPlayer
                                  closestNPC = male
                              end
                          end
                      end
                  end
              end
          end
          return closestNPC
      end

      -- Get target body part
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

      -- Hook BulletService untuk silent aim dengan damage boost
      local originalDischarge
      local BulletService = require(game:GetService("ReplicatedStorage").Shared.Services.BulletService)
      
      if BulletService and not getgenv().SilentAimHooked then
          getgenv().SilentAimHooked = true
          originalDischarge = BulletService.Discharge
          
          BulletService.Discharge = function(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
              if vars.SilentAim then
                  local targetNPC = getClosestMaleNPC()
                  
                  if targetNPC then
                      local targetPart = getTargetBodyPart(targetNPC)
                      
                      if targetPart then
                          local partPos = targetPart.Position
                          local newCFrame = CFrame.lookAt(originCFrame.Position, partPos)
                          
                          -- DAMAGE BOOST: Ubah ke caliber yang lebih powerful
                          local boostedCaliber = caliber
                          if vars.DamageBoost then
                              boostedCaliber = "intermediaterifle_556x45mmNATO_M855"  -- Ganti dengan caliber terkuat
                              print("💥 DAMAGE BOOST: Using high-power caliber")
                          end
                          
                          -- RAPID FIRE: Multiple shots
                          if vars.RapidFire then
                              coroutine.wrap(function()
                                  for i = 1, 3 do  -- 3 shot rapid
                                      wait(0.05)   -- 50ms delay
                                      originalDischarge(self, newCFrame, boostedCaliber, velocity, replicate, localShooter, ignore, tracer, ...)
                                  end
                              end)()
                              print("🔫 RAPID FIRE: 3-shot burst")
                          end
                          
                          local distance = math.floor((partPos - originCFrame.Position).Magnitude)
                          print("🎯 Targeting " .. vars.BodyPart .. " | Distance: " .. distance .. " studs")
                          
                          return originalDischarge(self, newCFrame, boostedCaliber, velocity, replicate, localShooter, ignore, tracer, ...)
                      end
                  else
                      print("❌ No target found")
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
              print(v and "✅ Silent Aim: ON" or "❌ Silent Aim: OFF")
          end
      })

      Group:AddDropdown("BodyPartDropdown", {
          Text = "Target Body Part", 
          Default = vars.BodyPart,
          Values = {"Head", "UpperTorso", "HumanoidRootPart", "Torso"},
          Callback = function(v)
              vars.BodyPart = v
              print("🎯 Body Part: " .. v)
          end
      })

      Group:AddToggle("ToggleDamageBoost", {
          Text = "Damage Boost",
          Default = vars.DamageBoost,
          Callback = function(v)
              vars.DamageBoost = v
              print(v and "💥 Damage Boost: ON" or "💥 Damage Boost: OFF")
          end
      })

      Group:AddToggle("ToggleRapidFire", {
          Text = "Rapid Fire (3-shot)",
          Default = vars.RapidFire,
          Callback = function(v)
              vars.RapidFire = v
              print(v and "🔫 Rapid Fire: ON" or "🔫 Rapid Fire: OFF")
          end
      })

      -- Auto-kill system untuk NPC yang bandel
      local function forceKillNPC(targetNPC)
          local humanoid = targetNPC:FindFirstChildOfClass("Humanoid")
          if humanoid then
              -- Method 1: Direct health set
              humanoid.Health = 0
              
              -- Method 2: Breakparts (fallback)
              for _, part in pairs(targetNPC:GetChildren()) do
                  if part:IsA("BasePart") then
                      part:BreakJoints()
                  end
              end
              
              print("☠️ FORCE KILL: " .. targetNPC.Name)
              return true
          end
          return false
      end

      -- Emergency kill button
      Group:AddButton("Force Kill Nearest NPC", function()
          local target = getClosestMaleNPC()
          if target then
              if forceKillNPC(target) then
                  print("✅ Force kill successful")
              else
                  print("❌ Force kill failed")
              end
          else
              print("❌ No target for force kill")
          end
      end)

      -- Debug info dengan health monitoring
      coroutine.wrap(function()
          while wait(2) do
              if vars.SilentAim then
                  local target = getClosestMaleNPC()
                  if target then
                      local targetPart = getTargetBodyPart(target)
                      local distance = (targetPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                      
                      local humanoid = target:FindFirstChildOfClass("Humanoid")
                      local healthInfo = ""
                      if humanoid then
                          healthInfo = string.format(" | Health: %d/%d", humanoid.Health, humanoid.MaxHealth)
                      end
                      
                      print(string.format("🎯 Locked: %s | Part: %s | Distance: %.1f studs%s", 
                          target.Name, targetPart.Name, distance, healthInfo))
                  end
              end
          end
      end)()

      print("✅ [Enhanced Silent Aim] Sistem aktif dengan damage boost options!")
  end
}