-- Reload.lua
-- Mengatur auto reload & visual indikator reload

return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      _G.BotVars = vars
      local Tabs = vars.Tabs or {}
      tab = tab or Tabs.Combat

      if not tab then
          warn("[Reload] Tab Combat tidak ditemukan!")
          return
      end

      vars.ReloadKey = vars.ReloadKey or Enum.KeyCode.R
      vars.AutoReload = vars.AutoReload or false
      vars.ReloadDelay = vars.ReloadDelay or 1.2
      vars.ShowReloadBar = vars.ShowReloadBar or true
      vars.Reloading = vars.Reloading or false
      vars.ReloadColor = vars.ReloadColor or Color3.fromRGB(0, 255, 0)
      vars.DebugMode = vars.DebugMode or false

      local UserInputService = game:GetService("UserInputService")
      local RunService = game:GetService("RunService")
      local Camera = workspace.CurrentCamera

      local Group = tab:AddRightGroupbox("Reload Controller")

      Group:AddToggle("AutoReload", {
          Text = "Aktifkan Auto Reload",
          Default = vars.AutoReload,
          Callback = function(v)
              vars.AutoReload = v
              print("[Reload]", v and "Auto Reload aktif ✅" or "Auto Reload nonaktif ❌")
          end
      })

      Group:AddSlider("ReloadDelay", {
          Text = "Waktu Reload (detik)",
          Default = vars.ReloadDelay,
          Min = 0.2,
          Max = 3,
          Rounding = 1,
          Callback = function(v)
              vars.ReloadDelay = v
          end
      })

      Group:AddDropdown("ReloadKey", {
          Text = "Tombol Reload",
          Default = tostring(vars.ReloadKey),
          Values = { "R", "E", "Q", "T" },
          Callback = function(value)
              vars.ReloadKey = Enum.KeyCode[value]
          end
      })

      Group:AddToggle("ShowReloadBar", {
          Text = "Tampilkan Reload Bar",
          Default = vars.ShowReloadBar,
          Callback = function(v)
              vars.ShowReloadBar = v
          end
      })

      Group:AddColorPicker("ReloadColor", {
          Text = "Warna Reload Bar",
          Default = vars.ReloadColor,
          Callback = function(v)
              vars.ReloadColor = v
          end
      })

      Group:AddToggle("DebugMode", {
          Text = "Debug Mode",
          Default = vars.DebugMode,
          Callback = function(v)
              vars.DebugMode = v
          end
      })

      local success, Drawing = pcall(function() return Drawing end)
      local drawAvailable = success and typeof(Drawing) == "table"
      local reloadBar

      if drawAvailable and vars.ShowReloadBar then
          pcall(function()
              reloadBar = Drawing.new("Square")
              reloadBar.Visible = false
              reloadBar.Filled = true
              reloadBar.Size = Vector2.new(0, 6)
              reloadBar.Position = Vector2.new(Camera.ViewportSize.X / 2 - 50, Camera.ViewportSize.Y - 60)
              reloadBar.Color = vars.ReloadColor
              reloadBar.Transparency = 0.9
          end)
      end

      local function startReload()
          if vars.Reloading then return end
          vars.Reloading = true
          if vars.DebugMode then print("[Reload] Mulai reload...") end

          if drawAvailable and reloadBar and vars.ShowReloadBar then
              task.spawn(function()
                  local elapsed = 0
                  reloadBar.Visible = true
                  while elapsed < vars.ReloadDelay do
                      elapsed += RunService.RenderStepped:Wait()
                      local pct = math.clamp(elapsed / vars.ReloadDelay, 0, 1)
                      reloadBar.Size = Vector2.new(pct * 100, 6)
                  end
                  reloadBar.Visible = false
              end)
          else
              task.delay(vars.ReloadDelay, function()
                  vars.Reloading = false
              end)
          end

          task.delay(vars.ReloadDelay, function()
              vars.Reloading = false
              if vars.DebugMode then print("[Reload] Selesai reload.") end
          end)
      end

      UserInputService.InputBegan:Connect(function(input, gameProcessed)
          if gameProcessed then return end
          if input.KeyCode == vars.ReloadKey and not vars.Reloading then
              startReload()
          end
      end)

      if vars.AutoReload then
          task.spawn(function()
              while task.wait(0.2) do
                  if vars.AutoReload and not vars.Reloading then
                      startReload()
                  end
              end
          end)
      end

      print("✅ [Reload] Siap digunakan — Controller aktif di tab Combat.")
  end
}
