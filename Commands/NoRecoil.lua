return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local CombatTab = tab or Tabs.Combat

      if not CombatTab then
          warn("[No Recoil] Tab Combat tidak ditemukan!")
          return
      end

      local Group = CombatTab:AddLeftGroupbox("No Recoil (M855)")

      vars.NoRecoil = vars.NoRecoil or false

      Group:AddToggle("ToggleNoRecoil", {
          Text = "No Recoil",
          Default = vars.NoRecoil,
          Callback = function(v)
              vars.NoRecoil = v
              if v then
                  -- Ubah RecoilForce menjadi 0 saat diaktifkan
                  local success, Calibers = pcall(function()
                      return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                  end)
                  
                  if success and Calibers then
                      -- Coba beberapa struktur yang mungkin
                      if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                          Calibers.v1.intermediaterifle_556x45mmNATO_M855["RecoilForce"] = 0
                          print("✅ RecoilForce M855 diubah menjadi 0 (struktur v1)")
                      elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                          Calibers.intermediaterifle_556x45mmNATO_M855["RecoilForce"] = 0
                          print("✅ RecoilForce M855 diubah menjadi 0 (struktur langsung)")
                      else
                          -- Cari tabel M855 secara manual
                          for name, data in pairs(Calibers) do
                              if string.find(tostring(name), "556x45mmNATO_M855") then
                                  data["RecoilForce"] = 0
                                  print("✅ RecoilForce " .. tostring(name) .. " diubah menjadi 0")
                                  break
                              end
                          end
                      end
                  else
                      warn("❌ Gagal memuat module Calibers")
                  end
              else
                  -- Reset ke nilai default saat dimatikan (opsional)
                  local success, Calibers = pcall(function()
                      return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                  end)
                  
                  if success and Calibers then
                      -- Reset ke nilai default (100)
                      if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                          Calibers.v1.intermediaterifle_556x45mmNATO_M855["RecoilForce"] = 100
                          print("❌ RecoilForce M855 dikembalikan ke 100")
                      elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                          Calibers.intermediaterifle_556x45mmNATO_M855["RecoilForce"] = 100
                          print("❌ RecoilForce M855 dikembalikan ke 100")
                      end
                  end
              end
          end
      })

      -- Hook untuk memastikan perubahan tetap berlaku
      if not getgenv().NoRecoilHooked then
          getgenv().NoRecoilHooked = true
          
          -- Periodic check untuk memastikan RecoilForce tetap 0
          coroutine.wrap(function()
              while wait(3) do
                  if vars.NoRecoil then
                      local success, Calibers = pcall(function()
                          return require(game:GetService("ReplicatedStorage").Shared.Configs.Calibers)
                      end)
                      
                      if success and Calibers then
                          if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
                              if Calibers.v1.intermediaterifle_556x45mmNATO_M855["RecoilForce"] ~= 0 then
                                  Calibers.v1.intermediaterifle_556x45mmNATO_M855["RecoilForce"] = 0
                                  print("🔄 RecoilForce diperbaiki menjadi 0")
                              end
                          elseif Calibers.intermediaterifle_556x45mmNATO_M855 then
                              if Calibers.intermediaterifle_556x45mmNATO_M855["RecoilForce"] ~= 0 then
                                  Calibers.intermediaterifle_556x45mmNATO_M855["RecoilForce"] = 0
                                  print("🔄 RecoilForce diperbaiki menjadi 0")
                              end
                          end
                      end
                  end
              end
          end)()
          
          print("✅ [No Recoil] Sistem periodic check aktif.")
      end

      print("✅ [No Recoil] Sistem aktif. Gunakan toggle untuk mengaktifkan/mematikan no recoil.")
  end
}