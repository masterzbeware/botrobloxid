-- Headshot_AIM_100Percent.lua
return {
  Execute = function()
      local vars = _G.BotVars
      vars.ToggleAutoHeadshot = vars.ToggleAutoHeadshot or false
      vars.ToggleAIM = vars.ToggleAIM or false
      vars.AimSmoothness = vars.AimSmoothness or 0
      vars.HeadshotRange = vars.HeadshotRange or 500

      local Window = vars.MainWindow
      local Camera = workspace.CurrentCamera
      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local UserInputService = game:GetService("UserInputService")
      local HttpService = game:GetService("HttpService")
      local RunService = game:GetService("RunService")

      -- Remote
      local Actor = ReplicatedFirst:WaitForChild("Actor", 2)
      local BulletSvc = Actor:WaitForChild("BulletServiceMultithread", 2)
      local Send = BulletSvc:WaitForChild("Send", 2)

      -- UI
      local Tabs = { Headshot = Window:AddTab("HEADSHOT", "target") }
      local GroupHeadshot = Tabs.Headshot:AddLeftGroupbox("Headshot Control")
      local TabsAim = { Aim = Window:AddTab("AIM", "crosshair") }
      local GroupAim = TabsAim.Aim:AddLeftGroupbox("AIM Assist Control")

      -- Toggle Headshot
      GroupHeadshot:AddToggle("EnableAutoHeadshot", {
          Text = "Aktifkan Headshot",
          Default = vars.ToggleAutoHeadshot,
          Callback = function(Value)
              vars.ToggleAutoHeadshot = Value
              print(Value and "[Headshot] Aktif ✅" or "[Headshot] Nonaktif ❌")
          end
      })

      GroupHeadshot:AddSlider("HeadshotRange", {
          Text = "Jarak Headshot",
          Default = vars.HeadshotRange,
          Min = 50,
          Max = 2000,
          Rounding = 0,
          Callback = function(Value)
              vars.HeadshotRange = Value
          end
      })

      -- Toggle AIM
      GroupAim:AddToggle("EnableAIM", {
          Text = "Aktifkan Aim Assist Lengket (Lock Kepala)",
          Default = vars.ToggleAIM,
          Callback = function(Value)
              vars.ToggleAIM = Value
              print(Value and "[AIM] Lengket Aktif ✅" or "[AIM] Nonaktif ❌")
          end
      })

      GroupAim:AddSlider("AimSmoothness", {
          Text = "Kelembutan Aim (0 = instan)",
          Default = vars.AimSmoothness,
          Min = 0,
          Max = 0.1,
          Rounding = 3,
          Callback = function(Value)
              vars.AimSmoothness = Value
          end
      })

      -- Ambil kepala NPC terdekat dalam range
      local function getNearestHead()
          local nearest, dist = nil, math.huge
          for _, model in ipairs(workspace:GetDescendants()) do
              if model:IsA("Model") and model.Name == "Male" and model:FindFirstChildOfClass("Humanoid") then
                  for _, c in ipairs(model:GetChildren()) do
                      if string.sub(c.Name,1,3) == "AI_" then
                          local head = model:FindFirstChild("Head")
                          if head then
                              local magnitude = (head.Position - Camera.CFrame.Position).Magnitude
                              if magnitude <= vars.HeadshotRange and magnitude < dist then
                                  nearest = head
                                  dist = magnitude
                              end
                          end
                          break
                      end
                  end
              end
          end
          return nearest
      end

      -- Payload 100% akurat → arahkan origin ke kepala target
      local function makePayloadToHead(head)
          local uid = HttpService:GenerateGUID(false)
          return uid, {
              Velocity = 1e9, -- super cepat supaya tidak meleset
              Caliber = "intermediaterifle_556x45mmNATO_M855",
              UID = uid,
              Ignore = workspace.Male,
              OriginCFrame = CFrame.new(Camera.CFrame.Position, head.Position),
              Tracer = "Default",
              Replicate = true,
              Local = true,
              Range = 1e9,
          }
      end

      -- Tembak kepala target (100% kena)
      local function shootHead(targetHead)
          if not vars.ToggleAutoHeadshot or not targetHead then return end
          local uid, payload = makePayloadToHead(targetHead)
          pcall(function()
              Send:Fire(1, uid, payload)
          end)
      end

      -- AIM lock ke kepala target
      local currentTarget = nil
      RunService.RenderStepped:Connect(function()
          if vars.ToggleAIM then
              currentTarget = getNearestHead()
              if currentTarget then
                  local currentCF = Camera.CFrame
                  local targetCF = CFrame.lookAt(currentCF.Position, currentTarget.Position)
                  local smooth = vars.AimSmoothness or 0
                  Camera.CFrame = currentCF:Lerp(targetCF, smooth)
              end
          end
      end)

      -- Klik kiri → tembak kepala target AIM (100% kena)
      UserInputService.InputBegan:Connect(function(input, gpe)
          if gpe then return end
          if input.UserInputType == Enum.UserInputType.MouseButton1 then
              shootHead(currentTarget or getNearestHead())
          end
      end)

      print("✅ Headshot + AIM sinkron 100% kena kepala aktif")
  end
}
