return {
  Execute = function()
      local vars = _G.BotVars
      vars.ToggleAutoHeadshot = vars.ToggleAutoHeadshot or false
      local Window = vars.MainWindow
      local Camera = workspace.CurrentCamera
      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local UserInputService = game:GetService("UserInputService")
      local HttpService = game:GetService("HttpService")

      -- Remote
      local Actor = ReplicatedFirst:WaitForChild("Actor", 2)
      local BulletSvc = Actor:WaitForChild("BulletServiceMultithread", 2)
      local Send = BulletSvc:WaitForChild("Send", 2)

      -- UI
      local Tabs = { Headshot = Window:AddTab("HEADSHOT", "target") }
      local Group = Tabs.Headshot:AddLeftGroupbox("Headshot Control")

      Group:AddToggle("EnableAutoHeadshot", {
          Text = "Aktifkan Headshot",
          Default = vars.ToggleAutoHeadshot,
          Callback = function(Value)
              vars.ToggleAutoHeadshot = Value
              print(Value and "[Headshot] Aktif ✅" or "[Headshot] Nonaktif ❌")
          end
      })

      Group:AddSlider("HeadshotRange", {
          Text = "Jarak Headshot",
          Default = 500,
          Min = 50,
          Max = 2000,
          Rounding = 0,
          Callback = function(Value)
              vars.HeadshotRange = Value
          end
      })

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

      local function shootHeads()
          if not vars.ToggleAutoHeadshot then return end
          local heads = getHeadsInRange()
          if #heads == 0 then return end

          local originCFrame = Camera.CFrame
          local head = heads[1]
          local uid = HttpService:GenerateGUID(false)
          local payload = makePayload(originCFrame, uid)
          pcall(function() Send:Fire(1, uid, payload) end)
      end

      UserInputService.InputBegan:Connect(function(input, gpe)
          if gpe then return end
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
              shootHeads()
          end
      end)

      print("✅ HeadshotAuto.lua kompatibel aktif")
  end
}
