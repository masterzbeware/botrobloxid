-- ManualWallbang.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      tab = tab or Tabs.Combat
      if not tab then return warn("[ManualWallbang] Tab Combat tidak ditemukan!") end

      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local Send = ReplicatedFirst.Actor.BulletServiceMultithread.Send
      local UserInputService = game:GetService("UserInputService")
      local Camera = workspace.CurrentCamera

      vars.ManualWallbangEnabled = vars.ManualWallbangEnabled or false

      local Group = tab:AddLeftGroupbox("Manual Wallbang")

      Group:AddToggle("ManualWallbangToggle", {
          Text = "Aktifkan Manual Wallbang",
          Default = vars.ManualWallbangEnabled,
          Callback = function(v)
              vars.ManualWallbangEnabled = v
              print("[ManualWallbang] Aktif:", v)
          end
      })

      -- Filter NPC Male dengan child "AI_"
      local function isValidNPC(model)
          if not model:IsA("Model") or model.Name ~= "Male" then return false end
          local humanoid = model:FindFirstChildOfClass("Humanoid")
          if not humanoid or humanoid.Health <= 0 then return false end
          for _, c in ipairs(model:GetChildren()) do
              if string.sub(c.Name,1,3) == "AI_" then
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

      -- Fungsi tembak manual wallbang
      local function FireManualWallbang()
          if not vars.ManualWallbangEnabled then return end
          local originCFrame = Camera.CFrame
          local heads = getNPCHeads()
          for _, head in ipairs(heads) do
              local bulletData = {
                  Velocity = 1e9,         -- peluru super cepat
                  Caliber = "intermediaterifle_556x45mmNATO_M855",
                  UID = "WALL_"..tostring(head:GetDebugId()),
                  Ignore = {},            -- tembus semua
                  OriginCFrame = originCFrame,
                  Tracer = "Default",
                  Replicate = true,
                  Local = true,
                  Range = 1e9,            -- jarak tak terbatas
                  Penetration = true      -- wallbang
              }
              Send:Fire(1, bulletData.UID, bulletData)
          end
      end

      -- Klik mouse kiri untuk tembak
      UserInputService.InputBegan:Connect(function(input, gpe)
          if gpe then return end
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
              FireManualWallbang()
          end
      end)

      print("✅ [ManualWallbang] Siap. Klik mouse untuk menembak kepala NPC dengan wallbang.")
  end
}
