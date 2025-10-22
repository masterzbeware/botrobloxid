return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local CombatTab = tab or Tabs.Combat

      if not CombatTab then
          warn("[Wallhack Bullet] Tab Combat tidak ditemukan!")
          return
      end

      local Group = CombatTab:AddLeftGroupbox("Wallhack Bullet")

      vars.WallhackBullet = vars.WallhackBullet or false

      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local Players = game:GetService("Players")
      local player = Players.LocalPlayer
      local BulletEvent = ReplicatedFirst:WaitForChild("BulletEvent")
      local Workspace = game:GetService("Workspace")

      Group:AddToggle("ToggleWallhackBullet", {
          Text = "Wallhack Bullet (Through Walls)",
          Default = vars.WallhackBullet,
          Callback = function(v)
              vars.WallhackBullet = v
              
              if v then
                  -- ✅ AKTIFKAN MAGIC BULLET + WALL PENETRATION
                  local success, Calibers = pcall(function()
                      return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                  end)
                  
                  if success and Calibers then
                      if Calibers.intermediaterifle_556x45mmNATO_M855 then
                          local ammo = Calibers.intermediaterifle_556x45mmNATO_M855
                          -- Magic Bullet Properties
                          ammo["Weight"] = 999
                          ammo["BallisticCoeff"] = 999
                          ammo["Spread"] = 0
                          ammo["RecoilForce"] = 0
                          ammo["Drag"] = 0
                          -- Wallhack Properties
                          ammo["Size"] = "50cal"  -- Larger bullet for better penetration
                          ammo["CanBreach"] = true  -- Can break through materials
                          print("✅ Wallhack Bullet activated!")
                      end
                  end
              else
                  -- ❌ NONAKTIFKAN - Reset ke normal
                  local success, Calibers = pcall(function()
                      return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                  end)
                  
                  if success and Calibers then
                      if Calibers.intermediaterifle_556x45mmNATO_M855 then
                          local ammo = Calibers.intermediaterifle_556x45mmNATO_M855
                          ammo["Weight"] = 12
                          ammo["BallisticCoeff"] = 0.151
                          ammo["Spread"] = 1.6
                          ammo["RecoilForce"] = 100
                          ammo["Drag"] = 2298.52
                          ammo["Size"] = "5.56"
                          ammo["CanBreach"] = false
                          print("❌ Wallhack Bullet deactivated!")
                      end
                  end
              end
          end
      })

      -- ✅ WALLHACK + AUTO HEADSHOT HOOK
      local oldFire
      oldFire = hookfunction(BulletEvent.Fire, function(self, ...)
          local args = {...}
          
          if vars.WallhackBullet and #args >= 7 then
              -- Cari musuh terdekat (termasuk yang di balik tembok)
              local closestTarget = nil
              local closestHead = nil
              local closestDistance = math.huge
              
              for _, target in pairs(Players:GetPlayers()) do
                  if target ~= player and target.Character and target.Character:FindFirstChild("Head") then
                      local head = target.Character.Head
                      local humanoid = target.Character:FindFirstChild("Humanoid")
                      
                      -- Cek jika musuh masih alive
                      if humanoid and humanoid.Health > 0 then
                          local distance = (player.Character.Head.Position - head.Position).Magnitude
                          
                          if distance < closestDistance then
                              closestDistance = distance
                              closestTarget = target
                              closestHead = head
                          end
                      end
                  end
              end
              
              if closestHead then
                  -- Modifikasi untuk WALLHACK + AUTO HEADSHOT
                  args[2] = player.Character.Head.Position  -- Origin dari kepala player
                  args[3] = closestHead.Position           -- Impact langsung ke kepala musuh
                  args[4] = closestHead                    -- Hit part = Head
                  args[5] = Vector3.new(0, 1, 0)           -- Normal vector (atas kepala)
                  args[6] = Enum.Material.Plastic          -- Material kepala
                  args[7] = "intermediaterifle_556x45mmNATO_M855"
                  args[8] = true                           -- Hit confirm
                  
                  -- ⚡ FORCE THROUGH WALLS - Skip wall collision check
                  -- Dengan mengatur impact langsung ke kepala musuh, sistem collision dilewati
                  
                  print("🎯 Wallhack Headshot! Distance: " .. math.floor(closestDistance))
              end
          end
          
          return oldFire(self, unpack(args))
      end)

      -- ✅ PERIODIC WALLHACK CHECK
      if not getgenv().WallhackHooked then
          getgenv().WallhackHooked = true
          
          coroutine.wrap(function()
              while wait(3) do
                  if vars.WallhackBullet then
                      -- Pastikan magic bullet properties tetap aktif
                      local success, Calibers = pcall(function()
                          return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                      end)
                      
                      if success and Calibers then
                          if Calibers.intermediaterifle_556x45mmNATO_M855 then
                              local ammo = Calibers.intermediaterifle_556x45mmNATO_M855
                              -- Maintain wallhack properties
                              if ammo["Size"] ~= "50cal" then
                                  ammo["Size"] = "50cal"
                                  print("🔄 Wall penetration maintained")
                              end
                              if ammo["CanBreach"] ~= true then
                                  ammo["CanBreach"] = true
                              end
                          end
                      end
                  end
              end
          end)()
      end

      print("✅ [Wallhack Bullet] Sistem aktif - Tembus tembok + Auto Headshot!")
      print("   - Peluru tembus semua obstacle")
      print("   - Auto target kepala musuh")
      print("   - Work through walls & covers")
  end
}