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
      local Actor = ReplicatedFirst:FindFirstChild("Actor")
      local BulletServiceMultithread = Actor and Actor:FindFirstChild("BulletServiceMultithread")
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
          
          local localPlayer = game.Players.LocalPlayer
          local localCharacter = localPlayer.Character
          if not localCharacter then return false end
          
          local direction = (targetPosition - origin).Unit
          local distance = (targetPosition - origin).Magnitude
          
          local raycastParams = RaycastParams.new()
          raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
          raycastParams.FilterDescendantsInstances = {localCharacter}
          
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

      -- Hook 1: BulletService.Discharge (High Level) - INI YANG PALING PENTING
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

      -- Hook 2: Direct manipulation melalui BulletEvent (Alternative method)
      local OriginalBulletEventFire
      
      -- Coba hook BulletEvent jika ada
      if BulletEvent then
          OriginalBulletEventFire = BulletEvent.Fire
          BulletEvent.Fire = function(self, ...)
              local args = {...}
              
              if vars.SilentAim and args[1] == 1 then -- Check jika ini bullet event
                  local targetData = getBestTarget()
                  
                  if targetData and targetData.Part then
                      print("🎯 [Silent Aim] BulletEvent intercepted: " .. targetData.Player.Name)
                      -- Di sini kita bisa modify args jika diperlukan
                  end
              end
              
              return OriginalBulletEventFire(self, ...)
          end
      end

      -- Hook 3: Manipulasi langsung melalui module script
      local function modifyBulletTrajectory(originCFrame, targetPosition)
          local newOrigin = originCFrame.Position
          local newLookVector = (targetPosition - newOrigin).Unit
          return CFrame.new(newOrigin, newOrigin + newLookVector)
      end

      -- Hook untuk memastikan perubahan tetap berlaku
      local function rehookIfNeeded()
          if BulletService.Discharge == OriginalDischarge then
              BulletService.Discharge = function(self, ...)
                  local args = {...}
                  local originCFrame, caliber, velocity, uid, replicate, isLocal = args[1], args[2], args[3], args[4], args[5], args[6]
                  
                  if vars.SilentAim and isLocal then
                      local targetData = getBestTarget()
                      
                      if targetData and targetData.Part then
                          local newCFrame = modifyBulletTrajectory(originCFrame, targetData.Part.Position)
                          local newVelocity = vars.SilentAimVelocity
                          
                          print("🎯 [Silent Aim] Re-hooked: " .. targetData.Player.Name)
                          
                          args[1] = newCFrame
                          args[3] = newVelocity
                          
                          return OriginalDischarge(self, unpack(args))
                      end
                  end
                  
                  return OriginalDischarge(self, ...)
              end
          end
      end

      -- UI Elements
      Group:AddToggle("ToggleSilentAim", {
          Text = "Enable Silent Aim",
          Default = vars.SilentAim,
          Callback = function(v)
              vars.SilentAim = v
              if v then
                  print("🎯 [Silent Aim] AUTO-LOCK Diaktifkan - Tembak saja!")
                  rehookIfNeeded()
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

      -- Periodic rehook untuk memastikan hook tetap aktif
      if not getgenv().SilentAimRehook then
          getgenv().SilentAimRehook = true
          coroutine.wrap(function()
              while wait(5) do
                  if vars.SilentAim then
                      rehookIfNeeded()
                  end
              end
          end)()
      end

      -- Cleanup ketika character respawn
      game.Players.LocalPlayer.CharacterAdded:Connect(function()
          wait(2)
          rehookIfNeeded()
      end)

      print("✅ [Silent Aim] System loaded!")
      print("🎯 Primary Hook: BulletService.Discharge")
      print("🎯 Secondary Hook: BulletEvent (jika tersedia)")
      print("🎯 Auto-rehook system: Active")
  end
}