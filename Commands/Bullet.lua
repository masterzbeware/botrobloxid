-- Bullet.lua
-- 💥 Burst Bullet System (tembakan otomatis ke target AIM.lua)

return {
  Execute = function()
      local vars = _G.BotVars
      local Window = vars.MainWindow
      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local RunService = game:GetService("RunService")
      local Camera = workspace.CurrentCamera

      -- Cari event tembakan
      local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent", true)
      if not BulletEvent then
          warn("[Bullet] Tidak menemukan BulletEvent di ReplicatedFirst!")
          return
      end

      -- 🔘 UI Control
      local Tabs = {
          Bullet = Window:AddTab("BULLET", "zap"),
      }
      local Group = Tabs.Bullet:AddLeftGroupbox("Burst Control")

      Group:AddToggle("EnableBurst", {
          Text = "Aktifkan Burst Bullet",
          Default = false,
          Callback = function(Value)
              vars.ToggleBurst = Value
              print(Value and "[Bullet] Burst aktif ✅" or "[Bullet] Burst nonaktif ❌")
          end
      })

      Group:AddSlider("BurstCount", {
          Text = "Jumlah Peluru per Burst",
          Default = 3,
          Min = 1,
          Max = 10,
          Rounding = 0,
          Callback = function(Value)
              vars.BurstCount = Value
          end
      })

      Group:AddSlider("BurstDelay", {
          Text = "Delay antar peluru (detik)",
          Default = 0.05,
          Min = 0.01,
          Max = 0.3,
          Rounding = 3,
          Callback = function(Value)
              vars.BurstDelay = Value
          end
      })

      -- 🎯 Burst shooting logic
      local function shootBurst()
          if not vars.ToggleBurst then return end
          if not vars.CurrentAimTarget then return end
          if not BulletEvent then return end

          local targetPos = vars.CurrentAimTarget.Position + Vector3.new(0, 0.05, 0)
          local origin = Camera.CFrame.Position
          local direction = (targetPos - origin).Unit

          for i = 1, (vars.BurstCount or 3) do
              -- Format: BulletEvent:Fire(playerId, pos1, pos2, main, dir, mat, ammo, bool)
              local args = {nil, origin, targetPos, nil, direction, nil, nil, true}
              BulletEvent:Fire(unpack(args))
              task.wait(vars.BurstDelay or 0.05)
          end

          print("[Bullet] Burst ke target:", vars.CurrentAimTarget.Parent.Name)
      end

      -- 🔫 Tekan klik kiri untuk menembak burst
      game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
          if gpe then return end
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
              shootBurst()
          end
      end)

      print("✅ Bullet.lua aktif — sistem burst bullet otomatis")
  end
}
