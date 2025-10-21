return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      tab = tab or Tabs.Combat
      if not tab then return warn("[BurstDamage] Tab Combat tidak ditemukan!") end

      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local Send = ReplicatedFirst.Actor.BulletServiceMultithread.Send

      vars.BurstCount = vars.BurstCount or 3
      vars.BurstDelay = vars.BurstDelay or 0.1

      local Group = tab:AddLeftGroupbox("Burst Damage")
      Group:AddSlider("BurstCountSlider", {
          Text = "Jumlah Peluru per Burst",
          Default = vars.BurstCount,
          Min = 1,
          Max = 100,
          Rounding = 0,
          Callback = function(v) vars.BurstCount = v end
      })

      Group:AddSlider("BurstDelaySlider", {
          Text = "Delay Antar Peluru (detik)",
          Default = vars.BurstDelay,
          Min = 0.05,
          Max = 1,
          Rounding = 2,
          Callback = function(v) vars.BurstDelay = v end
      })

      -- Fungsi untuk memicu burst secara manual
      function vars.FireBurst(originCFrame)
          originCFrame = originCFrame or workspace.CurrentCamera.CFrame
          for i = 1, vars.BurstCount do
              local bulletData = {
                  Velocity = 3110,
                  Caliber = "intermediaterifle_556x45mmNATO_M855",
                  UID = "BURST_"..tostring(i),
                  Ignore = workspace.Male,
                  OriginCFrame = originCFrame,
                  Tracer = "Default",
                  Replicate = true,
                  Local = true,
                  Range = 2100
              }
              Send:Fire(1, bulletData.UID, bulletData)
              task.wait(vars.BurstDelay)
          end
      end

      print("✅ [BurstDamage] Siap — gunakan vars.FireBurst() untuk menembak manual.")
  end
}
