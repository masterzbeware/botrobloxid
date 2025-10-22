-- onehit.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local CombatTab = tab or Tabs.Combat

      if not CombatTab then
          warn("[One Hit Kill] Tab Combat tidak ditemukan!")
          return
      end

      local Group = CombatTab:AddLeftGroupbox("One Hit Kill (M855)")

      vars.OneHitKill = vars.OneHitKill or false

      Group:AddToggle("ToggleOneHitKill", {
          Text = "One Hit Kill (9999 Damage)",
          Default = vars.OneHitKill,
          Callback = function(v)
              vars.OneHitKill = v
              if v then
                  -- Ubah semua damage menjadi 9999 saat diaktifkan
                  local success, Calibers = pcall(function()
                      return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                  end)
                  
                  if success and Calibers then
                      -- Coba beberapa struktur yang mungkin
                      if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                          local ammo = Calibers.v1.intermediaterifle_556x45mmNATO_M855
                          -- Buat damage table dengan 9999 untuk semua jarak dan bagian tubuh
                          local godDamage = {}
                          for i = 1, 21 do
                              godDamage[i] = 9999
                          end
                          
                          ammo["Damage"] = {
                              ["Head"] = godDamage,
                              ["Torso"] = godDamage,
                              ["Arms"] = godDamage,
                              ["Legs"] = godDamage
                          }
                          print("✅ One Hit Kill activated! All damage = 9999 (struktur v1)")
                      elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                          local ammo = Calibers.intermediaterifle_556x45mmNATO_M855
                          -- Buat damage table dengan 9999 untuk semua jarak dan bagian tubuh
                          local godDamage = {}
                          for i = 1, 21 do
                              godDamage[i] = 9999
                          end
                          
                          ammo["Damage"] = {
                              ["Head"] = godDamage,
                              ["Torso"] = godDamage,
                              ["Arms"] = godDamage,
                              ["Legs"] = godDamage
                          }
                          print("✅ One Hit Kill activated! All damage = 9999 (struktur langsung)")
                      else
                          -- Cari tabel M855 secara manual
                          for name, data in pairs(Calibers) do
                              if string.find(tostring(name), "556x45mmNATO_M855") then
                                  local godDamage = {}
                                  for i = 1, 21 do
                                      godDamage[i] = 9999
                                  end
                                  
                                  data["Damage"] = {
                                      ["Head"] = godDamage,
                                      ["Torso"] = godDamage,
                                      ["Arms"] = godDamage,
                                      ["Legs"] = godDamage
                                  }
                                  print("✅ One Hit Kill " .. tostring(name) .. " activated! All damage = 9999")
                                  break
                              end
                          end
                      end
                  else
                      warn("❌ Gagal memuat module Calibers")
                  end
              else
                  -- Reset ke nilai default saat dimatikan
                  local success, Calibers = pcall(function()
                      return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                  end)
                  
                  if success and Calibers then
                      -- Reset ke damage normal
                      local normalDamage = {
                          ["Head"] = {106.62, 105.6, 104.6, 103.5, 102.5, 101.5, 100.5, 99.4, 98.4, 97.4, 96.3, 95.3, 94.3, 93.3, 79.97, 66.64, 53.31, 39.99, 26.66, 13.33, 0},
                          ["Torso"] = {73.17, 71.9, 70.7, 69.4, 52.6, 48.7, 48.3, 47.8, 47.3, 46.9, 46.4, 45.9, 45.5, 45, 38.57, 32.14, 25.71, 19.29, 12.86, 6.43, 0},
                          ["Arms"] = {21, 20.6, 20.2, 19.7, 19.3, 18.9, 18.5, 18, 17.6, 17.2, 16.7, 16.3, 15.9, 15.5, 13.29, 11.07, 8.86, 6.64, 4.43, 2.21, 0},
                          ["Legs"] = {24.4, 24, 23.6, 23.1, 22.7, 22.3, 21.8, 21.4, 20.9, 20.5, 20.1, 19.6, 19.2, 18.8, 16.11, 13.43, 10.74, 8.06, 5.37, 2.69, 0}
                      }
                      
                      if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                          Calibers.v1.intermediaterifle_556x45mmNATO_M855["Damage"] = normalDamage
                          print("❌ One Hit Kill deactivated! Damage kembali normal (struktur v1)")
                      elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                          Calibers.intermediaterifle_556x45mmNATO_M855["Damage"] = normalDamage
                          print("❌ One Hit Kill deactivated! Damage kembali normal (struktur langsung)")
                      end
                  end
              end
          end
      })

      -- Hook untuk memastikan perubahan tetap berlaku
      if not getgenv().OneHitKillHooked then
          getgenv().OneHitKillHooked = true
          
          -- Periodic check untuk memastikan damage tetap 9999
          coroutine.wrap(function()
              while wait(5) do
                  if vars.OneHitKill then
                      local success, Calibers = pcall(function()
                          return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                      end)
                      
                      if success and Calibers then
                          local godDamage = {}
                          for i = 1, 21 do
                              godDamage[i] = 9999
                          end
                          
                          local expectedDamage = {
                              ["Head"] = godDamage,
                              ["Torso"] = godDamage,
                              ["Arms"] = godDamage,
                              ["Legs"] = godDamage
                          }
                          
                          if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                              local currentDamage = Calibers.v1.intermediaterifle_556x45mmNATO_M855["Damage"]
                              if currentDamage and currentDamage["Head"] and currentDamage["Head"][1] ~= 9999 then
                                  Calibers.v1.intermediaterifle_556x45mmNATO_M855["Damage"] = expectedDamage
                                  print("🔄 One Hit Kill damage diperbaiki menjadi 9999")
                              end
                          elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                              local currentDamage = Calibers.intermediaterifle_556x45mmNATO_M855["Damage"]
                              if currentDamage and currentDamage["Head"] and currentDamage["Head"][1] ~= 9999 then
                                  Calibers.intermediaterifle_556x45mmNATO_M855["Damage"] = expectedDamage
                                  print("🔄 One Hit Kill damage diperbaiki menjadi 9999")
                              end
                          end
                      end
                  end
              end
          end)()
          
          print("✅ [One Hit Kill] Sistem periodic check aktif.")
      end

      print("✅ [One Hit Kill] Sistem aktif. Gunakan toggle untuk one hit kill (9999 damage).")
  end
}