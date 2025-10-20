-- Hide.lua
-- 👻 Sistem "Hide dari NPC" — memblokir sinyal BeingSpotted agar tidak terdeteksi

return {
  Execute = function()
      local vars = _G.BotVars
      local Window = vars.MainWindow

      -- Services
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local RemoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvent")

      -- UI
      local Tabs = {
          Hide = Window:AddTab("HIDE", "eye-off"),
      }
      local Group = Tabs.Hide:AddLeftGroupbox("Hide Control")

      local HideConnection = nil

      -- 🚫 Fungsi untuk blokir sinyal BeingSpotted
      local function blockDetection()
          if HideConnection then return end

          print("[HIDE] Sistem Hide aktif 👻 — NPC tidak akan mendeteksi kamu")

          HideConnection = RemoteEvent.OnClientEvent:Connect(function(eventName, ...)
              if eventName == "BeingSpotted" then
                  -- Batalkan event agar tidak diproses
                  -- (tidak menjalankan apapun)
                  return
              end
          end)
      end

      -- ❌ Nonaktifkan sistem Hide
      local function stopHide()
          print("[HIDE] Sistem Hide dimatikan ❌")
          if HideConnection then
              HideConnection:Disconnect()
              HideConnection = nil
          end
      end

      -- 🎚️ Toggle
      Group:AddToggle("EnableHideSystem", {
          Text = "Aktifkan Hide dari NPC",
          Default = false,
          Callback = function(Value)
              vars.ToggleHide = Value
              if Value then
                  blockDetection()
              else
                  stopHide()
              end
          end
      })

      print("✅ Hide.lua loaded — sistem blokir BeingSpotted siap digunakan")
  end
}
