return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local CombatTab = tab or Tabs.Combat

      if not CombatTab then
          warn("[Silent Aim] Tab Combat tidak ditemukan!")
          return
      end

      local Group = CombatTab:AddLeftGroupbox("Silent Aim NPC Male + No Recoil")

      -- Settings
      vars.SilentAim = vars.SilentAim or false
      vars.NoRecoil = vars.NoRecoil or false
      vars.HeadshotOnly = vars.HeadshotOnly or true
      vars.FOV = vars.FOV or 100
      vars.MaxDistance = vars.MaxDistance or 500

      -- FOV Circle (Visual)
      local circle = Drawing.new("Circle")
      circle.Visible = false
      circle.Radius = vars.FOV
      circle.Color = Color3.fromRGB(255, 255, 255)
      circle.Thickness = 2
      circle.Position = workspace.CurrentCamera.ViewportSize / 2

      -- Find closest Male NPC
      local function getClosestMaleNPC()
          local closestNPC = nil
          local closestDistance = vars.FOV
          local mousePos = workspace.CurrentCamera.ViewportSize / 2
          local camera = workspace.CurrentCamera
          
          -- Cari semua model Male di workspace
          for _, male in pairs(workspace:GetDescendants()) do
              if male:IsA("Model") and male.Name == "Male" and male:FindFirstChild("Head") then
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
                      local direction = (headPos - originCFrame.Position).Unit
                      
                      -- Create new CFrame pointing to head
                      local newCFrame = CFrame.lookAt(originCFrame.Position, headPos)
                      
                      print("🎯 Silent Aim: Targeting Male NPC head")
                      print("   Head Position: " .. tostring(headPos))
                      print("   Distance: " .. math.floor((headPos - originCFrame.Position).Magnitude))
                      
                      return originalDischarge(self, newCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                  else
                      print("❌ No Male NPC found in FOV")
                  end
              end
              
              return originalDischarge(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
          end
      end

      -- UI Elements
      Group:AddToggle("ToggleSilentAim", {
          Text = "Silent Aim NPC Male",
          Default = vars.SilentAim,
          Callback = function(v)
              vars.SilentAim = v
              circle.Visible = v
          end
      })

      Group:AddToggle("ToggleHeadshot", {
          Text = "Headshot Only",
          Default = vars.HeadshotOnly,
          Callback = function(v)
              vars.HeadshotOnly = v
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
          Max = 1000,
          Rounding = 0,
          Callback = function(v)
              vars.MaxDistance = v
          end
      })

      -- No Recoil System
      Group:AddToggle("ToggleNoRecoil", {
          Text = "No Recoil",
          Default = vars.NoRecoil,
          Callback = function(v)
              vars.NoRecoil = v
              if v then
                  local success, Calibers = pcall(function()
                      return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                  end)
                  
                  if success and Calibers then
                      if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                          Calibers.v1.intermediaterifle_556x45mmNATO_M855["RecoilForce"] = 0
                      elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                          Calibers.intermediaterifle_556x45mmNATO_M855["RecoilForce"] = 0
                      end
                  end
              else
                  -- Reset recoil
                  local success, Calibers = pcall(function()
                      return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                  end)
                  
                  if success and Calibers then
                      if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                          Calibers.v1.intermediaterifle_556x45mmNATO_M855["RecoilForce"] = 100
                      elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                          Calibers.intermediaterifle_556x45mmNATO_M855["RecoilForce"] = 100
                      end
                  end
              end
          end
      })

      -- Update FOV circle position
      game:GetService("RunService").RenderStepped:Connect(function()
          circle.Position = workspace.CurrentCamera.ViewportSize / 2
      end)

      -- Debug info
      coroutine.wrap(function()
          while wait(2) do
              if vars.SilentAim then
                  local target = getClosestMaleNPC()
                  if target then
                      local distance = (target.Head.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                      print(string.format("🎯 Male NPC Target: Distance %.1f studs", distance))
                  end
              end
          end
      end)()

      print("✅ [Silent Aim NPC Male] Sistem aktif. Target otomatis ke kepala Male NPC terdekat.")
  end
}