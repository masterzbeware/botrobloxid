-- AIM.lua
-- 🎯 Auto Aim: Mengunci kepala NPC terdekat bernama "Male"

return {
  Execute = function()
      local vars = _G.BotVars
      local Window = vars.MainWindow
      local Camera = workspace.CurrentCamera
      local Players = game:GetService("Players")

      -- 🪶 Buat tab UI
      local Tabs = {
          Aim = Window:AddTab("AIM", "crosshair"),
      }
      local Group = Tabs.Aim:AddLeftGroupbox("AIM Lock Control")

      Group:AddToggle("EnableAIM", {
          Text = "Aktifkan Auto Lock Kepala",
          Default = false,
          Callback = function(Value)
              vars.ToggleAIM = Value
              print(Value and "[AIM] Lock Kepala Aktif ✅" or "[AIM] Lock Kepala Nonaktif ❌")
          end
      })

      -- 🔍 Fungsi cari NPC terdekat
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

      -- 🧭 Update target secara real-time
      game:GetService("RunService").Heartbeat:Connect(function()
          if not vars.ToggleAIM then
              vars.CurrentAimTarget = nil
              return
          end

          local head = getNearestHead()
          if head then
              vars.CurrentAimTarget = head
          end
      end)

      print("✅ AIM.lua aktif — hanya mengunci kepala NPC tanpa mengirim peluru")
  end
}
