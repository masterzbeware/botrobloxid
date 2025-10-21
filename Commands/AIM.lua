-- Aim.lua
-- Visualizer + Aim Assist (halus / legal)
-- Tidak auto tembak, hanya bantu arah kamera dengan lembut.

return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        _G.BotVars = vars
        local Tabs = vars.Tabs or {}
        tab = tab or Tabs.Combat

        if not tab then
            warn("[Aim] Tab Combat tidak ditemukan!")
            return
        end

        if vars._VisualizerCleanup then
            pcall(vars._VisualizerCleanup)
            vars._VisualizerCleanup = nil
        end

        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        vars.ShowVisualizer = vars.ShowVisualizer or false
        vars.TargetPart = vars.TargetPart or "Head"
        vars.CircleSize = vars.CircleSize or 150
        vars.HighlightColor = vars.HighlightColor or Color3.fromRGB(0, 255, 255)
        vars.DebugMode = vars.DebugMode or false
        vars.ScreenTargetRadius = vars.ScreenTargetRadius or vars.CircleSize
        vars.EnableAimAssist = vars.EnableAimAssist or false
        vars.AimSmoothness = vars.AimSmoothness or 0.15

        local Group = tab:AddLeftGroupbox("Auto Aim / Headshot (Visualizer)")

        Group:AddToggle("ShowVisualizer", {
            Text = "Tampilkan Visual Target",
            Default = vars.ShowVisualizer,
            Callback = function(v)
                vars.ShowVisualizer = v
                print("[Visualizer]", v and "Aktif ✅" or "Nonaktif ❌")
            end
        })

        Group:AddDropdown("TargetPart", {
            Text = "Pilih Target Part",
            Default = vars.TargetPart,
            Values = { "Head", "Torso", "HumanoidRootPart" },
            Callback = function(value)
                vars.TargetPart = value
                print("[Visualizer] Target part:", value)
            end
        })

        Group:AddToggle("ShowCircle", {
            Text = "Tampilkan Circle Tengah",
            Default = true,
            Callback = function(v) vars.ShowCircle = v end
        })

        Group:AddSlider("CircleSize", {
            Text = "Ukuran Circle (px)",
            Default = vars.CircleSize,
            Min = 50,
            Max = 400,
            Rounding = 0,
            Callback = function(v)
                vars.CircleSize = v
                vars.ScreenTargetRadius = v
            end
        })

        Group:AddToggle("EnableAimAssist", {
            Text = "Aktifkan Aim Assist (halus)",
            Default = vars.EnableAimAssist,
            Callback = function(v)
                vars.EnableAimAssist = v
                print("[AimAssist]", v and "Aktif ✅" or "Nonaktif ❌")
            end
        })

        Group:AddSlider("AimSmoothness", {
            Text = "Kehalusan Aim",
            Default = vars.AimSmoothness,
            Min = 0.05,
            Max = 0.5,
            Rounding = 2,
            Callback = function(v)
                vars.AimSmoothness = v
            end
        })

        Group:AddToggle("DebugMode", {
            Text = "Debug Mode (console)",
            Default = vars.DebugMode,
            Callback = function(v) vars.DebugMode = v end
        })

        local function isValidNPC(model)
            if not model or not model:IsA("Model") then return false end
            if model == LocalPlayer.Character then return false end
            local hum = model:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return false end
            return model:FindFirstChild(vars.TargetPart) ~= nil
        end

        local validTargets = {}
        local targetLookup = {}

        local function tryAddTarget(model)
            if not model:IsA("Model") then return end
            if not isValidNPC(model) then return end
            local part = model:FindFirstChild(vars.TargetPart)
            if part and not targetLookup[part] then
                table.insert(validTargets, part)
                targetLookup[part] = true
                if vars.DebugMode then
                    print("[Visualizer] Added target:", model:GetFullName())
                end
            end
        end

        local function removeTargetModel(model)
            for i = #validTargets, 1, -1 do
                local part = validTargets[i]
                if part and part.Parent == model then
                    targetLookup[part] = nil
                    table.remove(validTargets, i)
                end
            end
        end

        for _, c in ipairs(workspace:GetChildren()) do
            if c:IsA("Model") then
                tryAddTarget(c)
            end
        end

        local connAdded = workspace.ChildAdded:Connect(function(child)
            if child:IsA("Model") then
                tryAddTarget(child)
            else
                for _, v in ipairs(child:GetChildren()) do
                    if v:IsA("Model") then
                        tryAddTarget(v)
                    end
                end
            end
        end)

        local connRemoved = workspace.ChildRemoved:Connect(function(child)
            if child:IsA("Model") then
                removeTargetModel(child)
            end
        end)

        local validationRunning = true
        task.spawn(function()
            while validationRunning do
                for i = #validTargets, 1, -1 do
                    local part = validTargets[i]
                    if not part or not part.Parent or not part:IsDescendantOf(workspace) then
                        table.remove(validTargets, i)
                    else
                        local hum = part.Parent:FindFirstChildOfClass("Humanoid")
                        if not hum or hum.Health <= 0 then
                            table.remove(validTargets, i)
                        end
                    end
                end
                task.wait(0.25)
            end
        end)

        local success, Drawing = pcall(function() return Drawing end)
        local drawAvailable = success and typeof(Drawing) == "table"
        local aimCircle, targetCircle
        if drawAvailable then
            pcall(function()
                aimCircle = Drawing.new("Circle")
                aimCircle.Visible = false
                aimCircle.Filled = false
                aimCircle.Transparency = 0.8
                aimCircle.Thickness = 1.5
                aimCircle.Radius = vars.CircleSize

                targetCircle = Drawing.new("Circle")
                targetCircle.Visible = false
                targetCircle.Filled = false
                targetCircle.Transparency = 0.95
                targetCircle.Thickness = 2
                targetCircle.Radius = 8
            end)
        end

        local function getClosestTarget()
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local best, bestDist = nil, vars.ScreenTargetRadius
            for _, part in ipairs(validTargets) do
                if part and part.Parent then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local screenPos = Vector2.new(pos.X, pos.Y)
                        local dist = (screenPos - center).Magnitude
                        if dist < bestDist then
                            best = { part = part, screenPos = screenPos, depth = pos.Z }
                            bestDist = dist
                        end
                    end
                end
            end
            return best
        end

        local renderConn
        renderConn = RunService.RenderStepped:Connect(function(dt)
            if not vars.ShowVisualizer then
                if drawAvailable then
                    pcall(function()
                        aimCircle.Visible = false
                        targetCircle.Visible = false
                    end)
                end
                return
            end

            if drawAvailable and vars.ShowCircle then
                pcall(function()
                    local center = Camera.ViewportSize / 2
                    aimCircle.Position = Vector2.new(center.X, center.Y)
                    aimCircle.Radius = vars.CircleSize
                    aimCircle.Color = vars.HighlightColor
                    aimCircle.Visible = true
                end)
            end

            local closest = getClosestTarget()
            if closest and drawAvailable then
                pcall(function()
                    targetCircle.Position = closest.screenPos
                    targetCircle.Visible = true
                    targetCircle.Color = Color3.fromHSV(math.clamp((1 / math.max(closest.depth,1)) * 0.1, 0, 1), 1, 1)
                end)
            else
                if drawAvailable then
                    pcall(function() targetCircle.Visible = false end)
                end
            end

            ------------------------------------------------------------------
            -- 🎯 AIM ASSIST (halus)
            ------------------------------------------------------------------
            if vars.EnableAimAssist and closest then
                local targetPart = closest.part
                if targetPart and targetPart:IsA("BasePart") then
                    local camPos = Camera.CFrame.Position
                    local lookCFrame = CFrame.lookAt(camPos, targetPart.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(lookCFrame, math.clamp(vars.AimSmoothness, 0, 1))
                end
            end
        end)

        local function cleanup()
            validationRunning = false
            if renderConn and renderConn.Connected then pcall(renderConn.Disconnect, renderConn) end
            if connAdded and connAdded.Connected then pcall(connAdded.Disconnect, connAdded) end
            if connRemoved and connRemoved.Connected then pcall(connRemoved.Disconnect, connRemoved) end
            if drawAvailable then
                pcall(function()
                    if aimCircle then aimCircle:Remove() end
                    if targetCircle then targetCircle:Remove() end
                end)
            end
            validTargets = {}
            targetLookup = {}
        end

        vars._VisualizerCleanup = cleanup
        print("✅ [AimAssist] Siap digunakan — Visual + Aim Assist halus aktif.")
    end
}
