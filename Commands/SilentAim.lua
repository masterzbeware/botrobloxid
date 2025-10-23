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
      vars.BodyPart = vars.BodyPart or "Head"  -- Default head
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

      -- Function to check if target visible (no walls in between)
      local function isTargetVisible(targetPart, originPosition)
          -- Raycast from player to target part
          local rayOrigin = originPosition
          local rayDirection = (targetPart.Position - originPosition).Unit
          local rayDistance = (targetPart.Position - originPosition).Magnitude
          
          local raycastParams = RaycastParams.new()
          raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
          raycastParams.FilterDescendantsInstances = {workspace.CurrentCamera}
          raycastParams.IgnoreWater = true
          
          local rayResult = workspace:Raycast(rayOrigin, rayDirection * rayDistance, raycastParams)
          
          if rayResult then
              -- Jika raycast kena sesuatu sebelum target
              local hitInstance = rayResult.Instance
              if hitInstance and hitInstance:IsDescendantOf(targetPart.Parent) then
                  -- Kena target sendiri (visible)
                  return true
              else
                  -- Kena wall/obstacle sebelum target
                  return false
              end
          end
          
          -- No obstacles found (visible)
          return true
      end

      -- Find closest Male NPC dengan filter AI_ dan wall check
      local function getClosestMaleNPC()
          local closestNPC = nil
          local closestDistance = vars.MaxDistance
          local camera = workspace.CurrentCamera
          local playerPosition = camera.CFrame.Position
          
          -- Cari semua model Male di workspace yang memiliki child AI_
          for _, male in pairs(workspace:GetDescendants()) do
              if male:IsA("Model") and male.Name == "Male" and male:FindFirstChild("Head") then
                  
                  -- Filter: hanya yang memiliki child dengan nama diawali "AI_"
                  if hasAIChild(male) then
                      local head = male.Head
                      local headPos = head.Position
                      
                      -- Check distance from player
                      local distanceFromPlayer = (headPos - playerPosition).Magnitude
                      
                      if distanceFromPlayer <= vars.MaxDistance then
                          -- Check if target is visible (no walls)
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

      -- Get target body part position based on selection
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
              -- Fallback to Head jika bagian tubuh tidak ditemukan
              return targetNPC:FindFirstChild("Head") or targetNPC:FindFirstChild("HumanoidRootPart")
          end
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
                  
                  if targetNPC then
                      local targetPart = getTargetBodyPart(targetNPC)
                      
                      if targetPart then
                          -- Calculate direction to body part
                          local partPos = targetPart.Position
                          
                          -- Create new CFrame pointing to body part
                          local newCFrame = CFrame.lookAt(originCFrame.Position, partPos)
                          
                          -- Get AI child names for debug
                          local aiChildren = {}
                          for _, child in pairs(targetNPC:GetChildren()) do
                              if string.sub(child.Name, 1, 3) == "AI_" then
                                  table.insert(aiChildren, child.Name)
                              end
                          end
                          
                          local distance = math.floor((partPos - originCFrame.Position).Magnitude)
                          print("🎯 Silent Aim: Targeting " .. vars.BodyPart)
                          print("   Target: " .. targetNPC.Name)
                          print("   Body Part: " .. targetPart.Name)
                          print("   Position: " .. tostring(partPos))
                          print("   Distance: " .. distance .. " studs")
                          print("   AI Components: " .. table.concat(aiChildren, ", "))
                          
                          return originalDischarge(self, newCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                      end
                  else
                      print("❌ No visible Male NPC with AI found within " .. vars.MaxDistance .. " studs")
                  end
              end
              
              return originalDischarge(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
          end
      end

      -- UI Elements (Simple - hanya 1 toggle + 1 dropdown)
      Group:AddToggle("ToggleSilentAim", {
          Text = "Silent Aim NPC Male AI",
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
          Text = "Target Body Part",
          Default = vars.BodyPart,
          Values = {"Head", "UpperTorso", "HumanoidRootPart", "Torso"},
          Callback = function(v)
              vars.BodyPart = v
              print("🎯 Body Part changed to: " .. v)
          end
      })

      -- Debug info
      coroutine.wrap(function()
          while wait(3) do
              if vars.SilentAim then
                  local target = getClosestMaleNPC()
                  if target then
                      local targetPart = getTargetBodyPart(target)
                      local distance = (targetPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                      
                      -- Count AI children
                      local aiCount = 0
                      for _, child in pairs(target:GetChildren()) do
                          if string.sub(child.Name, 1, 3) == "AI_" then
                              aiCount = aiCount + 1
                          end
                      end
                      
                      print(string.format("🎯 Locked: %s | Part: %s | Distance: %.1f studs | AI: %d", 
                          target.Name, targetPart.Name, distance, aiCount))
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