return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local CombatTab = tab or Tabs.Combat

      if not CombatTab then
          warn("[Silent Aim] Tab Combat tidak ditemukan!")
          return
      end

      local Group = CombatTab:AddLeftGroupbox("Silent Aim + No Recoil")

      -- Settings
      vars.SilentAim = vars.SilentAim or false
      vars.NoRecoil = vars.NoRecoil or false
      vars.HeadshotOnly = vars.HeadshotOnly or true
      vars.FOV = vars.FOV or 100

      -- FOV Circle (Visual)
      local circle = Drawing.new("Circle")
      circle.Visible = false
      circle.Radius = vars.FOV
      circle.Color = Color3.fromRGB(255, 255, 255)
      circle.Thickness = 2
      circle.Position = workspace.CurrentCamera.ViewportSize / 2

      -- Get Players
      local Players = game:GetService("Players")
      local LocalPlayer = Players.LocalPlayer
      
      -- Find closest player to crosshair
      local function getClosestPlayer()
          local closestPlayer = nil
          local closestDistance = vars.FOV
          local mousePos = workspace.CurrentCamera.ViewportSize / 2
          
          for _, player in pairs(Players:GetPlayers()) do
              if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                  local headPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(player.Character.Head.Position)
                  
                  if onScreen then
                      local distance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(headPos.X, headPos.Y)).Magnitude
                      
                      if distance < closestDistance then
                          closestDistance = distance
                          closestPlayer = player
                      end
                  end
              end
          end
          
          return closestPlayer
      end

      -- Hook BulletService untuk silent aim
      local originalDischarge
      local BulletService = require(game:GetService("ReplicatedStorage").Shared.Services.BulletService)
      
      if BulletService and not getgenv().SilentAimHooked then
          getgenv().SilentAimHooked = true
          originalDischarge = BulletService.Discharge
          
          BulletService.Discharge = function(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
              if vars.SilentAim then
                  local target = getClosestPlayer()
                  
                  if target and target.Character and target.Character:FindFirstChild("Head") then
                      -- Calculate direction to head
                      local headPos = target.Character.Head.Position
                      local direction = (headPos - originCFrame.Position).Unit
                      
                      -- Create new CFrame pointing to head
                      local newCFrame = CFrame.lookAt(originCFrame.Position, headPos)
                      
                      print("🎯 Silent Aim: Targeting " .. target.Name .. " head")
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
          Min = 100,
          Max = 500,
          Rounding = 0,
          Callback = function(v)
              vars.FOV = v
              circle.Radius = v
          end
      })

      -- No Recoil System (dari kode asli)
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

      print("✅ [Silent Aim] Sistem aktif. Target otomatis ke head player terdekat dalam FOV.")
  end
}