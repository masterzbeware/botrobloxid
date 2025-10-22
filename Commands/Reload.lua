-- Modules/Reload.lua
return {
  Execute = function(tab)
      _G.BotVars = _G.BotVars or {}
      local vars = _G.BotVars
      vars.Tabs = vars.Tabs or {}

      -- Tunggu sampai Tab Combat tersedia dari WindowTab.lua
      if not vars.Tabs.Combat then
          repeat
              task.wait(0.1)
          until vars.Tabs and vars.Tabs.Combat
      end

      tab = tab or vars.Tabs.Combat
      if not tab then
          warn("[Reload] Tab Combat tidak ditemukan, membatalkan eksekusi.")
          return
      end

      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local Players = game:GetService("Players")
      local RemoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvent")
      local player = Players.LocalPlayer
      local char = player.Character or player.CharacterAdded:Wait()

      if vars.AutoReload == nil then vars.AutoReload = true end
      vars.ReloadDelay = vars.ReloadDelay or 1.8
      vars.Reloading = vars.Reloading or false
      vars.MagCheckInterval = vars.MagCheckInterval or 0.1

      local Group = tab:AddLeftGroupbox("Auto Reload")
      Group:AddToggle("AutoReload", {
          Text = "Aktifkan Auto Reload",
          Default = vars.AutoReload,
          Callback = function(v)
              vars.AutoReload = v
          end
      })

      local function doReload()
          if vars.Reloading then return end
          vars.Reloading = true
          RemoteEvent:FireServer("ActionActor", "b6ca2d2d-dc75-4987-b8b8-085a9a89539c", 0, "Reload", false)
          task.delay(vars.ReloadDelay, function()
              RemoteEvent:FireServer("ActionActor", "cd6c81a7-3f9a-4288-baaa-eb9514dce761", 0, "Reloaded", {
                  Capacity = 30,
                  Name = "M4A1_Stanag_Default",
                  Caliber = "intermediaterifle_556x45mmNATO_M855",
                  UID = "07a4535b-fc24-48c0-9dc4-94d68dddd0df"
              })
              vars.Reloading = false
          end)
      end

      task.spawn(function()
          while task.wait(vars.MagCheckInterval) do
              if vars.AutoReload and not vars.Reloading then
                  local weapon = char:FindFirstChildWhichIsA("Tool")
                  if weapon and weapon:FindFirstChild("Ammo") then
                      if weapon.Ammo.Value <= 0 then
                          doReload()
                      end
                  end
              end
          end
      end)

      print("[Reload] Auto reload siap digunakan (Combat Tab).")
  end
}
