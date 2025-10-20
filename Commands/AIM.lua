-- AIM.lua
-- 🔫 Auto Aim Otomatis Lock Kepala NPC (Model bernama "Male")

return {
  Execute = function()
      local vars = _G.BotVars
      local Window = vars.MainWindow
      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local RunService = game:GetService("RunService")
      local Players = game:GetService("Players")
      local Camera = workspace.CurrentCamera
      local LocalPlayer = Players.LocalPlayer

      -- 🔍 BindableEvent peluru (cari otomatis di ReplicatedFirst)
      local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent", true)
      if not BulletEvent then
          warn("[AIM] Tidak menemukan BulletEvent di ReplicatedFirst!")
          return
      end

      -- 🎛️ Buat tab AIM di window utama
      local Tabs = {
          Aim = Window:AddTab("AIM", "crosshair"),
      }

      local Group = Tabs.Aim:AddLeftGroupbox("AIM Control")

      -- 🔘 Toggle AIM Assist
      Group:AddToggle("EnableAIM", {
          Text = "Aktifkan AIM Otomatis (Lock Kepala)",
          Default = false,
          Callback = function(Value)
              vars.ToggleAIM = Value
              print(Value and "[AIM] Aim Otomatis: ON ✅" or "[AIM] Aim Otomatis: OFF ❌")
          end
      })

      -- 🧠 Fungsi mencari NPC terdekat (Model Male)
      local function getNearestHead()
          local nearest, dist = nil, math.huge
          for _, model in ipairs(workspace:GetChildren()) do
              if model:IsA("Model") and model.Name == "Male" and model:FindFirstChildOfClass("Humanoid") then
                  local head = model:FindFirstChild("Head") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
                  if head then
                      local magnitude = (head.Position - Camera.CFrame.Position).Magnitude
                      if magnitude < dist then
                          nearest = head
                          dist = magnitude
                      end
                  end
              end
          end
          return nearest
      end

      -- 🧩 Saat peluru ditembak, arahkan ke kepala NPC terdekat
      if BulletEvent and BulletEvent:IsA("BindableEvent") then
          BulletEvent.Event:Connect(function(...)
              if not vars.ToggleAIM then return end

              local args = {...}
              local target = getNearestHead()
              if target then
                  local targetPos = target.Position + Vector3.new(0, 0.05, 0) -- presisi sedikit di atas kepala
                  local origin = Camera.CFrame.Position
                  local direction = (targetPos - origin).Unit

                  -- Ubah arah & posisi peluru agar mengarah ke kepala
                  args[3] = targetPos
                  args[5] = direction

                  -- Kirim ulang event peluru dengan arah baru
                  BulletEvent:Fire(unpack(args))
                  --print("[AIM] Peluru diarahkan ke kepala NPC:", target.Parent.Name)
              end
          end)
      end

      print("✅ AIM.lua aktif — Aim otomatis lock kepala NPC terdekat tanpa ESP")
  end
}
