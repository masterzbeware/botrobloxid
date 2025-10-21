-- Headshot.lua
-- Klik kiri untuk menembak semua Male AI_ di map, menembus tembok, 100% headshot
return {
    Execute = function()
        local vars = _G.BotVars or {}
        _G.BotVars = vars

        vars.EnableManualHeadshot = true
        vars.HeadshotRange = math.huge -- Range tak terbatas

        local Camera = workspace.CurrentCamera
        local ReplicatedFirst = game:GetService("ReplicatedFirst")
        local HttpService = game:GetService("HttpService")
        local UserInputService = game:GetService("UserInputService")

        -- Remote setup
        local Actor = ReplicatedFirst:WaitForChild("Actor", 2)
        local BulletSvc = Actor and Actor:FindFirstChild("BulletServiceMultithread")
        local Send = BulletSvc and BulletSvc:FindFirstChild("Send")
        if not Send then
            warn("[Headshot] Bullet Send remote tidak ditemukan.")
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

        -- Ambil semua target dalam range (menembus tembok)
        local function getTargetsInRange()
            local camPos = Camera.CFrame.Position
            local targets = {}
            for _, model in ipairs(workspace:GetChildren()) do
                if model:IsA("Model") and isValidNPC(model) then
                    local head = model:FindFirstChild("Head")
                    if head then
                        table.insert(targets, head)
                    end
                end
            end
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
                Range = math.huge, -- Range infinite
            }
        end

        -- Fungsi tembak semua target
        local function fireAllTargets()
            if not vars.EnableManualHeadshot then return end
            local camPos = Camera.CFrame.Position
            local targets = getTargetsInRange()
            if #targets == 0 then return end

            local uidBase = HttpService:GenerateGUID(false)
            for i, head in ipairs(targets) do
                local originCFrame = CFrame.lookAt(camPos, head.Position)
                local uid = uidBase .. "-" .. tostring(i)
                local payload = buildPayload(originCFrame, uid)
                pcall(Send.Fire, Send, 1, uid, payload)
            end
        end

        -- Bind klik kiri
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                task.spawn(fireAllTargets)
            end
        end)

        print("✅ Headshot.lua aktif — klik kiri untuk menembak semua Male AI_ di map, menembus tembok, 100% headshot")
    end
}
