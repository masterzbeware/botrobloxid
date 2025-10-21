-- Headshot.lua
-- Auto Aim ke kepala target terdekat (AI_Male)
-- Tanpa auto fire, hanya mengarahkan kamera
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
        local RunService = game:GetService("RunService")

        -- Default state
        vars.AutoHeadshot = vars.AutoHeadshot or false
        vars.HeadshotRange = vars.HeadshotRange or 1000

        -- 🧩 UI Toggle
        local Group = tab:AddLeftGroupbox("Auto Headshot")
        Group:AddToggle("AutoHeadshot", {
            Text = "Aktifkan Auto Headshot (Aim Only)",
            Default = vars.AutoHeadshot,
            Callback = function(Value)
                vars.AutoHeadshot = Value
                print(Value and "[Headshot] Auto Aim ke kepala Aktif ✅" or "[Headshot] Nonaktif ❌")
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

        -- Arahkan kamera ke kepala target
        RunService.RenderStepped:Connect(function()
            if not vars.AutoHeadshot then return end
            local target = getClosestTarget()
            if not target then return end

            local curCF = Camera.CFrame
            local targetCF = CFrame.lookAt(curCF.Position, target.Position)
            Camera.CFrame = curCF:Lerp(targetCF, 0.15)
        end)

        print("✅ [Headshot] Auto Aim ke kepala siap digunakan (tanpa auto fire).")
    end
}
