-- Hide.lua
-- 👻 Sistem "Hide dari NPC" (mencegah deteksi / BeingSpotted)

return {
  Execute = function()
      local vars = _G.BotVars
      local Window = vars.MainWindow

      -- Services
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local RemoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvent")

      -- Tab & UI
      local Tabs = {
          Hide = Window:AddTab("HIDE", "eye-off"),
      }

      local Group = Tabs.Hide:AddLeftGroupbox("Hide Control")

      -- Variabel internal
      local HideConnection = nil
      local RunService = game:GetService("RunService")

      -- 🧠 Fungsi memicu "BeingSpotted" palsu (buat nge-reset status deteksi)
      local function spoofUnspotted()
          firesignal(RemoteEvent.OnClientEvent,
              "BeingSpotted",
              "67420b07-edf1-40be-b859-01b42ea479a2",
              workspace:GetServerTimeNow(),
              tick()
          )
      end

      -- 🕵️ Aktifkan sistem Hide
      local function startHide()
          print("[HIDE] Mode bersembunyi aktif 👻")

          -- Kirim sinyal spoof secara berkala agar NPC tidak melihat kita
          HideConnection = RunService.Heartbeat:Connect(function()
              spoofUnspotted()
          end)
      end

      -- 🚫 Nonaktifkan sistem Hide
      local function stopHide()
          print("[HIDE] Mode bersembunyi dimatikan ❌")
          if HideConnection then
              HideConnection:Disconnect()
              HideConnection = nil
          end
      end

      -- Toggle di UI
      Group:AddToggle("EnableHideSystem", {
          Text = "Aktifkan Hide dari NPC",
          Default = false,
          Callback = function(Value)
              vars.ToggleHide = Value
              if Value then
                  startHide()
              else
                  stopHide()
              end
          end
      })

      print("✅ Hide.lua loaded — siap sembunyi dari NPC")
  end
}
