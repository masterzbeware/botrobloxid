-- Headshot.lua
-- Auto Headshot otomatis ke target terdekat (AI_Male)
-- Toggle di tab Combat dari WindowTab.lua

return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        _G.BotVars = vars
        local Tabs = vars.Tabs or {}

        tab = tab or Tabs.Combat
        if not tab then
            warn("[Headshot] Tab Combat tidak ditemukan! Pastikan WindowTab.lua sudah dimuat.")
            return
        end

        local Camera = workspace.CurrentCamera
        local ReplicatedFirst = game:GetService("ReplicatedFirst")
        local RunService = game:GetService("RunService")
        local HttpService = game:GetService("HttpService")

        local Actor = ReplicatedFirst:FindFirstChild("Actor")
        local BulletSvc = Actor and Actor:FindFirstChild("BulletServiceMultithread")
        local Send = BulletSvc and BulletSvc:FindFirstChild("Send")
        if not Send then
            warn("[Headshot] Bullet Send remote tidak ditemukan di Actor.")
            return
        end

        -- Default state
        vars.AutoHeadshot = vars.AutoHeadshot or false
        vars.HeadshotRange = vars.HeadshotRange or 1000

        -- 🧩 UI Toggle
        local Group = tab:AddLeftGroupbox("Auto Headshot")
        Group:AddToggle("AutoHeadshot", {
            Text = "Aktifkan Auto Headshot",
            Default = vars.AutoHeadshot,
            Callback = function(Value)
                vars.AutoHeadshot = Value
                print(Value and "[Headshot] Auto Headshot Aktif ✅" or "[Headshot] Nonaktif ❌")
            end
        })

        -- Validasi NPC
        local function isValidNPC(model)
            if not model:IsA("Model") or model.Name ~= "Male" then return false end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return false end
            for _, c in ipairs(model:GetChildren()) do
                if string.sub(c.Name, 1, 3) == "AI_" then return true end
            end
            return false
        end

        -- Ambil target terdekat di depan kamera
        local function getClosestTarget()
            local camPos = Camera.CFrame.Position
            local camLook = Camera.CFrame.LookVector
            local bestTarget, bestDot, bestDist = nil, 0.97, vars.HeadshotRange

            for _, model in ipairs(workspace:GetChildren()) do
                if isValidNPC(model) then
                    local head = model:FindFirstChild("Head")
                    if head then
                        local dir = (head.Position - camPos).Unit
                        local dot = camLook:Dot(dir)
                        local dist = (head.Position - camPos).Magnitude
                        if dot > bestDot and dist < bestDist then
                            bestDot, bestDist, bestTarget = dot, dist, head
                        end
                    end
                end
            end
            return bestTarget
        end

        -- Kirim tembakan
        local function buildPayload(originCFrame, uid)
            return {
                Velocity = 3110.666858146635,
                Caliber = "intermediaterifle_556x45mmNATO_M855",
                UID = uid,
                OriginCFrame = originCFrame,
                Tracer = "Default",
                Replicate = true,
                Local = true,
                Range = math.huge,
            }
        end

        -- Auto headshot setiap frame
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not vars.AutoHeadshot then return end
            local target = getClosestTarget()
            if not target then return end

            local camPos = Camera.CFrame.Position
            local originCFrame = CFrame.lookAt(camPos, target.Position)
            local uid = HttpService:GenerateGUID(false)
            local payload = buildPayload(originCFrame, uid)
            pcall(Send.Fire, Send, 1, uid, payload)
        end)

        print("✅ [Headshot] Auto Headshot siap — aktifkan toggle di tab Combat.")
    end
}
