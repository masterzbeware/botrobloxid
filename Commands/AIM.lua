-- AIM.lua
-- Aimbot presisi tinggi ke Model "Male" dengan child "AI_"
-- Ditingkatkan: Respons lebih cepat, smooth adaptif, dan penguncian kuat

return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        _G.BotVars = vars
        local Tabs = vars.Tabs or {}
        tab = tab or Tabs.Combat
        if not tab then
            warn("[AIM] Tab Combat tidak ditemukan! Pastikan WindowTab.lua sudah dimuat.")
            return
        end

        -- Default vars
        vars.AimbotEnabled = vars.AimbotEnabled or false
        vars.ShowCircle    = vars.ShowCircle or false
        vars.CircleSize    = vars.CircleSize or 150
        vars.Wallcheck     = vars.Wallcheck or false
        vars.AimStrength   = vars.AimStrength or 0.45  -- 🔥 lebih tinggi = lebih kuat
        vars.AimSmoothness = vars.AimSmoothness or 0.15 -- 🔧 adaptif smoothing

        -- UI
        local Group = tab:AddLeftGroupbox("Aimbot")

        Group:AddToggle("AimbotEnabled", {
            Text = "Aktifkan Aimbot",
            Default = vars.AimbotEnabled,
            Callback = function(v)
                vars.AimbotEnabled = v
                print(v and "[AIMBOT] Aktif ✅" or "[AIMBOT] Nonaktif ❌")
            end
        })

        Group:AddToggle("ShowAimCircle", {
            Text = "Tampilkan Circle Aim",
            Default = vars.ShowCircle,
            Callback = function(v)
                vars.ShowCircle = v
            end
        })

        Group:AddSlider("CircleSize", {
            Text = "Ukuran Circle Aim",
            Default = vars.CircleSize,
            Min = 50,
            Max = 400,
            Rounding = 0,
            Callback = function(v)
                vars.CircleSize = v
            end
        })

        Group:AddSlider("AimStrength", {
            Text = "Kekuatan Aim",
            Default = vars.AimStrength,
            Min = 0.1,
            Max = 1,
            Rounding = 2,
            Callback = function(v)
                vars.AimStrength = v
            end
        })

        Group:AddSlider("AimSmoothness", {
            Text = "Kelembutan Aim",
            Default = vars.AimSmoothness,
            Min = 0.05,
            Max = 0.5,
            Rounding = 2,
            Callback = function(v)
                vars.AimSmoothness = v
            end
        })

        Group:AddToggle("WallcheckToggle", {
            Text = "Aktifkan Wallcheck",
            Default = vars.Wallcheck,
            Callback = function(v)
                vars.Wallcheck = v
                print(v and "[AIM] Wallcheck aktif 🧱" or "[AIM] Wallcheck dimatikan 🚫")
            end
        })

        -- Services
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera

        -- Circle Aim Visual
        local aimCircle = Drawing.new("Circle")
        aimCircle.Color = Color3.fromRGB(0, 255, 255)
        aimCircle.Thickness = 1.5
        aimCircle.Transparency = 0.8
        aimCircle.Filled = false

        -- Validasi NPC
        local function isValidNPC(model)
            if not model:IsA("Model") or model.Name ~= "Male" then return false end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return false end
            for _, c in ipairs(model:GetChildren()) do
                if typeof(c.Name) == "string" and string.sub(c.Name, 1, 3) == "AI_" then
                    return true
                end
            end
            return false
        end

        -- Wallcheck
        local function isVisible(part)
            if not vars.Wallcheck then return true end
            local origin = Camera.CFrame.Position
            local direction = (part.Position - origin)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Blacklist
            params.FilterDescendantsInstances = {Camera, game.Players.LocalPlayer.Character}

            local result = workspace:Raycast(origin, direction, params)
            if not result then return true end
            return result.Instance:IsDescendantOf(part.Parent)
        end

        -- Cache NPC setiap 1 detik
        local validNPCs = {}
        task.spawn(function()
            while true do
                validNPCs = {}
                for _, model in ipairs(workspace:GetChildren()) do
                    if isValidNPC(model) then
                        local head = model:FindFirstChild("Head")
                        if head then table.insert(validNPCs, head) end
                    end
                end
                task.wait(1)
            end
        end)

        -- Cari target terdekat di tengah layar
        local function getClosestTarget()
            local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            local closest, bestDist = nil, vars.CircleSize
            for _, head in ipairs(validNPCs) do
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < bestDist and isVisible(head) then
                        closest = head
                        bestDist = dist
                    end
                end
            end
            return closest
        end

        -- Aimbot loop
        RunService.RenderStepped:Connect(function(dt)
            -- Circle
            aimCircle.Visible = vars.ShowCircle
            if vars.ShowCircle then
                local center = Camera.ViewportSize / 2
                aimCircle.Position = Vector2.new(center.X, center.Y)
                aimCircle.Radius = vars.CircleSize
            end

            if not vars.AimbotEnabled then return end

            local target = getClosestTarget()
            if target then
                local curCF = Camera.CFrame
                local targetCF = CFrame.lookAt(curCF.Position, target.Position)

                -- adaptif lerp (kuat tapi smooth)
                local strength = math.clamp(vars.AimStrength, 0.1, 1)
                local smooth = math.clamp(vars.AimSmoothness, 0.05, 0.5)
                local delta = dt * (strength / smooth) * 5

                Camera.CFrame = curCF:Lerp(targetCF, math.clamp(delta, 0.15, 0.8))
            end
        end)

        print("✅ [AIM] Aimbot diperkuat — respons lebih cepat & stabil. Fokus ke Model 'Male' dengan AI_.")
    end
}
