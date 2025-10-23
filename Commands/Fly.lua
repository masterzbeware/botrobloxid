return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local CombatTab = tab or Tabs.Combat

      if not CombatTab then
          warn("[Flying] Tab Combat tidak ditemukan!")
          return
      end

      local Group = CombatTab:AddLeftGroupbox("Flying System")

      vars.Flying = vars.Flying or false

      -- Variables untuk flying
      local flying = false
      local flySpeed = 50
      local bodyVelocity
      local bodyGyro
      local player = game:GetService("Players").LocalPlayer
      local character = player.Character or player.CharacterAdded:Wait()
      local humanoid = character:WaitForChild("Humanoid")
      local rootPart = character:WaitForChild("HumanoidRootPart")

      -- Fungsi untuk memulai terbang
      local function startFlying()
          if flying or not rootPart then return end
          
          flying = true
          humanoid.PlatformStand = true
          
          -- Buat BodyVelocity untuk pergerakan
          bodyVelocity = Instance.new("BodyVelocity")
          bodyVelocity.Velocity = Vector3.new(0, 0, 0)
          bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
          bodyVelocity.Parent = rootPart
          
          -- Buat BodyGyro untuk stabilitas
          bodyGyro = Instance.new("BodyGyro")
          bodyGyro.MaxTorque = Vector3.new(50000, 50000, 50000)
          bodyGyro.P = 1000
          bodyGyro.D = 50
          bodyGyro.Parent = rootPart
          
          print("✅ Flying mode: ON")
      end

      -- Fungsi untuk berhenti terbang
      local function stopFlying()
          if not flying then return end
          
          flying = false
          humanoid.PlatformStand = false
          
          if bodyVelocity then
              bodyVelocity:Destroy()
              bodyVelocity = nil
          end
          
          if bodyGyro then
              bodyGyro:Destroy()
              bodyGyro = nil
          end
          
          print("❌ Flying mode: OFF")
      end

      -- Auto movement flying (bergerak otomatis mengikuti arah kamera)
      local function updateFlying()
          if not flying or not bodyVelocity or not bodyGyro then return end
          
          local cam = workspace.CurrentCamera
          local moveDirection = cam.CFrame.LookVector
          
          -- Terapkan velocity untuk bergerak maju secara otomatis
          bodyVelocity.Velocity = moveDirection * flySpeed
          
          -- Update gyro untuk menghadap ke arah kamera
          bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + moveDirection)
      end

      -- Handle character respawn
      local function onCharacterAdded(newCharacter)
          character = newCharacter
          humanoid = character:WaitForChild("Humanoid")
          rootPart = character:WaitForChild("HumanoidRootPart")
          
          -- Reset flying state saat respawn
          flying = false
      end

      -- Connect events
      game:GetService("RunService").Heartbeat:Connect(updateFlying)
      player.CharacterAdded:Connect(onCharacterAdded)

      Group:AddToggle("ToggleFlying", {
          Text = "Enable Flying",
          Default = vars.Flying,
          Callback = function(v)
              vars.Flying = v
              if v then
                  startFlying()
              else
                  stopFlying()
              end
          end
      })

      -- Slider untuk mengatur kecepatan terbang
      Group:AddSlider("FlySpeed", {
          Text = "Fly Speed",
          Default = 50,
          Min = 10,
          Max = 200,
          Rounding = 0,
          Callback = function(v)
              flySpeed = v
              if flying then
                  print("🔄 Fly speed diubah menjadi: " .. v)
              end
          end
      })

      -- Info label
      Group:AddLabel("Karakter akan terbang mengikuti arah kamera")

      -- Hook untuk memastikan flying tetap aktif setelah respawn
      if not getgenv().FlyingHooked then
          getgenv().FlyingHooked = true
          
          -- Periodic check untuk memastikan flying tetap aktif
          coroutine.wrap(function()
              while wait(2) do
                  if vars.Flying and not flying then
                      -- Jika setting flying aktif tapi tidak terbang, restart flying
                      if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                          character = player.Character
                          humanoid = character:FindFirstChild("Humanoid")
                          rootPart = character:FindFirstChild("HumanoidRootPart")
                          
                          if humanoid and rootPart then
                              startFlying()
                              print("🔄 Flying system di-restart setelah respawn")
                          end
                      end
                  end
              end
          end)()
          
          print("✅ [Flying] Sistem periodic check aktif.")
      end

      -- Auto start jika sebelumnya aktif
      if vars.Flying then
          wait(1) -- Tunggu karakter load
          startFlying()
      end

      print("✅ [Flying] Sistem aktif. Gunakan toggle untuk mengaktifkan/mematikan flying.")
      print("📋 Fitur:")
      print("   - Terbang otomatis mengikuti arah kamera")
      print("   - Adjustable speed")
      print("   - Auto restart setelah respawn")
  end
}