-- AIM.lua
-- Sistem Auto Aim + Auto Bullet Direction ke NPC (integrasi dengan window utama Bot.lua)

return {
  Execute = function()
      local vars = _G.BotVars
      local Window = vars.MainWindow -- 🔗 Ambil dari Bot.lua

      local Tabs = {
          AIM = Window:AddTab("AIM", "crosshair"),
      }

      local Group = Tabs.AIM:AddLeftGroupbox("Auto Aim & Bullet Assist")

      -- Services
      local Players = game:GetService("Players")
      local RunService = game:GetService("RunService")
      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local Camera = workspace.CurrentCamera
      local LocalPlayer = Players.LocalPlayer

      -- Remote
      local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent")
      local Send = ReplicatedFirst:FindFirstChild("Actor")
          and ReplicatedFirst.Actor:FindFirstChild("BulletServiceMultithread")
          and ReplicatedFirst.Actor.BulletServiceMultithread:FindFirstChild("Send")

      local ActiveAim = false
      local AimConnection, BulletHook

      ---------------------------------------------------------------------
      -- 🔍 Cari NPC (Model “Male”) terdekat di depan kamera
      ---------------------------------------------------------------------
      local function getNearestMale()
          local nearestModel, shortestDistance = nil, math.huge
          for _, obj in ipairs(workspace:GetDescendants()) do
              if obj:IsA("Model") and obj.Name == "Male" and obj:FindFirstChildOfClass("Humanoid") then
                  local torso = obj:FindFirstChild("UpperTorso") or obj:FindFirstChild("HumanoidRootPart")
                  if torso then
                      local screenPos, onScreen = Camera:WorldToViewportPoint(torso.Position)
                      if onScreen then
                          local dist = (Vector2.new(screenPos.X, screenPos.Y) - (Camera.ViewportSize / 2)).Magnitude
                          if dist < shortestDistance then
                              shortestDistance = dist
                              nearestModel = obj
                          end
                      end
                  end
              end
          end
          return nearestModel
      end

      ---------------------------------------------------------------------
      -- 🎯 Arahkan kamera ke NPC
      ---------------------------------------------------------------------
      local function aimAt(target)
          if not target then return end
          local torso = target:FindFirstChild("UpperTorso") or target:FindFirstChild("HumanoidRootPart")
          if not torso then return end
          local dir = (torso.Position - Camera.CFrame.Position).Unit
          Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + dir)
      end

      ---------------------------------------------------------------------
      -- 💥 Hook peluru agar mengarah ke NPC saat ditembak
      ---------------------------------------------------------------------
      local function hookBulletEvent()
          if not BulletEvent then return end
          if BulletHook then BulletHook:Disconnect() end

          BulletHook = BulletEvent.Event:Connect(function(...)
              if not ActiveAim then return end

              local target = getNearestMale()
              if not target then return end
              local torso = target:FindFirstChild("UpperTorso") or target:FindFirstChild("HumanoidRootPart")
              if not torso then return end

              -- Override arah peluru ke target
              local startPos = Camera.CFrame.Position
              local direction = (torso.Position - startPos).Unit

              -- Panggil ulang BulletEvent dengan arah baru
              BulletEvent:Fire(
                  2,
                  startPos,
                  torso.Position,
                  workspace,
                  direction,
                  Enum.Material.Rock,
                  "intermediaterifle_556x45mmNATO_M855",
                  true
              )

              -- Batalkan tembakan asli
              return nil
          end)
      end

      ---------------------------------------------------------------------
      -- 🚀 Aktifkan Auto Aim
      ---------------------------------------------------------------------
      local function startAutoAim()
          print("[AIM] Auto Aim + Bullet Assist aktif 🚀")
          ActiveAim = true

          -- Auto arahkan kamera setiap frame
          AimConnection = RunService.RenderStepped:Connect(function()
              local target = getNearestMale()
              if target then
                  aimAt(target)
              end
          end)

          -- Hook arah peluru
          hookBulletEvent()
      end

      ---------------------------------------------------------------------
      -- ❌ Matikan Auto Aim
      ---------------------------------------------------------------------
      local function stopAutoAim()
          print("[AIM] Auto Aim dimatikan ❌")
          ActiveAim = false

          if AimConnection then
              AimConnection:Disconnect()
              AimConnection = nil
          end
          if BulletHook then
              BulletHook:Disconnect()
              BulletHook = nil
          end
      end

      ---------------------------------------------------------------------
      -- 🧩 UI Toggle
      ---------------------------------------------------------------------
      Group:AddToggle("EnableAIMSystem", {
          Text = "Aktifkan Auto Aim & Bullet Assist",
          Default = false,
          Callback = function(Value)
              vars.ToggleAim = Value
              if Value then
                  startAutoAim()
              else
                  stopAutoAim()
              end
          end
      })

      print("✅ AIM.lua loaded — Auto Aim + Bullet Assist aktif via toggle")
  end
}
