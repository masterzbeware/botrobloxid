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
      vars.SilentAimFOV = vars.SilentAimFOV or 500
      vars.SilentAimWallCheck = vars.SilentAimWallCheck or false
      vars.SilentAimVelocity = vars.SilentAimVelocity or 999999

      -- Services
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      
      -- Get BulletService
      local BulletService
      local success, result = pcall(function()
          return require(ReplicatedStorage.Shared.Services.BulletService)
      end)
      
      if success then
          BulletService = result
          print("✅ [Silent Aim] BulletService berhasil dimuat")
      else
          warn("❌ [Silent Aim] Gagal memuat BulletService: " .. tostring(result))
          return
      end

      -- Find important objects
      local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent")
      local BulletServiceMultithread = ReplicatedFirst:FindFirstChild("Actor"):FindFirstChild("BulletServiceMultithread")
      local SendEvent = BulletServiceMultithread and BulletServiceMultithread:FindFirstChild("Send")

      if not BulletEvent or not SendEvent then
          warn("❌ [Silent Aim] Gagal menemukan event penting!")
          return
      end

      -- Original functions backup
      local OriginalDischarge = BulletService.Discharge

      -- Function untuk cek wall
      local function isVisible(targetPosition, origin)
          if not vars.SilentAimWallCheck then return true end
          
          local direction = (targetPosition - origin).Unit
          local distance = (targetPosition - origin).Magnitude
          
          local raycastParams = RaycastParams.new()
          raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
          raycastParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}
          
          local result = workspace:Raycast(origin, direction * distance, raycastParams)
          return result == nil
      end

      -- Silent Aim function yang lebih akurat
      local function getBestTarget()
          local localPlayer = game.Players.LocalPlayer
          local localCharacter = localPlayer.Character
          if not localCharacter then return nil end
          
          local camera = game.Workspace.CurrentCamera
          local mousePos = game:GetService("UserInputService"):GetMouseLocation()
          
          local bestTarget = nil
          local bestDistance = vars.SilentAimFOV

          for _, player in pairs(game.Players:GetPlayers()) do
              if player ~= localPlayer and player.Character then
                  local humanoid = player.Character:FindFirstChild("Humanoid")
                  if humanoid and humanoid.Health > 0 then
                      
                      -- Coba berbagai part tubuh berdasarkan damage table
                      local bodyParts = {"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
                      
                      for _, partName in ipairs(bodyParts) do
                          local targetPart = player.Character:FindFirstChild(partName)
                          if targetPart then
                              local screenPoint, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                              
                              if onScreen then
                                  local distanceFromMouse = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
                                  
                                  -- Prioritaskan yang dekat dengan crosshair dan visible
                                  if distanceFromMouse < bestDistance and isVisible(targetPart.Position, camera.CFrame.Position) then
                                      bestDistance = distanceFromMouse
                                      bestTarget = {
                                          Player = player,
                                          Part = targetPart,
                                          Distance = distanceFromMouse,
                                          ScreenPosition = Vector2.new(screenPoint.X, screenPoint.Y),
                                          PartName = partName
                                      }
                                  end
                              end
                          end
                      end
                  end
              end
          end
          
          return bestTarget
      end

      -- Hook 1: BulletService.Discharge (High Level)
      BulletService.Discharge = function(self, originCFrame, caliber, velocity, uid, replicate, isLocal, ...)
          if vars.SilentAim and isLocal then
              local targetData = getBestTarget()
              
              if targetData and targetData.Part then
                  -- Calculate new CFrame aiming directly at target
                  local newOrigin = originCFrame.Position
                  local newLookVector = (targetData.Part.Position - newOrigin).Unit
                  
                  -- Create new CFrame aiming precisely at target
                  local newCFrame = CFrame.new(newOrigin, newOrigin + newLookVector)
                  
                  -- Gunakan velocity tinggi untuk instant hit
                  local newVelocity = vars.SilentAimVelocity
                  
                  print("🎯 [Silent Aim] Locked: " .. targetData.Player.Name .. " | Part: " .. targetData.PartName)
                  
                  -- Call original function with modified parameters
                  return OriginalDischarge(self, newCFrame, caliber, newVelocity, uid, replicate, isLocal, ...)
              end
          end
          
          return OriginalDischarge(self, originCFrame, caliber, velocity, uid, replicate, isLocal, ...)
      end

      -- Hook 2: Direct Send Event (Low Level)
      local OriginalSendFire = SendEvent.Fire
      SendEvent.Fire = function(self, ...)
          local args = {...}
          
          if vars.SilentAim and args[1] == 1 then -- Check if it's a bullet send
              local targetData = getBestTarget()
              
              if targetData and targetData.Part then
                  -- Modify the bullet data
                  local bulletData = args[3]
                  if bulletData and bulletData.OriginCFrame then
                      local newOrigin = bulletData.OriginCFrame.Position
                      local newLookVector = (targetData.Part.Position - newOrigin).Unit
                      local newCFrame = CFrame.new(newOrigin, newOrigin + newLookVector)
                      
                      -- Update bullet data
                      bulletData.OriginCFrame = newCFrame
                      bulletData.Velocity = vars.SilentAimVelocity
                      bulletData.Range = 999999
                      
                      print("🎯 [Silent Aim] Direct Send Modified: " .. targetData.Player.Name)
                  end
              end
          end
          
          return OriginalSendFire(self, ...)
      end

      -- Hook 3: RemoteEvent untuk ActionActor
      local RemoteEvent = ReplicatedStorage.Events.RemoteEvent
      local OriginalFireSignal
      
      -- Hook firesignal jika memungkinkan
      if getgenv().firesignal then
          OriginalFireSignal = getgenv().firesignal
          getgenv().firesignal = function(event, ...)
              local args = {...}
              
              if event == RemoteEvent and vars.SilentAim then
                  if args[1] == "ActionActor" and args[4] == "Discharge" then
                      local targetData = getBestTarget()
                      
                      if targetData and targetData.Part then
                          -- Modify discharge data
                          local dischargeData = args[5]
                          if dischargeData and dischargeData[1] then
                              local originCFrame = dischargeData[1]
                              local newOrigin = originCFrame.Position
                              local newLookVector = (targetData.Part.Position - newOrigin).Unit
                              local newCFrame = CFrame.new(newOrigin, newOrigin + newLookVector)
                              
                              dischargeData[1] = newCFrame
                              print("🎯 [Silent Aim] RemoteEvent Modified: " .. targetData.Player.Name)
                          end
                      end
                  end
              end
              
              return OriginalFireSignal(event, ...)
          end
      end

      -- UI Elements
      Group:AddToggle("ToggleSilentAim", {
          Text = "Enable Silent Aim",
          Default = vars.SilentAim,
          Callback = function(v)
              vars.SilentAim = v
              if v then
                  print("🎯 [Silent Aim] AUTO-LOCK Diaktifkan - Multi-layer hook aktif!")
              else
                  print("❌ [Silent Aim] Dimatikan")
              end
          end
      })

      Group:AddDropdown("SilentAimTarget", {
          Text = "Prioritas Target",
          Default = vars.SilentAimTarget,
          Values = {"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
          Callback = function(v)
              vars.SilentAimTarget = v
              print("🎯 [Silent Aim] Prioritas target: " .. v)
          end
      })

      Group:AddSlider("SilentAimFOV", {
          Text = "Lock Radius",
          Default = vars.SilentAimFOV,
          Min = 50,
          Max = 1000,
          Rounding = 0,
          Callback = function(v)
              vars.SilentAimFOV = v
          end
      })

      Group:AddSlider("SilentAimVelocity", {
          Text = "Bullet Velocity",
          Default = vars.SilentAimVelocity,
          Min = 1000,
          Max = 9999999,
          Rounding = 0,
          Callback = function(v)
              vars.SilentAimVelocity = v
          end
      })

      Group:AddLabel("Lock Radius: " .. vars.SilentAimFOV)
      Group:AddLabel("Velocity: " .. vars.SilentAimVelocity)

      Group:AddToggle("WallCheck", {
          Text = "Wall Check",
          Default = vars.SilentAimWallCheck,
          Callback = function(v)
              vars.SilentAimWallCheck = v
              if v then
                  print("🎯 [Silent Aim] Wall Check: AKTIF")
              else
                  print("🎯 [Silent Aim] Wall Check: NON-AKTIF")
              end
          end
      })

      -- Visual indicator
      local targetIndicator = Drawing.new("Circle")
      targetIndicator.Visible = false
      targetIndicator.Color = Color3.fromRGB(0, 255, 0)
      targetIndicator.Thickness = 3
      targetIndicator.NumSides = 12
      targetIndicator.Radius = 8

      -- Update visual indicator
      game:GetService("RunService").RenderStepped:Connect(function()
          if vars.SilentAim then
              local targetData = getBestTarget()
              if targetData then
                  targetIndicator.Visible = true
                  targetIndicator.Position = targetData.ScreenPosition
                  targetIndicator.Color = Color3.fromRGB(0, 255, 0)
              else
                  targetIndicator.Visible = false
              end
          else
              targetIndicator.Visible = false
          end
      end)

      -- Cleanup function
      local function cleanup()
          if OriginalDischarge then
              BulletService.Discharge = OriginalDischarge
          end
          if OriginalSendFire then
              SendEvent.Fire = OriginalSendFire
          end
          if OriginalFireSignal then
              getgenv().firesignal = OriginalFireSignal
          end
          targetIndicator:Remove()
      end

      -- Auto cleanup
      game.Players.LocalPlayer.CharacterAdded:Connect(function()
          wait(1)
          cleanup()
          -- Re-initialize setelah respawn
          wait(2)
      end)

      print("✅ [Silent Aim] Multi-layer silent aim loaded!")
      print("🎯 Hooked: BulletService.Discharge, SendEvent, RemoteEvent")
  end
}