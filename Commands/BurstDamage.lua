-- BurstDamage.lua
-- 💥 Burst Headshot Manual: klik kiri, semua NPC kena burst

return {
  Execute = function()
      local vars = _G.BotVars
      local Window = vars.MainWindow
      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local Camera = workspace.CurrentCamera
      local UserInputService = game:GetService("UserInputService")
      local HttpService = game:GetService("HttpService")

      -- Cari Send remote (Sigma Spy style)
      local ok, Actor = pcall(function() return ReplicatedFirst:WaitForChild("Actor", 2) end)
      if not ok or not Actor then
          warn("[BurstDamage] Actor tidak ditemukan di ReplicatedFirst.")
          return
      end

      local ok2, BulletSvc = pcall(function() return Actor:WaitForChild("BulletServiceMultithread", 2) end)
      if not ok2 or not BulletSvc then
          warn("[BurstDamage] BulletServiceMultithread tidak ditemukan di Actor.")
          return
      end

      local ok3, Send = pcall(function() return BulletSvc:WaitForChild("Send", 2) end)
      if not ok3 or not Send then
          warn("[BurstDamage] Remote 'Send' tidak ditemukan.")
          return
      end

      -- UI
      local Tabs = { Burst = Window:AddTab("BURST", "zap") }
      local Group = Tabs.Burst:AddLeftGroupbox("Burst Headshot Control")

      Group:AddToggle("EnableBurstDamage", {
          Text = "Aktifkan Burst Headshot (Klik Kiri)",
          Default = false,
          Callback = function(Value)
              vars.ToggleBurstDamage = Value
          end
      })

      Group:AddSlider("BurstCount", {
          Text = "Jumlah Peluru per NPC",
          Default = 3,
          Min = 1,
          Max = 10,
          Rounding = 0,
          Callback = function(Value)
              vars.BurstCount = Value
          end
      })

      -- Ambil semua kepala NPC Male AI_
      local function getAllNPCHeads()
          local result = {}
          for _, model in ipairs(workspace:GetDescendants()) do
              if model:IsA("Model") and model.Name == "Male" then
                  for _, c in ipairs(model:GetChildren()) do
                      if string.sub(c.Name,1,3) == "AI_" then
                          local head = model:FindFirstChild("Head")
                          if head then table.insert(result, head) end
                          break
                      end
                  end
              end
          end
          return result
      end

      -- Payload tembakan
      local function makePayload(originCFrame, uid)
          return {
              Velocity = 3110.666858146635,
              Caliber = "intermediaterifle_556x45mmNATO_M855",
              UID = uid,
              Ignore = workspace.Male,
              OriginCFrame = originCFrame,
              Tracer = "Default",
              Replicate = true,
              Local = true,
              Range = 1e9 -- jarak sangat jauh
          }
      end

      -- Fungsi burst headshot
      local function shootBurst()
          if not vars.ToggleBurstDamage then return end
          local heads = getAllNPCHeads()
          if #heads == 0 then return end

          local originCFrame = Camera.CFrame
          local burstCount = vars.BurstCount or 3

          for _, head in ipairs(heads) do
              if head and head.Parent then
                  for i = 1, burstCount do
                      local uid = HttpService:GenerateGUID(false)
                      local payload = makePayload(originCFrame, uid)
                      pcall(function()
                          Send:Fire(1, uid, payload)
                      end)
                  end
              end
          end
      end

      -- Klik kiri untuk tembak burst ke semua kepala NPC
      UserInputService.InputBegan:Connect(function(input, gpe)
          if gpe then return end
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
              shootBurst()
          end
      end)

      print("✅ BurstDamage.lua siap — klik kiri = semua NPC kena headshot burst")
  end
}
