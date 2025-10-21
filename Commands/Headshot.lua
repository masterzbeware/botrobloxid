-- Headshot.lua
-- Auto Aim ke kepala NPC "Male" dengan child "AI_"
-- Tanpa auto fire, hanya mengarahkan kamera saat pemain menembak

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
        local UserInputService = game:GetService("UserInputService")

        -- Default state
        vars.AutoHeadshot = vars.AutoHeadshot or false
        vars.HeadshotRange = vars.HeadshotRange or 1000

        -- === UI ===
        local Group = tab:AddLeftGroupbox("Auto Headshot")
        Group:AddToggle("AutoHeadshot", {
            Text = "Auto Headshot (arah ke kepala NPC)",
            Default = vars.AutoHeadshot,
            Callback = function(Value)
                vars.AutoHeadshot = Value
                print(Value and "[Headshot] Auto Headshot aktif ✅" or "[Headshot] Nonaktif ❌")
            end
        })

        -------------------------------------------------
        -- === VALIDASI NPC SESUAI STRUKTUR ESP ===
        -------------------------------------------------
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

        -------------------------------------------------
        -- === AMBIL HEAD TERDEKAT ===
        -------------------------------------------------
        local function getClosestHead()
            local camPos = Camera.CFrame.Position
            local camLook = Camera.CFrame.LookVector
            local bestHead, bestDot, bestDist = nil, 0.97, vars.HeadshotRange

            for _, model in ipairs(workspace:GetChildren()) do
                if isValidNPC(model) then
                    local head = model:FindFirstChild("Head")
                    if head then
                        local dir = (head.Position - camPos).Unit
                        local dot = camLook:Dot(dir)
                        local dist = (head.Position - camPos).Magnitude
                        if dot > bestDot and dist < bestDist then
                            bestHead, bestDot, bestDist = head, dot, dist
                        end
                    end
                end
            end
            return bestHead
        end

        -------------------------------------------------
        -- === SAAT MENEMBAK (klik kiri) ===
        -------------------------------------------------
        local isShooting = false

        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if not vars.AutoHeadshot or isShooting then return end
            isShooting = true

            local target = getClosestHead()
            if target then
                local newCF = CFrame.lookAt(Camera.CFrame.Position, target.Position)
                -- Gunakan lerp halus agar tidak terlalu snap
                Camera.CFrame = Camera.CFrame:Lerp(newCF, 0.25)
                print("[Headshot] Arah tembakan dikoreksi ke kepala " .. target.Parent.Name .. " 🎯")
            end

            task.wait(0.1)
            isShooting = false
        end)

        print("✅ [Headshot] Siap — setiap kali menembak, bidikan diarahkan ke kepala NPC Male.")
    end
}
