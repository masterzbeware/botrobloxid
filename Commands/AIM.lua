-- AIM.lua
-- Sistem Auto Aim Otomatis (nyala/mati via toggle di window utama dari Bot.lua)

return {
  Execute = function()
      local vars = _G.BotVars
      local Window = vars.MainWindow  -- ✅ pakai window utama dari Bot.lua

      -- Tambahkan tab baru di window utama
      local Tabs = {
          Control = Window:AddTab("Auto Aim", "crosshair"),
      }

      local Group = Tabs.Control:AddLeftGroupbox("Auto Aim Control")

      -- Service & Remote setup
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local RemoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvent")

      -- ✅ Konfigurasi internal
      local RunService = game:GetService("RunService")
      local Players = game:GetService("Players")
      local LocalPlayer = Players.LocalPlayer
      local Camera = workspace.CurrentCamera
      local AimConnection = nil

      -- Data dari hasil SigmaSpy
      local AIM_ACTION_GUID = "05725503-addc-4643-824a-006f3afbd01f"

      -- Fungsi bantu: cari target Male terdekat di layar
      local function getNearestMale()
          local nearestModel = nil
          local shortestDistance = math.huge
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

      local function aimAt(target)
          if not target then return end
          local torso = target:FindFirstChild("UpperTorso") or target:FindFirstChild("HumanoidRootPart")
          if not torso then return end

          -- Arahkan kamera ke target
          local direction = (torso.Position - Camera.CFrame.Position).Unit
          Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + direction)
      end

      -- 🔫 Auto Aim aktif
      local function startAutoAim()
          print("[AIM] Auto Aim aktif 🚀")

          -- Aktifkan mode ADS (Aim Down Sight)
          firesignal(RemoteEvent.OnClientEvent,
              "ActionActor",
              AIM_ACTION_GUID,
              0,
              "ADS",
              true,
              0
          )

          AimConnection = RunService.RenderStepped:Connect(function()
              local target = getNearestMale()
              if target then
                  aimAt(target)
              end
          end)
      end

      -- ❌ Auto Aim nonaktif
      local function stopAutoAim()
          print("[AIM] Auto Aim dimatikan ❌")

          if AimConnection then
              AimConnection:Disconnect()
              AimConnection = nil
          end

          -- Matikan mode ADS
          firesignal(RemoteEvent.OnClientEvent,
              "ActionActor",
              AIM_ACTION_GUID,
              0,
              "ADS",
              false,
              0
          )
      end

      -- ✅ Toggle Auto Aim di UI utama
      Group:AddToggle("EnableAIMSystem", {
          Text = "Aktifkan Auto Aim",
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

      print("✅ AIM.lua loaded — terhubung ke window utama dari Bot.lua")
  end
}
