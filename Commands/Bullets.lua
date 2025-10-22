return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local CombatTab = tab or Tabs.Combat

      if not CombatTab then
          warn("[Custom Bullets] Tab Combat tidak ditemukan!")
          return
      end

      local Group = CombatTab:AddLeftGroupbox("Custom Bullets (M855)")

      vars.BulletsToggle = vars.BulletsToggle or false
      vars.BulletsValue = vars.BulletsValue or 1

      -- Toggle Bullets
      Group:AddToggle("ToggleBullets", {
          Text = "Custom Bullets",
          Default = vars.BulletsToggle,
          Callback = function(v)
              vars.BulletsToggle = v
              if v then
                  -- Terapkan nilai bullets saat diaktifkan
                  applyBulletsValue(vars.BulletsValue)
              else
                  -- Reset ke nilai default saat dimatikan (1)
                  resetBulletsValue()
              end
          end
      })

      -- Slider Bullets
      Group:AddSlider("BulletsSlider", {
          Text = "Bullets Count",
          Default = vars.BulletsValue,
          Min = 1,
          Max = 50,
          Rounding = 0,
          Callback = function(v)
              vars.BulletsValue = v
              -- Jika toggle aktif, langsung terapkan perubahan
              if vars.BulletsToggle then
                  applyBulletsValue(v)
              end
          end
      })

      -- Fungsi untuk menerapkan nilai bullets
      function applyBulletsValue(value)
          local success, Calibers = pcall(function()
              return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
          end)
          
          if success and Calibers then
              -- Coba beberapa struktur yang mungkin
              if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                  Calibers.v1.intermediaterifle_556x45mmNATO_M855["Bullets"] = value
                  print("✅ Bullets M855 diubah menjadi " .. value .. " (struktur v1)")
              elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                  Calibers.intermediaterifle_556x45mmNATO_M855["Bullets"] = value
                  print("✅ Bullets M855 diubah menjadi " .. value .. " (struktur langsung)")
              else
                  -- Cari tabel M855 secara manual
                  for name, data in pairs(Calibers) do
                      if string.find(tostring(name), "556x45mmNATO_M855") then
                          data["Bullets"] = value
                          print("✅ Bullets " .. tostring(name) .. " diubah menjadi " .. value)
                          break
                      end
                  end
              end
          else
              warn("❌ Gagal memuat module Calibers")
          end
      end

      -- Fungsi untuk reset bullets ke nilai default
      function resetBulletsValue()
          local success, Calibers = pcall(function()
              return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
          end)
          
          if success and Calibers then
              -- Reset ke nilai default (1)
              if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                  Calibers.v1.intermediaterifle_556x45mmNATO_M855["Bullets"] = 1
                  print("❌ Bullets M855 dikembalikan ke 1")
              elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                  Calibers.intermediaterifle_556x45mmNATO_M855["Bullets"] = 1
                  print("❌ Bullets M855 dikembalikan ke 1")
              end
          end
      end

      -- Hook untuk memastikan perubahan bullets tetap berlaku
      if not getgenv().BulletsHooked then
          getgenv().BulletsHooked = true
          
          -- Periodic check untuk memastikan nilai bullets tetap sesuai
          coroutine.wrap(function()
              while wait(5) do
                  -- Check Bullets
                  if vars.BulletsToggle then
                      local success, Calibers = pcall(function()
                          return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                      end)
                      
                      if success and Calibers then
                          if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                              if Calibers.v1.intermediaterifle_556x45mmNATO_M855["Bullets"] ~= vars.BulletsValue then
                                  Calibers.v1.intermediaterifle_556x45mmNATO_M855["Bullets"] = vars.BulletsValue
                                  print("🔄 Bullets diperbaiki menjadi " .. vars.BulletsValue)
                              end
                          elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                              if Calibers.intermediaterifle_556x45mmNATO_M855["Bullets"] ~= vars.BulletsValue then
                                  Calibers.intermediaterifle_556x45mmNATO_M855["Bullets"] = vars.BulletsValue
                                  print("🔄 Bullets diperbaiki menjadi " .. vars.BulletsValue)
                              end
                          end
                      end
                  end
              end
          end)()
          
          print("✅ [Custom Bullets] Sistem periodic check aktif.")
      end

      -- Terapkan nilai awal jika toggle sudah aktif
      if vars.BulletsToggle then
          applyBulletsValue(vars.BulletsValue)
      end

      print("✅ [Custom Bullets] Sistem aktif.")
      print("   - Gunakan toggle Custom Bullets untuk mengaktifkan/mematikan")
      print("   - Gunakan slider untuk mengatur jumlah peluru (1-50)")
  end
}