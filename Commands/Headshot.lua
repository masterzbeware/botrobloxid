-- Headshot.lua
-- Klik kiri untuk menembak semua Male AI_, menembus tembok, 100% headshot, dengan toggle
-- Dijalankan melalui Bot.lua — menerima tab dari WindowTab.lua

return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        _G.BotVars = vars
        local Tabs = vars.Tabs or {}

        -- fallback: ambil tab Combat dari WindowTab.lua
        tab = tab or Tabs.Combat
        if not tab then
            warn("[Headshot] Tab Combat tidak ditemukan! Pastikan WindowTab.lua sudah dimuat.")
            return
        end

        local Camera = workspace.CurrentCamera
        local ReplicatedFirst = game:GetService("ReplicatedFirst")
        local HttpService = game:GetService("HttpService")
        local UserInputService = game:GetService("UserInputService")

        vars.EnableManualHeadshot = vars.EnableManualHeadshot or false
        vars.HeadshotRange = math.huge

        -- 🧩 UI: Groupbox di tab Combat
        local Group = tab:AddLeftGroupbox("Headshot Control")

        Group:AddToggle("EnableManualHeadshot", {
            Text = "Aktifkan Manual Headshot",
            Default = vars.EnableManualHeadshot,
            Callback = function(Value)
                vars.EnableManualHeadshot = Value
                print(Value and "[Headshot] Aktif ✅" or "[Headshot] Nonaktif ❌")
            end
        })

        Group:AddSlider("HeadshotDelay", {
            Text = "Delay antar tembakan (ms)",
            Default = 50,
            Min = 0,
            Max = 500,
            Rounding = 0,
            Callback = function(v)
                vars.HeadshotDelay = v
            end
        })

        -- 🎯 Setup Remote
        local Actor = ReplicatedFirst:FindFirstChild("Actor")
        local BulletSvc = Actor and Actor:FindFirstChild("BulletServiceMultithread")
        local Send = BulletSvc and BulletSvc:FindFirstChild("Send")

        if not Send then
            warn("[Headshot] Bullet Send remote tidak ditemukan di Actor.")
        end

        -- 🧠 Cek valid NPC target
        local function isValidNPC(model)
            if not model or not model:IsA("Model") or model.Name ~= "Male" then return false end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return false end
            for _, c in ipairs(model:GetChildren()) do
                if type(c.Name) == "string" and c.Name:find("AI_") then
                    return true
                end
            end
            return false
        end

        -- 🔍 Ambil semua target valid (menembus tembok)
        local function getTargetsInRange()
            local targets = {}
            for _, model in ipairs(workspace:GetChildren()) do
                if isValidNPC(model) then
                    local head = model:FindFirstChild("Head")
                    if head then table.insert(targets, head) end
                end
            end
            return targets
        end

        -- 🔫 Payload builder
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
                Range = math.huge,
            }
        end

        -- 💥 Fungsi tembak semua target
        local function fireAllTargets()
            if not vars.EnableManualHeadshot or not Send then return end

            local camPos = Camera.CFrame.Position
            local targets = getTargetsInRange()
            if #targets == 0 then return end

            local uidBase = HttpService:GenerateGUID(false)
            for i, head in ipairs(targets) do
                local originCFrame = CFrame.lookAt(camPos, head.Position)
                local uid = uidBase .. "-" .. tostring(i)
                local payload = buildPayload(originCFrame, uid)
                pcall(Send.Fire, Send, 1, uid, payload)
                if vars.HeadshotDelay and vars.HeadshotDelay > 0 then
                    task.wait(vars.HeadshotDelay / 1000)
                end
            end
        end

        -- 🖱️ Bind ke klik kiri mouse
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                task.spawn(fireAllTargets)
            end
        end)

        print("✅ [Headshot] Aktif — klik kiri untuk menembak semua Male AI_ menembus tembok.")
    end
}
