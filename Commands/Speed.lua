return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      local VisualTab = tab or Tabs.Visual

      if not VisualTab then
          warn("[Speed] Tab Visual tidak ditemukan!")
          return
      end

      local Group = VisualTab:AddLeftGroupbox("Speed Control")

      vars.SpeedEnabled = vars.SpeedEnabled or false
      vars.SpeedValue = vars.SpeedValue or 16

      local Players = game:GetService("Players")
      local RunService = game:GetService("RunService")
      local LocalPlayer = Players.LocalPlayer
      local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
      local Humanoid = Character:WaitForChild("Humanoid")

      Group:AddToggle("ToggleSpeed", {
          Text = "Aktifkan Speed",
          Default = vars.SpeedEnabled,
          Callback = function(v)
              vars.SpeedEnabled = v
              if not v and Humanoid then Humanoid.WalkSpeed = 16 end
              print("[Speed] Speed", v and "Aktif ✅" or "Nonaktif ❌")
          end
      })

      Group:AddSlider("SpeedSlider", {
          Text = "Atur Kecepatan",
          Default = vars.SpeedValue,
          Min = 16,
          Max = 200,
          Rounding = 0,
          Callback = function(v)
              vars.SpeedValue = v
              if vars.SpeedEnabled and Humanoid then Humanoid.WalkSpeed = v end
              print("[Speed] WalkSpeed diatur ke", v)
          end
      })

      RunService.RenderStepped:Connect(function()
          if vars.SpeedEnabled then
              if not Humanoid or not Humanoid.Parent then
                  Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                  Humanoid = Character:WaitForChild("Humanoid")
              end
              Humanoid.WalkSpeed = vars.SpeedValue
          end
      end)

      print("✅ [Speed] Siap — gunakan toggle untuk aktifkan Speed.")
  end
}
