-- HeadshotManual_ThroughWalls.lua
-- Manual multi-headshot: menembak semua Male AI_ di dalam range saat klik kiri, menembus tembok
return {
    Execute = function()
        local vars = _G.BotVars or {}
        _G.BotVars = vars

        vars.EnableManualHeadshot = vars.EnableManualHeadshot or false
        vars.HeadshotRange = vars.HeadshotRange or 500
        vars.MaxTargetsPerShot = vars.MaxTargetsPerShot or 100

        local Camera = workspace.CurrentCamera
        local ReplicatedFirst = game:GetService("ReplicatedFirst")
        local HttpService = game:GetService("HttpService")
        local UserInputService = game:GetService("UserInputService")

        -- UI (jika tersedia)
        local Window = vars.MainWindow
        if Window then
            local Tabs = { Headshot = Window:AddTab("HEADSHOT", "target") }
            local Group = Tabs.Headshot:AddLeftGroupbox("Headshot Control")

            Group:AddToggle("EnableManualHeadshot", {
                Text = "Aktifkan Manual Headshot (Klik kiri untuk tembak semua)",
                Default = vars.EnableManualHeadshot,
                Callback = function(Value) vars.EnableManualHeadshot = Value end
            })

            Group:AddSlider("HeadshotRange", {
                Text = "Range Tembak (studs)",
                Default = vars.HeadshotRange,
                Min = 50,
                Max = 2000,
                Rounding = 0,
                Callback = function(Value) vars.HeadshotRange = Value end
            })

            Group:AddSlider("MaxTargetsPerShot", {
                Text = "Max Targets Per Click",
                Default = vars.MaxTargetsPerShot,
                Min = 1,
                Max = 200,
                Rounding = 0,
                Callback = function(Value) vars.MaxTargetsPerShot = Value end
            })
        end

        -- Remote setup
        local Actor = ReplicatedFirst:WaitForChild("Actor", 2)
        local BulletSvc = Actor and Actor:FindFirstChild("BulletServiceMultithread")
        local Send = BulletSvc and BulletSvc:FindFirstChild("Send")
        if not Send then
            warn("[HeadshotManual] Bullet Send remote tidak ditemukan.")
            return
        end

        -- Helper: cek Male AI_ valid & hidup
        local function isValidNPC(model)
            if not model or not model:IsA("Model") or model.Name ~= "Male" then return false end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return false end
            for _, c in ipairs(model:GetChildren()) do
                if type(c.Name) == "string" and c.Name:find("AI_") then return true end
            end
            return false
        end

        -- Ambil semua target dalam range (melewati tembok)
        local function getTargetsInRange()
            local camPos = Camera and Camera.CFrame.Position or workspace.CurrentCamera.CFrame.Position
            local range = vars.HeadshotRange or 500
            local targets = {}

            for _, model in ipairs(workspace:GetChildren()) do
                if model:IsA("Model") and isValidNPC(model) then
                    local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                    if head then
                        local d = (head.Position - camPos).Magnitude
                        if d <= range then
                            table.insert(targets, {model = model, part = head, dist = d})
                        end
                    end
                end
            end

            -- urutkan jarak terdekat dulu
            table.sort(targets, function(a,b) return a.dist < b.dist end)
            return targets
        end

        -- Payload builder
        local function buildPayload(originCFrame, uid)
            return {
                Velocity = 3110.666858146635,
                Caliber = "intermediaterifle_556x45mmNATO_M855",
                UID = uid,
                Ignore = workspace.Male,
                OriginCFrame = originCFrame,
                Tracer = "Default",
                Replicate = true,
                Local = true,
                Range = vars.HeadshotRange or 2104.88,
            }
        end

        -- Fungsi tembak semua target
        local function fireAllTargets()
            if not vars.EnableManualHeadshot then return end
            if not Camera then return end

            local camPos = Camera.CFrame.Position
            local targets = getTargetsInRange()
            if #targets == 0 then return end

            local maxTargets = math.max(1, math.floor(vars.MaxTargetsPerShot or 100))
            local uidBase = HttpService:GenerateGUID(false)
            local fired = 0

            for i, info in ipairs(targets) do
                if fired >= maxTargets then break end
                local targetPart = info.part
                local originCFrame = CFrame.lookAt(camPos, targetPart.Position)
                local uid = uidBase .. "-" .. tostring(i)
                local payload = buildPayload(originCFrame, uid)
                pcall(Send.Fire, Send, 1, uid, payload)
                fired = fired + 1
            end
        end

        -- Bind klik kiri
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                task.spawn(fireAllTargets)
            end
        end)

        print("✅ HeadshotManual_ThroughWalls.lua aktif — klik kiri untuk menembak semua Male AI_ dalam range, menembus tembok")
    end
}
