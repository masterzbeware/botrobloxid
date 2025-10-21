-- FastFire_Instant.lua
return {
  Execute = function(tab)
      local vars = _G.BotVars or {}
      local Tabs = vars.Tabs or {}
      tab = tab or Tabs.Combat
      if not tab then return warn("[FastFire] Tab Combat tidak ditemukan!") end

      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local Send = ReplicatedFirst.Actor.BulletServiceMultithread.Send
      local UserInputService = game:GetService("UserInputService")
      local Camera = workspace.CurrentCamera

      vars.FastFireEnabled = vars.FastFireEnabled or false
      local BULLET_COUNT = 5      -- jumlah peluru per klik
      local BULLET_DELAY = 0.02   -- delay antar peluru

      local Group = tab:AddLeftGroupbox("Fast Fire Instant")

      Group:AddToggle("FastFireToggle", {
          Text = "Aktifkan Fast Fire",
          Default = vars.FastFireEnabled,
          Callback = function(v)
              vars.FastFireEnabled = v
              print("[FastFire] Fast Fire", v and "Aktif ✅" or "Nonaktif ❌")
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

      -- Fungsi tembak burst cepat
      local function FireFast()
          if not vars.FastFireEnabled then return end
          local originCFrame = Camera.CFrame
          local heads = getNPCHeads()
          for _, head in ipairs(heads) do
              for i = 1, BULLET_COUNT do
                  local bulletData = {
                      Velocity = 1e9,  -- peluru super cepat
                      Caliber = "intermediaterifle_556x45mmNATO_M855",
                      UID = "FAST_"..tostring(i).."_"..tostring(head:GetDebugId()),
                      Ignore = {},  -- tembus semua
                      OriginCFrame = originCFrame,
                      Tracer = "Default",
                      Replicate = true,
                      Local = true,
                      Range = 1e9,   -- jarak tak terbatas
                      Penetration = true
                  }
                  Send:Fire(1, bulletData.UID, bulletData)
                  task.wait(BULLET_DELAY)
              end
          end
      end

      -- Klik mouse kiri untuk tembak
      UserInputService.InputBegan:Connect(function(input, gpe)
          if gpe then return end
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
              FireFast()
          end
      end)

      print("✅ [FastFire] Siap. Klik mouse untuk menembak burst cepat dengan velocity & range tinggi.")
  end
}
