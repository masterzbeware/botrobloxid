-- AutoHeadshotAI.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      tab = tab or Tabs.Combat

      if not tab then return end

      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local Send = ReplicatedFirst.Actor.BulletServiceMultithread.Send
      local RunService = game:GetService("RunService")
      local Camera = workspace.CurrentCamera

      vars.HeadshotEnabled = vars.HeadshotEnabled or false

      local Group = tab:AddLeftGroupbox("Auto Headshot (AI_Male Only)")

      Group:AddToggle("HeadshotToggle", {
          Text = "Aktifkan Auto Headshot",
          Default = vars.HeadshotEnabled,
          Callback = function(v)
              vars.HeadshotEnabled = v
              print("[AutoHeadshot] Aktif:", v)
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

      -- Ambil kepala NPC valid
      local function getNPCHeads()
          local heads = {}
          for _, model in ipairs(workspace:GetChildren()) do
              if isValidNPC(model) then
                  local head = model:FindFirstChild("Head")
                  if head then table.insert(heads, head) end
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
                  Ignore = {}, -- kosong agar tembus semua
                  OriginCFrame = CFrame.new(Camera.CFrame.Position),
                  Tracer = "Default",
                  Replicate = true,
                  Local = true,
                  Range = 99999999,
                  Penetration = true
              }
          )
      end

      -- Auto headshot setiap frame
      RunService.RenderStepped:Connect(function()
          if vars.HeadshotEnabled then
              local heads = getNPCHeads()
              for _, head in ipairs(heads) do
                  FireHeadshot(head)
              end
          end
      end)

      print("✅ [AutoHeadshot AI_Male] Siap. Menembak kepala NPC Male dengan child 'AI_' otomatis, tembus tembok.")
  end
}
