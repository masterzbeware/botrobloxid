return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local CombatTab = tab or Tabs.Combat

      if not CombatTab then
          warn("[God Damage] Tab Combat tidak ditemukan!")
          return
      end

      local Group = CombatTab:AddLeftGroupbox("Damage")

      vars.GodDamage = vars.GodDamage or false

      local ReplicatedFirst = game:GetService("ReplicatedFirst")

      local BulletService = ReplicatedFirst:FindFirstChild("Actor") and ReplicatedFirst.Actor:FindFirstChild("BulletServiceMultithread")
      local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent")

      Group:AddToggle("ToggleGodDamage", {
          Text = "God Damage (999 Damage)",
          Default = vars.GodDamage,
          Callback = function(v)
              vars.GodDamage = v
              if v then
                  print("✅ [God Damage] Damage diubah menjadi 999 untuk semua jarak!")
              else
                  print("❌ [God Damage] Damage kembali normal.")
              end
          end
      })

      -- Metamethod hook untuk God Damage
      if not getgenv().GodDamageHooked then
          getgenv().GodDamageHooked = true

          local oldNamecall
          oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
              local method = getnamecallmethod()
              local args = {...}

              -- God Damage Modification
              if vars.GodDamage and method == "Fire" and (self == BulletService.Send or self == BulletEvent) then
                  -- Modifikasi damage menjadi 999
                  if typeof(args[3]) == "table" and args[3].Caliber then
                      -- Simpan caliber asli untuk referensi
                      local originalCaliber = args[3].Caliber
                      
                      -- Override damage parameters
                      args[3].GodDamage = true  -- Flag custom
                      args[3].OriginalCaliber = originalCaliber  -- Simpan aslinya
                      
                      -- Modifikasi caliber menjadi custom god damage type
                      if string.find(originalCaliber, "intermediaterifle") or 
                         string.find(originalCaliber, "pistol") or 
                         string.find(originalCaliber, "shotgun") or
                         string.find(originalCaliber, "fullpowerrifle") then
                          args[3].Caliber = "god_damage_mod"
                      end
                  end
              end

              return oldNamecall(self, ...)
          end)

          print("✅ [God Damage] Hook metamethod aktif.")
      end

      -- Hook untuk memodifikasi data amunisi secara global
      if not getgenv().DamageModHooked then
          getgenv().DamageModHooked = true
          
          local oldIndex
          oldIndex = hookmetamethod(game, "__index", function(self, key)
              if vars.GodDamage then
                  -- Cek jika ini adalah tabel amunisi
                  local tableName = tostring(self)
                  if (string.find(tableName, "intermediaterifle") or 
                      string.find(tableName, "pistol") or 
                      string.find(tableName, "shotgun") or
                      string.find(tableName, "fullpowerrifle") or
                      string.find(tableName, "personaldefenseweapon")) and key == "Damage" then
                      
                      -- Return god damage table dengan 999 untuk semua jarak
                      local godDamage = {
                          Head = {999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999},
                          Torso = {999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999},
                          Arms = {999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999},
                          Legs = {999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999, 999}
                      }
                      print("🔫 [God Damage] Damage " .. tableName .. " di-override menjadi 999!")
                      return godDamage
                  end
              end
              return oldIndex(self, key)
          end)
      end

      print("✅ [God Damage] Sistem aktif.")
      print("   - Damage dapat diubah menjadi 999 via toggle")
      print("   - Berfungsi untuk semua jenis senjata")
  end
}