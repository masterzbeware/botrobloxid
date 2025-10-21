-- InstantWallbang.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      tab = tab or Tabs.Combat
      if not tab then return warn("[InstantWallbang] Tab Combat tidak ditemukan!") end

      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local Send = ReplicatedFirst.Actor.BulletServiceMultithread.Send
      local Camera = workspace.CurrentCamera

      vars.InstantWallbangEnabled = vars.InstantWallbangEnabled or false

      local Group = tab:AddLeftGroupbox("Instant Wallbang")

      Group:AddToggle("InstantWallbangToggle", {
          Text = "Aktifkan Instant Wallbang",
          Default = vars.InstantWallbangEnabled,
          Callback = function(v)
              vars.InstantWallbangEnabled = v
              print("[InstantWallbang] Aktif:", v)
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

      -- Fungsi instant wallbang
      local function FireInstantWallbang()
          if not vars.InstantWallbangEnabled then return end
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

      -- Loop RenderStepped otomatis tembak semua kepala NPC valid
      game:GetService("RunService").RenderStepped:Connect(function()
          if vars.InstantWallbangEnabled then
              FireInstantWallbang()
          end
      end)

      print("✅ [InstantWallbang] Siap. Semua kepala NPC valid akan terkena peluru tembus tembok secara otomatis.")
  end
}
