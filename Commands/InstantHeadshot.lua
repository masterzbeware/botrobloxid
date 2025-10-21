-- ManualHeadshot.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      tab = tab or Tabs.Combat

      if not tab then return end

      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local Send = ReplicatedFirst.Actor.BulletServiceMultithread.Send
      local UserInputService = game:GetService("UserInputService")
      local Camera = workspace.CurrentCamera

      vars.HeadshotEnabled = vars.HeadshotEnabled or false
      vars.HeadshotRange = vars.HeadshotRange or 5000

      local Group = tab:AddLeftGroupbox("Manual Headshot (AI_Male)")

      Group:AddToggle("HeadshotToggle", {
          Text = "Aktifkan Manual Headshot",
          Default = vars.HeadshotEnabled,
          Callback = function(v)
              vars.HeadshotEnabled = v
              print("[ManualHeadshot] Aktif:", v)
          end
      })

      Group:AddSlider("HeadshotRangeSlider", {
          Text = "Range Headshot",
          Default = vars.HeadshotRange,
          Min = 100,
          Max = 10000,
          Rounding = 0,
          Callback = function(v)
              vars.HeadshotRange = v
          end
      })

      -- Validasi NPC Male dengan child "AI_"
      local function isValidNPC(model)
          if not model:IsA("Model") or model.Name ~= "Male" then return false end
          local humanoid = model:FindFirstChildOfClass("Humanoid")
          if not humanoid or humanoid.Health <= 0 then return false end
          for _, c in ipairs(model:GetChildren()) do
              if string.sub(c.Name, 1, 3) == "AI_" then
                  return true
              end
          end
          return false
      end

      -- Ambil kepala NPC valid dalam range
      local function getNPCHeads()
          local heads = {}
          local camPos = Camera.CFrame.Position
          for _, model in ipairs(workspace:GetChildren()) do
              if isValidNPC(model) then
                  local head = model:FindFirstChild("Head")
                  if head and (head.Position - camPos).Magnitude <= vars.HeadshotRange then
                      table.insert(heads, head)
                  end
              end
          end
          return heads
      end

      -- Tembak kepala NPC
      local function FireHeadshot(head)
          Send:Fire(
              1,
              "NPC_"..tostring(head.Parent:GetDebugId()),
              {
                  Velocity = 3110,
                  Caliber = "intermediaterifle_556x45mmNATO_M855",
                  UID = "NPC_"..tostring(head.Parent:GetDebugId()),
                  Ignore = {}, -- kosong agar menembus semua
                  OriginCFrame = CFrame.new(Camera.CFrame.Position),
                  Tracer = "Default",
                  Replicate = true,
                  Local = true,
                  Range = vars.HeadshotRange,
                  Penetration = true
              }
          )
      end

      -- Manual fire: tembak saat klik mouse kiri
      UserInputService.InputBegan:Connect(function(input, gpe)
          if gpe then return end
          if input.UserInputType == Enum.UserInputType.MouseButton1 and vars.HeadshotEnabled then
              local heads = getNPCHeads()
              for _, head in ipairs(heads) do
                  FireHeadshot(head)
              end
          end
      end)

      print("✅ [ManualHeadshot] Siap. Klik mouse untuk menembak kepala NPC Male dengan 'AI_'.")
  end
}
