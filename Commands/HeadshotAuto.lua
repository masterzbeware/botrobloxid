-- HeadshotAuto.lua
-- 🎯 Auto Headshot ke NPC Male AI_ (tanpa burst) dengan slider jarak tembak

return {
  Execute = function()
      local vars = _G.BotVars
      local Window = vars.MainWindow
      local Camera = workspace.CurrentCamera
      local UserInputService = game:GetService("UserInputService")
      local HttpService = game:GetService("HttpService")
      local RunService = game:GetService("RunService")

      -- Cari Send remote (Sigma Spy style)
      local Actor = ReplicatedFirst:WaitForChild("Actor", 2)
      local BulletSvc = Actor:WaitForChild("BulletServiceMultithread", 2)
      local Send = BulletSvc:WaitForChild("Send", 2)

      -- UI
      local Tabs = { Headshot = Window:AddTab("HEADSHOT", "target") }
      local Group = Tabs.Headshot:AddLeftGroupbox("Headshot Control")

      -- Toggle aktif/nonaktif
      Group:AddToggle("EnableAutoHeadshot", {
          Text = "Aktifkan Auto Headshot",
          Default = false,
          Callback = function(Value)
              vars.ToggleAutoHeadshot = Value
              print(Value and "[Headshot] Aktif ✅" or "[Headshot] Nonaktif ❌")
          end
      })

      -- Slider jarak tembak
      Group:AddSlider("HeadshotRange", {
          Text = "Jarak tembak (studs)",
          Default = 1000,
          Min = 50,
          Max = 5000,
          Rounding = 0,
          Callback = function(Value)
              vars.HeadshotRange = Value
          end
      })

      -- Fungsi cari semua kepala NPC Male AI_ di radius
      local function getHeadsInRange()
          local heads = {}
          local range = vars.HeadshotRange or 1000
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

      -- Fungsi tembak kepala
      local function shootHeads()
          if not vars.ToggleAutoHeadshot then return end
          local heads = getHeadsInRange()
          if #heads == 0 then return end
          local originCFrame = Camera.CFrame

          for _, head in ipairs(heads) do
              if head and head.Parent then
                  local uid = HttpService:GenerateGUID(false)
                  local payload = makePayload(originCFrame, uid)
                  pcall(function()
                      Send:Fire(1, uid, payload)
                  end)
              end
          end
      end

      -- Klik kiri untuk menembak semua kepala NPC di radius
      UserInputService.InputBegan:Connect(function(input, gpe)
          if gpe then return end
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
              shootHeads()
          end
      end)

      print("✅ HeadshotAuto.lua siap digunakan — klik kiri = tembak kepala semua NPC Male AI_ dalam radius slider")
  end
}
