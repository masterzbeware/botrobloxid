-- HeadshotAuto.lua
-- Hanya Auto-Headshot ke semua Male AI_ (tanpa AIM / camera lock)
return {
  Execute = function()
      local vars = _G.BotVars or {}
      _G.BotVars = vars

      vars.ToggleAutoHeadshot = vars.ToggleAutoHeadshot or false
      vars.HeadshotRange = vars.HeadshotRange or 500
      vars.AutoFireInterval = vars.AutoFireInterval or 0.12 -- detik antara tembakan otomatis
      local Window = vars.MainWindow
      local Camera = workspace.CurrentCamera

      local ReplicatedFirst = game:GetService("ReplicatedFirst")
      local HttpService = game:GetService("HttpService")
      local RunService = game:GetService("RunService")

      -- Remote
      local Actor = ReplicatedFirst:WaitForChild("Actor", 2)
      local BulletSvc = Actor and Actor:FindFirstChild("BulletServiceMultithread")
      local Send = BulletSvc and BulletSvc:FindFirstChild("Send")

      if not Send then
          warn("[HeadshotAuto] Bullet Send remote tidak ditemukan. Script dihentikan.")
          return
      end

      -- UI (hanya HEADSHOT tab)
      local Tabs = { Headshot = Window:AddTab("HEADSHOT", "target") }
      local GroupHeadshot = Tabs.Headshot:AddLeftGroupbox("Headshot Control")

      GroupHeadshot:AddToggle("EnableAutoHeadshot", {
          Text = "Aktifkan Auto Headshot (ke semua AI Male)",
          Default = vars.ToggleAutoHeadshot,
          Callback = function(Value)
              vars.ToggleAutoHeadshot = Value
              print(Value and "[Headshot] Aktif ✅" or "[Headshot] Nonaktif ❌")
          end
      })

      GroupHeadshot:AddSlider("HeadshotRange", {
          Text = "Jarak Headshot (studs)",
          Default = vars.HeadshotRange,
          Min = 50,
          Max = 2000,
          Rounding = 0,
          Callback = function(Value)
              vars.HeadshotRange = Value
          end
      })

      GroupHeadshot:AddSlider("AutoFireInterval", {
          Text = "Interval Tembak (detik)",
          Default = vars.AutoFireInterval,
          Min = 0.01,
          Max = 1,
          Rounding = 3,
          Callback = function(Value)
              vars.AutoFireInterval = Value
          end
      })

      -- Helper: apakah model Male memiliki anak yang namanya mengandung "AI_"
      local function modelHasAINode(mdl)
          for _, child in ipairs(mdl:GetChildren()) do
              if type(child.Name) == "string" and child.Name:find("AI_") then
                  return true
              end
          end
          return false
      end

      -- Cari semua kepala (Head / HumanoidRootPart / BasePart) dari Male AI_ dalam range
      local function getAIHeadsInRange()
          local heads = {}
          local range = vars.HeadshotRange or 500
          local camPos = (Camera and Camera.CFrame and Camera.CFrame.Position) or workspace.CurrentCamera.CFrame.Position
          for _, obj in ipairs(workspace:GetChildren()) do
              if obj:IsA("Model") and obj.Name == "Male" and modelHasAINode(obj) then
                  local targetPart = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                  if targetPart then
                      local mag = (targetPart.Position - camPos).Magnitude
                      if mag <= range then
                          table.insert(heads, {part = targetPart, dist = mag})
                      end
                  end
              end
          end
          return heads
      end

      -- Payload builder (mengikuti pola Send:Fire(1, UIDString, payload))
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
              Range = 2104.8866884716813,
          }
      end

      -- Fungsi tembak ke part (mengatur OriginCFrame agar menghadap target)
      local function fireAtPart(part)
          if not part or not Camera then return end
          local originPos = Camera.CFrame.Position
          local originCFrame = CFrame.lookAt(originPos, part.Position)
          local uid = HttpService:GenerateGUID(false)
          local payload = makePayload(originCFrame, uid)

          pcall(function()
              Send:Fire(1, uid, payload)
          end)

          -- Kirim juga BulletEvent lokal jika tersedia (opsional)
          local BulletEvent = ReplicatedFirst:FindFirstChild("BulletEvent")
          if BulletEvent then
              pcall(function()
                  BulletEvent:Fire(1, uid, true, part.Position, part, (part.Position - originPos).Unit, Enum.Material.Wood, 0.018505063986543308)
              end)
          end
      end

      -- Loop auto-fire (throttle menggunakan AutoFireInterval)
      local lastFire = 0
      RunService.Heartbeat:Connect(function(dt)
          if not vars.ToggleAutoHeadshot then return end
          lastFire = lastFire + dt
          if lastFire < (vars.AutoFireInterval or 0.12) then return end
          lastFire = 0

          local heads = getAIHeadsInRange()
          if #heads == 0 then return end

          for _, info in ipairs(heads) do
              pcall(function()
                  fireAtPart(info.part)
              end)
          end
      end)

      print("✅ HeadshotAuto.lua aktif — auto-fire ke semua Male AI_ (tanpa AIM)")
  end
}
