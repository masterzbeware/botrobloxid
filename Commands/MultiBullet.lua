return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local CombatTab = tab or Tabs.Combat

      if not CombatTab then
          warn("[MultiBullet] Tab Combat tidak ditemukan!")
          return
      end

      local Group = CombatTab:AddLeftGroupbox("Multi Bullet (M855)")

      vars.MultiBullet = vars.MultiBullet or false
      vars.BulletCount = vars.BulletCount or 1

      Group:AddToggle("ToggleMultiBullet", {
          Text = "Multi Bullet",
          Default = vars.MultiBullet,
          Callback = function(v)
              vars.MultiBullet = v
              applyMultiBullet()
          end
      })

      Group:AddSlider("BulletCount", {
          Text = "Bullet Count",
          Default = vars.BulletCount,
          Min = 1,
          Max = 10,
          Rounding = 0,
          Callback = function(v)
              vars.BulletCount = v
              if vars.MultiBullet then
                  applyMultiBullet()
              end
          end
      })

      local function applyMultiBullet()
          local success, Calibers = pcall(function()
              return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
          end)
          
          if success and Calibers then
              local bulletCount = vars.MultiBullet and vars.BulletCount or 1
              
              -- Coba beberapa struktur yang mungkin
              if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                  Calibers.v1.intermediaterifle_556x45mmNATO_M855["Bullets"] = bulletCount
                  print("✅ Bullets M855 diubah menjadi " .. bulletCount .. " (struktur v1)")
              elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                  Calibers.intermediaterifle_556x45mmNATO_M855["Bullets"] = bulletCount
                  print("✅ Bullets M855 diubah menjadi " .. bulletCount .. " (struktur langsung)")
              else
                  -- Cari tabel M855 secara manual
                  for name, data in pairs(Calibers) do
                      if string.find(tostring(name), "556x45mmNATO_M855") then
                          data["Bullets"] = bulletCount
                          print("✅ Bullets " .. tostring(name) .. " diubah menjadi " .. bulletCount)
                          break
                      end
                  end
              end
          else
              warn("❌ Gagal memuat module Calibers")
          end
      end

      -- Hook untuk memastikan perubahan tetap berlaku
      if not getgenv().MultiBulletHooked then
          getgenv().MultiBulletHooked = true
          
          -- Periodic check untuk memastikan Bullets tetap sesuai setting
          coroutine.wrap(function()
              while wait(5) do
                  if vars.MultiBullet then
                      local success, Calibers = pcall(function()
                          return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                      end)
                      
                      if success and Calibers then
                          local expectedBullets = vars.BulletCount
                          
                          if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                              if Calibers.v1.intermediaterifle_556x45mmNATO_M855["Bullets"] ~= expectedBullets then
                                  Calibers.v1.intermediaterifle_556x45mmNATO_M855["Bullets"] = expectedBullets
                                  print("🔄 Bullets diperbaiki menjadi " .. expectedBullets)
                              end
                          elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                              if Calibers.intermediaterifle_556x45mmNATO_M855["Bullets"] ~= expectedBullets then
                                  Calibers.intermediaterifle_556x45mmNATO_M855["Bullets"] = expectedBullets
                                  print("🔄 Bullets diperbaiki menjadi " .. expectedBullets)
                              end
                          end
                      end
                  end
              end
          end)()
          
          print("✅ [Multi Bullet] Sistem periodic check aktif.")
      end

      -- Apply setting awal
      applyMultiBullet()

      print("✅ [Multi Bullet] Sistem aktif. Gunakan toggle dan slider untuk mengatur jumlah bullets.")
  end
}