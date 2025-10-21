-- Auto Aim / Headshot Gabungan
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        _G.BotVars = vars
        local Tabs = vars.Tabs or {}
        tab = tab or Tabs.Combat

        if not tab then
            warn("[Aim] Tab Combat tidak ditemukan! Pastikan WindowTab.lua sudah dimuat.")
            return
        end

        local Camera = workspace.CurrentCamera
        local RunService = game:GetService("RunService")

        -- Variabel default
        vars.AimEnabled = vars.AimEnabled or false
        vars.TargetPart = vars.TargetPart or "Head"
        vars.AimStrength = vars.AimStrength or 0.45
        vars.AimSmoothness = vars.AimSmoothness or 0.15
        vars.ShowCircle = vars.ShowCircle or false
        vars.CircleSize = vars.CircleSize or 150
        vars.Wallcheck = vars.Wallcheck or false

        local Group = tab:AddLeftGroupbox("Auto Aim / Headshot")

        -- Toggle utama untuk aktif/nonaktif
        Group:AddToggle("AimToggle", {
            Text = "Aktifkan Aim",
            Default = vars.AimEnabled,
            Callback = function(v)
                vars.AimEnabled = v
                print("[Aim] Auto Aim", v and "Aktif ✅" or "Nonaktif ❌")
            end
        })

        -- Dropdown untuk pilih target part
        Group:AddDropdown("TargetPart", {
            Text = "Pilih Target",
            Default = vars.TargetPart,
            Values = { "Head", "Torso", "HumanoidRootPart" },
            Callback = function(value)
                vars.TargetPart = value
                print("[Aim] Target body diganti ke:", value)
            end
        })

        -- Toggle Circle Aim
        Group:AddToggle("ShowCircle", {
            Text = "Tampilkan Circle Aim",
            Default = vars.ShowCircle,
            Callback = function(v) vars.ShowCircle = v end
        })

        -- Slider ukuran circle
        Group:AddSlider("CircleSize", {
            Text = "Ukuran Circle Aim",
            Default = vars.CircleSize,
            Min = 50,
            Max = 400,
            Rounding = 0,
            Callback = function(v) vars.CircleSize = v end
        })

        -- Fungsi validasi NPC
        local function isValidNPC(model)
            if not model:IsA("Model") or model.Name ~= "Male" then return false end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return false end
            for _, c in ipairs(model:GetChildren()) do
                if typeof(c.Name) == "string" and string.sub(c.Name,1,3) == "AI_" then
                    return true
                end
            end
            return false
        end

        -- Wallcheck
        local function isVisible(part)
            if not vars.Wallcheck then return true end
            local origin = Camera.CFrame.Position
            local dir = (part.Position - origin)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Blacklist
            params.FilterDescendantsInstances = {Camera, game.Players.LocalPlayer.Character}
            local result = workspace:Raycast(origin, dir, params)
            if not result then return true end
            return result.Instance:IsDescendantOf(part.Parent)
        end

        -- Loop untuk update daftar NPC valid
        local validTargets = {}
        task.spawn(function()
            while true do
                validTargets = {}
                for _, model in ipairs(workspace:GetChildren()) do
                    if isValidNPC(model) then
                        local part = model:FindFirstChild(vars.TargetPart)
                        if part then table.insert(validTargets, part) end
                    end
                end
                task.wait(0.5)
            end
        end)

        -- Cari target terdekat dari center screen
        local function getClosestTarget()
            local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            local closest, bestDist = nil, vars.CircleSize
            for _, part in ipairs(validTargets) do
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < bestDist and isVisible(part) then
                        closest = part
                        bestDist = dist
                    end
                end
            end
            return closest
        end

        -- Circle Aim
        local aimCircle = Drawing.new("Circle")
        aimCircle.Color = Color3.fromRGB(0,255,255)
        aimCircle.Thickness = 1.5
        aimCircle.Transparency = 0.8
        aimCircle.Filled = false

        -- RenderStepped loop
        RunService.RenderStepped:Connect(function(dt)
            -- Update circle
            aimCircle.Visible = vars.ShowCircle
            if vars.ShowCircle then
                local center = Camera.ViewportSize / 2
                aimCircle.Position = Vector2.new(center.X, center.Y)
                aimCircle.Radius = vars.CircleSize
            end

            if not vars.AimEnabled then return end
            local target = getClosestTarget()
            if target then
                local curCF = Camera.CFrame
                local targetCF = CFrame.lookAt(curCF.Position, target.Position)
                local strength = math.clamp(vars.AimStrength,0.1,1)
                local smooth = math.clamp(vars.AimSmoothness,0.05,0.5)
                local delta = dt * (strength / smooth) * 5
                Camera.CFrame = curCF:Lerp(targetCF, math.clamp(delta,0.15,0.8))
            end
        end)

        print("✅ [Aim] Auto Aim / Headshot siap. Gunakan toggle untuk aktifkan.")
    end
}
