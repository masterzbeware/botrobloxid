-- HeadshotAuto.lua
-- 🎯 Auto Headshot ke NPC Male AI_ menggunakan BulletServiceMultithread.Send (ringan + draggable range)

return {
  Execute = function()
      local vars = _G.BotVars
      local Window = vars.MainWindow
      local Camera = workspace.CurrentCamera
      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local UserInputService = game:GetService("UserInputService")
      local HttpService = game:GetService("HttpService")
      local RunService = game:GetService("RunService")

      -- Cari Send remote
      local Actor = ReplicatedFirst:WaitForChild("Actor", 2)
      local BulletSvc = Actor:WaitForChild("BulletServiceMultithread", 2)
      local Send = BulletSvc:WaitForChild("Send", 2)

      -- UI
      local Tabs = { Headshot = Window:AddTab("HEADSHOT", "target") }
      local Group = Tabs.Headshot:AddLeftGroupbox("Headshot Control")

      -- Toggle headshot
      Group:AddToggle("EnableAutoHeadshot", {
          Text = "Aktifkan Headshot",
          Default = false,
          Callback = function(Value)
              vars.ToggleAutoHeadshot = Value
              print(Value and "[Headshot] Aktif ✅" or "[Headshot] Nonaktif ❌")
          end
      })

      -- Draggable slider untuk jarak tembak
      Group:AddSlider("HeadshotRange", {
          Text = "Jarak Headshot",
          Default = 500, -- default 500 studs
          Min = 50,
          Max = 2000,
          Rounding = 0,
          Callback = function(Value)
              vars.HeadshotRange = Value
          end
      })

      -- Cari semua kepala NPC Male AI_ dalam range
      local function getHeadsInRange()
          local heads = {}
          local range = vars.HeadshotRange or 500
          for _, model in ipairs(workspace:GetDescendants()) do
              if model:IsA("Model") and model.Name == "Male" then
                  for _, c in ipairs(model:GetChildren()) do
                      if string.sub(c.Name,1,3) == "AI_" then
                          local head = model:FindFirstChild("Head")
                          if head and (head.Position - Camera.CFrame.Position).Magnitude <= range then
                              table.insert(heads, head)
                          end
                          break
                      end
                  end
              end
          end
          return heads
      end

      -- Payload Sigma Spy style
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
              Range = 1e9,
          }
      end

      -- Fungsi tembak kepala NPC
      local function shootHeads()
          if not vars.ToggleAutoHeadshot then return end
          local heads = getHeadsInRange()
          if #heads == 0 then return end

          local originCFrame = Camera.CFrame

          for _, head in ipairs(heads) do
              task.spawn(function()
                  local uid = HttpService:GenerateGUID(false)
                  local payload = makePayload(originCFrame, uid)
                  pcall(function()
                      Send:Fire(1, uid, payload)
                  end)
              end)
              task.wait(0.01) -- delay sedikit supaya tidak lag
          end
      end

      -- Klik kiri untuk menembak semua kepala NPC
      UserInputService.InputBegan:Connect(function(input, gpe)
          if gpe then return end
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
              shootHeads()
          end
      end)

      print("✅ HeadshotAuto.lua aktif — Klik untuk tembak kepala NPC, jarak bisa diatur")
  end
}
