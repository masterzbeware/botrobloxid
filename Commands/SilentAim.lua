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

      vars.SilentAim = vars.SilentAim or false
      vars.SilentAimTarget = vars.SilentAimTarget or "Head"
      vars.SilentAimFOV = vars.SilentAimFOV or 50

      -- Get BulletService
      local BulletService
      local success, result = pcall(function()
          return require(game:GetService("ReplicatedStorage").Shared.Services.BulletService)
      end)
      
      if success then
          BulletService = result
          print("✅ [Silent Aim] BulletService berhasil dimuat")
      else
          warn("❌ [Silent Aim] Gagal memuat BulletService: " .. tostring(result))
          return
      end

      -- Original functions backup
      local OriginalDischarge = BulletService.Discharge

      -- Silent Aim function
      local function getClosestPlayer()
          local localPlayer = game.Players.LocalPlayer
          local localCharacter = localPlayer.Character
          if not localCharacter then return nil end
          
          local localHead = localCharacter:FindFirstChild("Head")
          if not localHead then return nil end

          local closestPlayer = nil
          local closestDistance = vars.SilentAimFOV

          for _, player in pairs(game.Players:GetPlayers()) do
              if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                  local targetPart = player.Character:FindFirstChild(vars.SilentAimTarget)
                  if targetPart then
                      local screenPoint, visible = game.Workspace.CurrentCamera:WorldToViewportPoint(targetPart.Position)
                      
                      if visible then
                          local mouse = game:GetService("UserInputService"):GetMouseLocation()
                          local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                          
                          if distance < closestDistance then
                              closestDistance = distance
                              closestPlayer = player
                          end
                      end
                  end
              end
          end
          
          return closestPlayer, closestDistance
      end

      -- Hook Discharge function
      BulletService.Discharge = function(self, originCFrame, caliber, velocity, uid, replicate, isLocal, ...)
          if vars.SilentAim and isLocal then
              local targetPlayer, distance = getClosestPlayer()
              
              if targetPlayer and targetPlayer.Character then
                  local targetPart = targetPlayer.Character:FindFirstChild(vars.SilentAimTarget)
                  if targetPart then
                      -- Calculate new CFrame aiming at target
                      local newOrigin = originCFrame.Position
                      local newLookVector = (targetPart.Position - newOrigin).Unit
                      
                      -- Create new CFrame aiming at target
                      local newCFrame = CFrame.new(newOrigin, newOrigin + newLookVector)
                      
                      print("🎯 [Silent Aim] Target locked: " .. targetPlayer.Name .. " | Distance: " .. math.floor(distance))
                      
                      -- Call original function with modified CFrame
                      return OriginalDischarge(self, newCFrame, caliber, velocity, uid, replicate, isLocal, ...)
                  end
              end
          end
          
          -- Call original function if silent aim is off or no target
          return OriginalDischarge(self, originCFrame, caliber, velocity, uid, replicate, isLocal, ...)
      end

      -- UI Elements
      Group:AddToggle("ToggleSilentAim", {
          Text = "Enable Silent Aim",
          Default = vars.SilentAim,
          Callback = function(v)
              vars.SilentAim = v
              if v then
                  print("🎯 [Silent Aim] Diaktifkan")
              else
                  print("❌ [Silent Aim] Dimatikan")
              end
          end
      })

      Group:AddDropdown("SilentAimTarget", {
          Text = "Target Part",
          Default = vars.SilentAimTarget,
          Values = {"Head", "HumanoidRootPart", "Torso", "LeftHand", "RightHand", "LeftFoot", "RightFoot"},
          Callback = function(v)
              vars.SilentAimTarget = v
              print("🎯 [Silent Aim] Target part: " .. v)
          end
      })

      Group:AddSlider("SilentAimFOV", {
          Text = "FOV Radius",
          Default = vars.SilentAimFOV,
          Min = 10,
          Max = 200,
          Rounding = 0,
          Callback = function(v)
              vars.SilentAimFOV = v
          end
      })

      Group:AddLabel("FOV: " .. vars.SilentAimFOV)

      -- FOV Visualization (optional)
      local circle
      local function updateFOVCircle()
          if circle then
              circle:Remove()
          end
          
          if vars.ShowFOV then
              circle = Drawing.new("Circle")
              circle.Visible = true
              circle.Thickness = 2
              circle.Color = Color3.fromRGB(255, 255, 255)
              circle.Transparency = 1
              circle.NumSides = 64
              circle.Radius = vars.SilentAimFOV
              
              game:GetService("RunService").RenderStepped:Connect(function()
                  local mouse = game:GetService("UserInputService"):GetMouseLocation()
                  circle.Position = Vector2.new(mouse.X, mouse.Y)
              end)
          end
      end

      Group:AddToggle("ShowFOV", {
          Text = "Show FOV Circle",
          Default = false,
          Callback = function(v)
              vars.ShowFOV = v
              updateFOVCircle()
          end
      })

      -- Cleanup when GUI is closed
      if not getgenv().SilentAimHooked then
          getgenv().SilentAimHooked = true
          
          game.Players.LocalPlayer.CharacterAdded:Connect(function()
              -- Re-hook when character respawns
              wait(2)
              if BulletService.Discharge ~= OriginalDischarge then
                  local currentHook = BulletService.Discharge
                  BulletService.Discharge = OriginalDischarge
                  BulletService.Discharge = currentHook
              end
          end)
          
          print("✅ [Silent Aim] Sistem berhasil diinisialisasi")
      end

      print("✅ [Silent Aim] Module siap digunakan!")
  end
}