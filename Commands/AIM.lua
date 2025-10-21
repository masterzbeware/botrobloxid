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

        vars.AimbotEnabled = vars.AimbotEnabled or false
        vars.ShowCircle    = vars.ShowCircle or false
        vars.CircleSize    = vars.CircleSize or 150
        vars.Wallcheck     = vars.Wallcheck or false
        vars.AimStrength   = vars.AimStrength or 0.45
        vars.AimSmoothness = vars.AimSmoothness or 0.15
        vars.ADSActive     = vars.ADSActive or false

        local Group = tab:AddLeftGroupbox("Aimbot")

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

        local RunService = game:GetService("RunService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Camera = workspace.CurrentCamera

        local RemoteEvent = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RemoteEvent")

        local aimCircle = Drawing.new("Circle")
        aimCircle.Color = Color3.fromRGB(0, 255, 255)
        aimCircle.Thickness = 1.5
        aimCircle.Transparency = 0.8
        aimCircle.Filled = false

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

        if RemoteEvent then
            RemoteEvent.OnClientEvent:Connect(function(action, id, _, actionType, state)
                if action == "ActionActor" and actionType == "ADS" then
                    vars.ADSActive = state
                    vars.AimbotEnabled = state
                    print(state and "[ADS] Aim aktif otomatis 🎯" or "[ADS] Aim nonaktif ❌")
                end
            end)
        else
            warn("[AIM] RemoteEvent tidak ditemukan di ReplicatedStorage.Events.RemoteEvent")
        end

        RunService.RenderStepped:Connect(function(dt)
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
                local strength = math.clamp(vars.AimStrength, 0.1, 1)
                local smooth = math.clamp(vars.AimSmoothness, 0.05, 0.5)
                local delta = dt * (strength / smooth) * 5
                Camera.CFrame = curCF:Lerp(targetCF, math.clamp(delta, 0.15, 0.8))
            end
        end)

        print("✅ [AIM] Aimbot siap, aktif otomatis saat ADS ditekan.")
    end
}
