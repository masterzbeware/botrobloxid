-- InstantHeadshot.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      tab = tab or Tabs.Combat

      if not tab then return end

      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local UserInputService = game:GetService("UserInputService")
      local Send = ReplicatedFirst.Actor.BulletServiceMultithread.Send

      vars.HeadshotEnabled = vars.HeadshotEnabled or false
      vars.BurstAmount = vars.BurstAmount or 3

      local Group = tab:AddLeftGroupbox("Instant Headshot (Manual Fire)")

      Group:AddToggle("HeadshotToggle", {
          Text = "Aktifkan Instant Headshot",
          Default = vars.HeadshotEnabled,
          Callback = function(v)
              vars.HeadshotEnabled = v
              print("[InstantHeadshot] Aktif:", v)
          end
      })

      Group:AddSlider("BurstAmount", {
          Text = "Jumlah Peluru per Klik",
          Default = vars.BurstAmount,
          Min = 1,
          Max = 10,
          Rounding = 0,
          Callback = function(v) vars.BurstAmount = v end
      })

      local function getNPCHeads()
          local heads = {}
          for _, model in ipairs(workspace:GetChildren()) do
              if model:IsA("Model") and model.Name == "Male" then
                  local humanoid = model:FindFirstChildOfClass("Humanoid")
                  local head = model:FindFirstChild("Head")
                  if humanoid and humanoid.Health > 0 and head then
                      table.insert(heads, head)
                  end
              end
          end
          return heads
      end

      UserInputService.InputBegan:Connect(function(input, gpe)
          if gpe then return end
          if input.UserInputType == Enum.UserInputType.MouseButton1 and vars.HeadshotEnabled then
              local heads = getNPCHeads()
              for _, head in ipairs(heads) do
                  for i = 1, vars.BurstAmount do
                      Send:Fire(
                          1,
                          "NPC_"..tostring(head.Parent:GetDebugId()),
                          {
                              Velocity = 3110,
                              Caliber = "intermediaterifle_556x45mmNATO_M855",
                              UID = "NPC_"..tostring(head.Parent:GetDebugId()),
                              Ignore = workspace.Male,
                              OriginCFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position),
                              Tracer = "Default",
                              Replicate = true,
                              Local = true,
                              Range = 2100
                          }
                      )
                  end
              end
          end
      end)

      print("✅ [InstantHeadshot] Siap. Klik untuk menembak, semua NPC Male auto kena kepala.")
  end
}
