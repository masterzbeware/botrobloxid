return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local CombatTab = tab or Tabs.Combat

      if not CombatTab then
          warn("[HighDamage] Tab Combat tidak ditemukan!")
          return
      end

      local Group = CombatTab:AddLeftGroupbox("High Damage Modifier")

      vars.HighDamage = vars.HighDamage or false

      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      
      -- Cari module Calibers
      local Calibers
      local success, err = pcall(function()
          Calibers = require(ReplicatedStorage.Shared.Configs.Calibers)
      end)

      if not success or not Calibers then
          warn("[HighDamage] Tidak bisa menemukan module Calibers!")
          return
      end

      -- Store original values
      local originalValues = {}

      local function backupOriginalValues()
          if Calibers.v1 and Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
              local ammoData = Calibers.v1.intermediaterifle_556x45mmNATO_M855
              
              originalValues.Damage = {
                  Head = table.clone(ammoData.Damage.Head),
                  Torso = table.clone(ammoData.Damage.Torso),
                  Arms = table.clone(ammoData.Damage.Arms),
                  Legs = table.clone(ammoData.Damage.Legs)
              }
              originalValues.Velocity = ammoData.Velocity
              originalValues.Dropoff = table.clone(ammoData.Dropoff)
          end
      end

      local function applyHighDamage()
          if not Calibers.v1 or not Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
              warn("[HighDamage] Ammo data tidak ditemukan!")
              return
          end

          local ammoData = Calibers.v1.intermediaterifle_556x45mmNATO_M855
          
          -- Ubah Velocity menjadi konstan 1000
          ammoData.Velocity = function(arg1)
              return 1000
          end

          -- Ubah Dropoff
          ammoData.Dropoff = {
              0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000,
              10000, 11000, 12000, 13000, 14000, 15000, 16000, 17000, 18000, 19000, 20000
          }

          -- High Damage values
          local highHeadDamage = 500
          local highTorsoDamage = 300
          local highArmsDamage = 150
          local highLegsDamage = 200

          -- Apply high damage ke semua range
          for i = 1, 21 do
              ammoData.Damage.Head[i] = highHeadDamage
              ammoData.Damage.Torso[i] = highTorsoDamage
              ammoData.Damage.Arms[i] = highArmsDamage
              ammoData.Damage.Legs[i] = highLegsDamage
          end

          print("✅ High Damage Aktif - Velocity 1000, Damage Maksimal!")
      end

      local function restoreOriginalDamage()
          if not originalValues.Damage or not Calibers.v1 or not Calibers.v1.intermediaterifle_556x45mmNATO_M855 then
              return
          end

          local ammoData = Calibers.v1.intermediaterifle_556x45mmNATO_M855
          
          ammoData.Damage.Head = originalValues.Damage.Head
          ammoData.Damage.Torso = originalValues.Damage.Torso
          ammoData.Damage.Arms = originalValues.Damage.Arms
          ammoData.Damage.Legs = originalValues.Damage.Legs
          ammoData.Velocity = originalValues.Velocity
          ammoData.Dropoff = originalValues.Dropoff

          print("❌ High Damage Nonaktif")
      end

      -- Backup original values sekali di awal
      backupOriginalValues()

      -- Tombol tunggal
      Group:AddToggle("ToggleHighDamage", {
          Text = "High Damage",
          Default = vars.HighDamage,
          Callback = function(v)
              vars.HighDamage = v
              
              if v then
                  applyHighDamage()
              else
                  restoreOriginalDamage()
              end
          end
      })

      print("✅ [HighDamage] Sistem siap! Gunakan toggle untuk aktif/nonaktif.")
  end
}