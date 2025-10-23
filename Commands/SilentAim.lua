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
      vars.HeadshotOnly = vars.HeadshotOnly or true
      vars.MaxDistance = 400  -- Fixed distance 400 studs

      -- Function to check if model has AI_ child
      local function hasAIChild(model)
          for _, child in pairs(model:GetChildren()) do
              if string.sub(child.Name, 1, 3) == "AI_" then
                  return true
              end
          end
          return false
      end

      -- Find closest Male NPC dengan filter AI_ (tanpa FOV)
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
                      local headPos = male.Head.Position
                      
                      -- Check distance from player saja (tanpa FOV)
                      local distanceFromPlayer = (headPos - playerPosition).Magnitude
                      
                      if distanceFromPlayer <= vars.MaxDistance then
                          if distanceFromPlayer < closestDistance then
                              closestDistance = distanceFromPlayer
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
                      
                      local distance = math.floor((headPos - originCFrame.Position).Magnitude)
                      print("🎯 Silent Aim: Targeting Male NPC with AI")
                      print("   Head Position: " .. tostring(headPos))
                      print("   Distance: " .. distance .. " studs")
                      print("   AI Children: " .. table.concat(aiChildren, ", "))
                      
                      return originalDischarge(self, newCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                  else
                      print("❌ No Male NPC with AI found within " .. vars.MaxDistance .. " studs")
                  end
              end
              
              return originalDischarge(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
          end
      end

      -- UI Elements (sederhana, tanpa FOV)
      Group:AddToggle("ToggleSilentAim", {
          Text = "Silent Aim NPC Male AI",
          Default = vars.SilentAim,
          Callback = function(v)
              vars.SilentAim = v
          end
      })

      Group:AddToggle("ToggleHeadshot", {
          Text = "Headshot Only",
          Default = vars.HeadshotOnly,
          Callback = function(v)
              vars.HeadshotOnly = v
          end
      })

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
                      print("🔍 No Male NPC with AI found within " .. vars.MaxDistance .. " studs")
                      
                      -- Debug: list semua Male dengan AI di workspace beserta jaraknya
                      local maleWithAI = 0
                      local cameraPos = workspace.CurrentCamera.CFrame.Position
                      
                      for _, male in pairs(workspace:GetDescendants()) do
                          if male:IsA("Model") and male.Name == "Male" and hasAIChild(male) then
                              local distance = (male.Head.Position - cameraPos).Magnitude
                              maleWithAI = maleWithAI + 1
                              print(string.format("   Male #%d: %.1f studs", maleWithAI, distance))
                          end
                      end
                      
                      if maleWithAI > 0 then
                          print("   Total Male with AI in workspace: " .. maleWithAI)
                      else
                          print("   ❌ No Male with AI found in entire workspace")
                      end
                  end
              end
          end
      end)()

      print("✅ [Silent Aim NPC Male AI] Sistem aktif.")
      print("   Target: Male dengan komponen AI")
      print("   Max Distance: " .. vars.MaxDistance .. " studs")
      print("   FOV: Disabled (target terdekat dalam radius)")
  end
}