-- ESP.lua
-- ESP Skeleton + Tracer + Distance untuk semua AI_ (Male NPC)
-- Otomatis aktif saat salah satu toggle (Skeleton / Tracer / Distance) diaktifkan

return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local VisualTab = tab or Tabs.Visual

        if not VisualTab then
            warn("[ESP] Tab Visual tidak ditemukan! Pastikan WindowTab.lua sudah dijalankan.")
            return
        end

        local Group = VisualTab:AddLeftGroupbox("ESP Control")

        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera

        -- Default settings
        vars.ShowSkeleton = vars.ShowSkeleton or false
        vars.ShowTracer   = vars.ShowTracer or false
        vars.ShowDistance = vars.ShowDistance or false
        vars.ESPRange     = vars.ESPRange or 500

        -- Colors
        local SkeletonColor = Color3.fromRGB(255, 255, 255)
        local TracerColor   = Color3.fromRGB(255, 0, 0)
        local DistanceColor = Color3.fromRGB(255, 255, 255)

        local ActiveESP = {}
        local ESPConnection, DescendantConnection

        ---------------------------
        -- === UI CONTROLS === --
        ---------------------------

        local function updateESPState()
            local anyEnabled = vars.ShowSkeleton or vars.ShowTracer or vars.ShowDistance
            if anyEnabled and not ESPConnection then
                startESP()
            elseif not anyEnabled and ESPConnection then
                stopESP()
            end
        end

        Group:AddToggle("ToggleSkeletonESP", {
            Text = "Tampilkan Skeleton",
            Default = vars.ShowSkeleton,
            Callback = function(v)
                vars.ShowSkeleton = v
                updateESPState()
            end
        })

        Group:AddToggle("ToggleTracerESP", {
            Text = "Tampilkan Tracer",
            Default = vars.ShowTracer,
            Callback = function(v)
                vars.ShowTracer = v
                updateESPState()
            end
        })

        Group:AddToggle("ToggleDistanceESP", {
            Text = "Tampilkan Distance",
            Default = vars.ShowDistance,
            Callback = function(v)
                vars.ShowDistance = v
                updateESPState()
            end
        })

        Group:AddSlider("ESPRangeSlider", {
            Text = "ESP Range (jarak maksimum)",
            Default = vars.ESPRange,
            Min = 100,
            Max = 2000,
            Rounding = 0,
            Callback = function(v)
                vars.ESPRange = v
            end
        })

        -----------------------------------
        -- === VALIDATION / BODY PARTS === --
        -----------------------------------

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

        local partNames = {
            "Head","UpperTorso","LowerTorso",
            "LeftUpperArm","LeftLowerArm","LeftHand",
            "RightUpperArm","RightLowerArm","RightHand",
            "LeftUpperLeg","LeftLowerLeg","LeftFoot",
            "RightUpperLeg","RightLowerLeg","RightFoot"
        }

        local function getBodyParts(model)
            local parts = {}
            for _, name in ipairs(partNames) do
                local p = model:FindFirstChild(name)
                if p and p:IsA("BasePart") then
                    parts[name] = p
                end
            end
            return parts
        end

        ------------------------
        -- === DRAW HELPERS === --
        ------------------------

        local function newLine(isTracer)
            local line = Drawing.new("Line")
            line.Color = isTracer and TracerColor or SkeletonColor
            line.Thickness = 1.3
            line.Transparency = 1
            line.Visible = false
            return line
        end

        local function newText()
            local text = Drawing.new("Text")
            text.Color = DistanceColor
            text.Size = 14
            text.Center = true
            text.Outline = true
            text.Visible = false
            return text
        end

        ---------------------------------
        -- === ESP CREATION / REMOVAL === --
        ---------------------------------

        local function removeESP(model)
            local esp = ActiveESP[model]
            if esp then
                for _, l in pairs(esp.Lines) do l:Remove() end
                esp.Tracer:Remove()
                esp.Text:Remove()
                ActiveESP[model] = nil
            end
        end

        local function createESP(model)
            if ActiveESP[model] or not isValidNPC(model) then return end
            local parts = getBodyParts(model)
            local lines = {}
            for _ in pairs(parts) do table.insert(lines, newLine(false)) end
            local tracer = newLine(true)
            local distanceText = newText()

            ActiveESP[model] = {
                Parts = parts,
                Lines = lines,
                Tracer = tracer,
                Text = distanceText
            }

            model.AncestryChanged:Connect(function(_, parent)
                if not parent then removeESP(model) end
            end)
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Died:Connect(function() removeESP(model) end)
            end
        end

        local function clearAllESP()
            for model in pairs(ActiveESP) do
                removeESP(model)
            end
        end

        ------------------------------------
        -- === MAIN UPDATE LOOP (LIVE) === --
        ------------------------------------

        function startESP()
            clearAllESP()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if isValidNPC(obj) then createESP(obj) end
            end

            if DescendantConnection then DescendantConnection:Disconnect() end
            DescendantConnection = workspace.DescendantAdded:Connect(function(obj)
                if isValidNPC(obj) then createESP(obj) end
            end)

            if ESPConnection then ESPConnection:Disconnect() end
            ESPConnection = RunService.RenderStepped:Connect(function()
                if not (vars.ShowSkeleton or vars.ShowTracer or vars.ShowDistance) then
                    stopESP()
                    return
                end

                local camPos = Camera.CFrame.Position
                local halfX, halfY = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2

                for model, data in pairs(ActiveESP) do
                    if not isValidNPC(model) then
                        removeESP(model)
                        continue
                    end

                    local torso = data.Parts.UpperTorso or data.Parts.LowerTorso
                    if not torso then continue end
                    local dist = (torso.Position - camPos).Magnitude

                    if dist > vars.ESPRange then
                        data.Tracer.Visible = false
                        data.Text.Visible = false
                        for _, l in pairs(data.Lines) do l.Visible = false end
                        continue
                    end

                    local pos, onScreen = Camera:WorldToViewportPoint(torso.Position)
                    if not onScreen then
                        data.Tracer.Visible = false
                        data.Text.Visible = false
                        for _, l in pairs(data.Lines) do l.Visible = false end
                        continue
                    end

                    -- Distance
                    if vars.ShowDistance then
                        data.Text.Position = Vector2.new(pos.X, pos.Y - 25)
                        data.Text.Text = string.format("%.1fm", dist)
                        data.Text.Visible = true
                    else
                        data.Text.Visible = false
                    end

                    -- Tracer
                    if vars.ShowTracer then
                        data.Tracer.From = Vector2.new(halfX, Camera.ViewportSize.Y)
                        data.Tracer.To = Vector2.new(pos.X, pos.Y)
                        data.Tracer.Visible = true
                    else
                        data.Tracer.Visible = false
                    end

                    -- Skeleton
                    if vars.ShowSkeleton then
                        local function drawLine(p1,p2,line)
                            if not p1 or not p2 then line.Visible = false return end
                            local p1v, on1 = Camera:WorldToViewportPoint(p1.Position)
                            local p2v, on2 = Camera:WorldToViewportPoint(p2.Position)
                            line.From = Vector2.new(p1v.X, p1v.Y)
                            line.To = Vector2.new(p2v.X, p2v.Y)
                            line.Visible = on1 or on2
                        end

                        local i = 1
                        drawLine(data.Parts.Head, data.Parts.UpperTorso, data.Lines[i]); i += 1
                        drawLine(data.Parts.UpperTorso, data.Parts.LowerTorso, data.Lines[i]); i += 1
                        drawLine(data.Parts.UpperTorso, data.Parts.LeftUpperArm, data.Lines[i]); i += 1
                        drawLine(data.Parts.LeftUpperArm, data.Parts.LeftLowerArm, data.Lines[i]); i += 1
                        drawLine(data.Parts.LeftLowerArm, data.Parts.LeftHand, data.Lines[i]); i += 1
                        drawLine(data.Parts.UpperTorso, data.Parts.RightUpperArm, data.Lines[i]); i += 1
                        drawLine(data.Parts.RightUpperArm, data.Parts.RightLowerArm, data.Lines[i]); i += 1
                        drawLine(data.Parts.RightLowerArm, data.Parts.RightHand, data.Lines[i]); i += 1
                        drawLine(data.Parts.LowerTorso, data.Parts.LeftUpperLeg, data.Lines[i]); i += 1
                        drawLine(data.Parts.LeftUpperLeg, data.Parts.LeftLowerLeg, data.Lines[i]); i += 1
                        drawLine(data.Parts.LeftLowerLeg, data.Parts.LeftFoot, data.Lines[i]); i += 1
                        drawLine(data.Parts.LowerTorso, data.Parts.RightUpperLeg, data.Lines[i]); i += 1
                        drawLine(data.Parts.RightUpperLeg, data.Parts.RightLowerLeg, data.Lines[i]); i += 1
                        drawLine(data.Parts.RightLowerLeg, data.Parts.RightFoot, data.Lines[i])
                    else
                        for _, l in pairs(data.Lines) do l.Visible = false end
                    end
                end
            end)
        end

        function stopESP()
            if ESPConnection then ESPConnection:Disconnect(); ESPConnection = nil end
            if DescendantConnection then DescendantConnection:Disconnect(); DescendantConnection = nil end
            clearAllESP()
        end

        -- Cek awal jika user sudah nyalakan toggle sebelumnya
        updateESPState()

        print("✅ [ESP] Siap — aktif otomatis saat salah satu toggle dinyalakan.")
    end
}
