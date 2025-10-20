-- AIM.lua
-- Auto Aim: Mengarahkan peluru ke NPC terdekat (Model bernama "Male")

return {
  Execute = function()
      local vars = _G.BotVars
      local Window = vars.MainWindow
      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local RunService = game:GetService("RunService")
      local Players = game:GetService("Players")
      local Camera = workspace.CurrentCamera
      local LocalPlayer = Players.LocalPlayer

      -- BindableEvent tembakan (cocok dengan pattern BulletEvent yang kamu kasih)
      local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent", true)
      if not BulletEvent then
          warn("[AIM] Tidak menemukan BulletEvent di ReplicatedFirst!")
          return
      end

      -- Toggle di UI
      local Tabs = {
          Aim = Window:AddTab("AIM", "crosshair"),
      }

      local Group = Tabs.Aim:AddLeftGroupbox("AIM Control")

      Group:AddToggle("EnableAIM", {
          Text = "Aktifkan AIM Assist",
          Default = false,
          Callback = function(Value)
              vars.ToggleAIM = Value
              print("[AIM] AIM Assist:", Value and "Aktif ✅" or "Nonaktif ❌")
          end
      })

      -- Fungsi mencari NPC terdekat
      local function getNearestNPC()
          local nearest, dist = nil, math.huge
          for _, model in ipairs(workspace:GetChildren()) do
              if model:IsA("Model") and model.Name == "Male" and model:FindFirstChildOfClass("Humanoid") then
                  local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
                  if torso then
                      local magnitude = (torso.Position - Camera.CFrame.Position).Magnitude
                      if magnitude < dist then
                          nearest = torso
                          dist = magnitude
                      end
                  end
              end
          end
          return nearest
      end

      -- Hook event peluru (tembakan)
      if BulletEvent and BulletEvent:IsA("BindableEvent") then
          BulletEvent.Event:Connect(function(...)
              if not vars.ToggleAIM then return end

              local args = {...}
              local nearest = getNearestNPC()
              if nearest then
                  -- Posisi target NPC
                  local targetPos = nearest.Position
                  -- Posisi kamera (arah awal peluru)
                  local origin = Camera.CFrame.Position
                  local direction = (targetPos - origin).Unit

                  -- Override args peluru agar menuju target
                  -- Format umum: BulletEvent:Fire(playerId, pos1, pos2, main, dir, mat, ammo, bool)
                  args[3] = targetPos
                  args[5] = direction

                  -- Kirim ulang peluru dengan arah yang sudah dikoreksi
                  BulletEvent:Fire(unpack(args))
                  --print("[AIM] Peluru diarahkan ke:", nearest.Parent.Name)
              end
          end)
      end

      print("✅ AIM.lua aktif — Auto-aim siap tanpa ESP tambahan")
  end
}
