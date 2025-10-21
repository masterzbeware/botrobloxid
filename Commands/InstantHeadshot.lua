-- ManualHeadshot.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      tab = tab or Tabs.Combat
      if not tab then return warn("[ManualHeadshot] Tab Combat tidak ditemukan!") end

      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local BulletEvent = ReplicatedFirst:WaitForChild("BulletEvent") -- contoh remote
      local UserInputService = game:GetService("UserInputService")
      local Camera = workspace.CurrentCamera
      local Players = game:GetService("Players")
      local LocalPlayer = Players.LocalPlayer

      vars.ManualHeadshotEnabled = vars.ManualHeadshotEnabled or false

      local Group = tab:AddLeftGroupbox("Manual Headshot")

      Group:AddToggle("ManualHeadshotToggle", {
          Text = "Aktifkan Manual Headshot",
          Default = vars.ManualHeadshotEnabled,
          Callback = function(v)
              vars.ManualHeadshotEnabled = v
              print("[ManualHeadshot] Aktif:", v)
          end
      })

      -- Filter semua NPC valid (punya Humanoid & Head)
      local function isValidNPC(model)
          if not model:IsA("Model") then return false end
          local humanoid = model:FindFirstChildOfClass("Humanoid")
          local head = model:FindFirstChild("Head")
          if humanoid and humanoid.Health > 0 and head then
              return true
          end
          return false
      end

      -- Ambil kepala NPC valid
      local function getNPCHeads()
          local heads = {}
          for _, model in ipairs(workspace:GetChildren()) do
              if isValidNPC(model) then
                  table.insert(heads, model.Head)
              end
          end
          return heads
      end

      -- Fungsi tembak manual headshot dengan instant kill
      local function FireManualHeadshot()
          if not vars.ManualHeadshotEnabled then return end
          local origin = Camera.CFrame.Position
          local heads = getNPCHeads()
          for _, head in ipairs(heads) do
            -- Mengirim damage sangat besar agar langsung membunuh
            BulletEvent:Fire(
                999999, -- damage besar untuk instant kill
                head.Position,
                origin
            )
          end
      end

      -- Klik mouse kiri untuk tembak
      UserInputService.InputBegan:Connect(function(input, gpe)
          if gpe then return end
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
              FireManualHeadshot()
          end
      end)

      print("✅ [ManualHeadshot] Siap. Klik mouse untuk menembak kepala NPC.")
  end
}