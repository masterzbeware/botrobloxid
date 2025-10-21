-- Headshot.lua
-- Auto Aim otomatis ke bagian tubuh NPC "Male" dengan child "AI_"
-- Tambahan Dropdown Pilihan Target Body (Head / Torso / HumanoidRootPart)

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

        vars.AutoHeadshot = true
        vars.HeadshotRange = vars.HeadshotRange or 1000
        vars.TargetPart = vars.TargetPart or "Head"

        local Group = tab:AddLeftGroupbox("Auto Headshot")

        Group:AddDropdown("TargetPart", {
            Text = "Pilih Target",
            Default = vars.TargetPart,
            Values = { "Head", "Torso", "HumanoidRootPart" },
            Callback = function(value)
                vars.TargetPart = value
                print("[Headshot] Target body diganti ke:", value)
            end
        })

        local function isValidNPC(model)
            if not model:IsA("Model") or model.Name ~= "Male" then return false end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return false end
            for _, c in ipairs(model:GetChildren()) do
                if string.sub(c.Name, 1, 3) == "AI_" then
                    return true
                end
            end
            return false
        end

        local function getClosestTarget()
            local camPos = Camera.CFrame.Position
            local camLook = Camera.CFrame.LookVector
            local bestTarget, bestDot, bestDist = nil, 0.97, vars.HeadshotRange

            for _, model in ipairs(workspace:GetChildren()) do
                if isValidNPC(model) then
                    local part = model:FindFirstChild(vars.TargetPart)
                    if part then
                        local dir = (part.Position - camPos).Unit
                        local dot = camLook:Dot(dir)
                        local dist = (part.Position - camPos).Magnitude
                        if dot > bestDot and dist < bestDist then
                            bestTarget, bestDot, bestDist = part, dot, dist
                        end
                    end
                end
            end
            return bestTarget
        end

        RunService.RenderStepped:Connect(function()
            if not vars.AutoHeadshot then return end
            local target = getClosestTarget()
            if target then
                local curCF = Camera.CFrame
                local targetCF = CFrame.lookAt(curCF.Position, target.Position)
                Camera.CFrame = curCF:Lerp(targetCF, 0.18)
            end
        end)

        print("✅ [Headshot] Auto Aim aktif — mengunci ke '" .. vars.TargetPart .. "' NPC Male dengan AI_.")
    end
}
