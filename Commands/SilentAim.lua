return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local CombatTab = tab or Tabs.Combat

      if not CombatTab then
          warn("[Silent Aim] Tab Combat tidak ditemukan!")
          return
      end

      local Group = CombatTab:AddLeftGroupbox("Silent Aim Pro")

      vars.SilentAim = vars.SilentAim or false
      vars.SilentAimTarget = vars.SilentAimTarget or "Head"
      vars.SilentAimFOV = vars.SilentAimFOV or 500
      vars.SilentAimWallCheck = vars.SilentAimWallCheck or false
      vars.SilentAimVelocity = vars.SilentAimVelocity or 999999
      vars.InstantKill = vars.InstantKill or true
      vars.TargetPriority = vars.TargetPriority or "LowHealth"

      -- Health data dari AI profiles
      local EnemyHealthData = {
          ["PL5_Rifleman"] = 130,
          ["PL5_HeliGunner"] = 110,
          ["PL5_Pilot"] = 200,
          ["PL5_Sniper"] = 100,
          ["PL5_Operator"] = 300,
          ["Dummy_Blind"] = 100,
          ["Dummy_Rifleman"] = 100,
          ["M1_SMG"] = 75,
          ["M1_SMG2"] = 75,
          ["M1_AK"] = 75,
          ["M1_AK2"] = 75,
          ["M1_PKM"] = 150,
          ["M1_Sniper"] = 75,
          ["M1_Friendly"] = 100,
          ["M1_Suspect"] = 1,  -- Sangat mudah dibunuh
          ["HS_Basic"] = 75
      }

      -- Damage data dari M855 (Head damage = 106.62)
      local M855Damage = {
          ["Head"] = 106.62,
          ["Torso"] = 73.17,
          ["Arms"] = 21,
          ["Legs"] = 24.4
      }

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

      -- Original functions backup
      local OriginalDischarge = BulletService.Discharge

      -- Function untuk mendapatkan health musuh
      local function getEnemyHealth(player)
          if not player.Character then return 100 end
          
          local humanoid = player.Character:FindFirstChild("Humanoid")
          if humanoid then
              return humanoid.Health
          end
          
          -- Coba deteksi berdasarkan appearance/type
          for enemyType, health in pairs(EnemyHealthData) do
              if string.find(player.Name, enemyType) or (player.Character and player.Character:FindFirstChild("Appearance")) then
                  return health
              end
          end
          
          return 100 -- Default
      end

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

      -- Advanced target selection dengan prioritas instant kill
      local function getBestTarget()
          local localPlayer = game.Players.LocalPlayer
          local localCharacter = localPlayer.Character
          if not localCharacter then return nil end
          
          local camera = game.Workspace.CurrentCamera
          local mousePos = game:GetService("UserInputService"):GetMouseLocation()
          
          local bestTarget = nil
          local bestScore = -math.huge

          for _, player in pairs(game.Players:GetPlayers()) do
              if player ~= localPlayer and player.Character then
                  local humanoid = player.Character:FindFirstChild("Humanoid")
                  if humanoid and humanoid.Health > 0 then
                      
                      local enemyHealth = getEnemyHealth(player)
                      local canInstantKill = false
                      
                      -- Cek berbagai part tubuh untuk instant kill
                      local bodyParts = {"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
                      
                      for _, partName in ipairs(bodyParts) do
                          local targetPart = player.Character:FindFirstChild(partName)
                          if targetPart then
                              local screenPoint, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                              
                              if onScreen then
                                  local distanceFromMouse = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
                                  
                                  if distanceFromMouse < vars.SilentAimFOV and isVisible(targetPart.Position, camera.CFrame.Position) then
                                      
                                      -- Kalkulasi score berdasarkan prioritas
                                      local score = 0
                                      
                                      -- Base score dari jarak mouse
                                      score = score + (vars.SilentAimFOV - distanceFromMouse)
                                      
                                      -- Bonus untuk headshot (instant kill potential)
                                      if partName == "Head" then
                                          score = score + 1000
                                          canInstantKill = (M855Damage.Head >= enemyHealth)
                                      elseif partName == "Torso" then
                                          score = score + 500
                                          canInstantKill = (M855Damage.Torso >= enemyHealth)
                                      end
                                      
                                      -- Bonus untuk low health enemies
                                      if enemyHealth <= 75 then
                                          score = score + 300
                                      elseif enemyHealth <= 100 then
                                          score = score + 200
                                      end
                                      
                                      -- Bonus untuk instant kill potential
                                      if canInstantKill then
                                          score = score + 2000
                                      end
                                      
                                      -- Prioritas berdasarkan setting
                                      if vars.TargetPriority == "LowHealth" then
                                          score = score + (200 - enemyHealth)
                                      elseif vars.TargetPriority == "Headshot" and partName == "Head" then
                                          score = score + 1500
                                      end
                                      
                                      if score > bestScore then
                                          bestScore = score
                                          bestTarget = {
                                              Player = player,
                                              Part = targetPart,
                                              Distance = distanceFromMouse,
                                              ScreenPosition = Vector2.new(screenPoint.X, screenPoint.Y),
                                              PartName = partName,
                                              Health = enemyHealth,
                                              CanInstantKill = canInstantKill,
                                              Score = score
                                          }
                                      end
                                  end
                              end
                          end
                      end
                  end
              end
          end
          
          return bestTarget
      end

      -- Hook BulletService.Discharge dengan instant kill
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
                  
                  -- Log info
                  local killType = targetData.CanInstantKill and "💀 INSTANT KILL" or "⚡ DAMAGE"
                  print(string.format("🎯 [Silent Aim] %s | Target: %s | Health: %d | Part: %s", 
                      killType, targetData.Player.Name, targetData.Health, targetData.PartName))
                  
                  -- Call original function with modified parameters
                  return OriginalDischarge(self, newCFrame, caliber, newVelocity, uid, replicate, isLocal, ...)
              end
          end
          
          return OriginalDischarge(self, originCFrame, caliber, velocity, uid, replicate, isLocal, ...)
      end

      -- UI Elements
      Group:AddToggle("ToggleSilentAim", {
          Text = "Enable Silent Aim",
          Default = vars.SilentAim,
          Callback = function(v)
              vars.SilentAim = v
              if v then
                  print("🎯 [Silent Aim] AUTO-LOCK Diaktifkan - Instant Kill System Active!")
              else
                  print("❌ [Silent Aim] Dimatikan")
              end
          end
      })

      Group:AddToggle("InstantKill", {
          Text = "Instant Kill Priority",
          Default = vars.InstantKill,
          Callback = function(v)
              vars.InstantKill = v
              if v then
                  print("💀 [Silent Aim] Instant Kill: PRIORITAS HEADSHOT")
              else
                  print("⚡ [Silent Aim] Instant Kill: STANDARD TARGETING")
              end
          end
      })

      Group:AddDropdown("TargetPriority", {
          Text = "Target Priority",
          Default = vars.TargetPriority,
          Values = {"LowHealth", "Headshot", "Closest"},
          Callback = function(v)
              vars.TargetPriority = v
              print("🎯 [Silent Aim] Prioritas: " .. v)
          end
      })

      Group:AddDropdown("SilentAimTarget", {
          Text = "Aim Part",
          Default = vars.SilentAimTarget,
          Values = {"Head", "Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
          Callback = function(v)
              vars.SilentAimTarget = v
              print("🎯 [Silent Aim] Aim part: " .. v)
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

      -- Visual indicator dengan info health
      local targetIndicator = Drawing.new("Circle")
      local healthText = Drawing.new("Text")
      
      targetIndicator.Visible = false
      targetIndicator.Thickness = 3
      targetIndicator.NumSides = 12
      targetIndicator.Radius = 8

      healthText.Visible = false
      healthText.Size = 16
      healthText.Center = true
      healthText.Outline = true

      -- Update visual indicator
      game:GetService("RunService").RenderStepped:Connect(function()
          if vars.SilentAim then
              local targetData = getBestTarget()
              if targetData then
                  targetIndicator.Visible = true
                  healthText.Visible = true
                  
                  targetIndicator.Position = targetData.ScreenPosition
                  healthText.Position = targetData.ScreenPosition + Vector2.new(0, 20)
                  
                  -- Warna berdasarkan instant kill potential
                  if targetData.CanInstantKill then
                      targetIndicator.Color = Color3.fromRGB(255, 0, 0)  -- Merah untuk instant kill
                      healthText.Color = Color3.fromRGB(255, 0, 0)
                      healthText.Text = "💀 " .. math.floor(targetData.Health)
                  else
                      targetIndicator.Color = Color3.fromRGB(0, 255, 0)  -- Hijau untuk damage
                      healthText.Color = Color3.fromRGB(0, 255, 0)
                      healthText.Text = math.floor(targetData.Health) .. " HP"
                  end
              else
                  targetIndicator.Visible = false
                  healthText.Visible = false
              end
          else
              targetIndicator.Visible = false
              healthText.Visible = false
          end
      end)

      -- Auto rehook system
      local function rehookIfNeeded()
          if BulletService.Discharge == OriginalDischarge then
              BulletService.Discharge = function(self, ...)
                  local args = {...}
                  local originCFrame, caliber, velocity, uid, replicate, isLocal = args[1], args[2], args[3], args[4], args[5], args[6]
                  
                  if vars.SilentAim and isLocal then
                      local targetData = getBestTarget()
                      
                      if targetData and targetData.Part then
                          local newOrigin = originCFrame.Position
                          local newLookVector = (targetData.Part.Position - newOrigin).Unit
                          local newCFrame = CFrame.new(newOrigin, newOrigin + newLookVector)
                          local newVelocity = vars.SilentAimVelocity
                          
                          args[1] = newCFrame
                          args[3] = newVelocity
                          
                          return OriginalDischarge(self, unpack(args))
                      end
                  end
                  
                  return OriginalDischarge(self, ...)
              end
              print("🔧 [Silent Aim] Re-hook successful")
          end
      end

      -- Periodic rehook
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

      -- Cleanup
      game.Players.LocalPlayer.CharacterAdded:Connect(function()
          wait(2)
          rehookIfNeeded()
      end)

      print("✅ [Silent Aim Pro] Instant Kill System Loaded!")
      print("💀 M855 Head Damage: " .. M855Damage.Head .. " (Instant kill untuk musuh <107 HP)")
      print("🎯 AI Health Range: 1-300 HP")
  end
}