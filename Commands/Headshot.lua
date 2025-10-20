-- Headshot.lua
-- 💀 Full Auto Headshot: Kamera + tembakan otomatis ke kepala NPC (Male)

return {
  Execute = function()
      local vars = _G.BotVars
      local Window = vars.MainWindow
      local Camera = workspace.CurrentCamera
      local RunService = game:GetService("RunService")
      local ReplicatedFirst = game:GetService("ReplicatedFirst")

      -- 🔫 Cari event tembakan
      local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent", true)
      if not BulletEvent then
          warn("[Headshot] Tidak menemukan BulletEvent di ReplicatedFirst!")
          return
      end

      -- 🧭 UI Tab
      local Tabs = {
          Headshot = Window:AddTab("HEADSHOT", "target"),
      }
      local Group = Tabs.Headshot:AddLeftGroupbox("Headshot Control")

      Group:AddToggle("EnableAutoHeadshot", {
          Text = "Aktifkan Auto Headshot",
          Default = false,
          Callback = function(Value)
              vars.ToggleAutoHeadshot = Value
              print(Value and "[Headshot] Auto Headshot Aktif ✅" or "[Headshot] Nonaktif ❌")
          end
      })

      -- 🔍 Cari kepala NPC terdekat
      local function getNearestHead()
          local nearest, dist = nil, math.huge
          for _, model in ipairs(workspace:GetChildren()) do
              if model:IsA("Model") and model.Name == "Male" and model:FindFirstChildOfClass("Humanoid") then
                  for _, c in ipairs(model:GetChildren()) do
                      if string.sub(c.Name, 1, 3) == "AI_" then
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
              end
          end
          return nearest
      end

      -- 🎯 Auto headshot loop
      task.spawn(function()
          while true do
              task.wait(0.05) -- delay kecil, auto fire cepat
              if not vars.ToggleAutoHeadshot then continue end
              local head = getNearestHead()
              if not head then continue end

              -- Kamera langsung ke kepala
              Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, head.Position)

              -- Tembak otomatis
              local origin = Camera.CFrame.Position
              local targetPos = head.Position
              local direction = (targetPos - origin).Unit

              local args = {nil, origin, targetPos, nil, direction, nil, nil, true}
              BulletEvent:Fire(unpack(args))
          end
      end)

      print("✅ Headshot.lua aktif — Auto headshot penuh ke NPC (Male AI_) 🎯")
  end
}
