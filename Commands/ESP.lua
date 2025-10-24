return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local VisualTab = tab or Tabs.Visual

        if not VisualTab then
            warn("[ESP] Tab Visual tidak ditemukan!")
            return
        end

        local Group = VisualTab:AddLeftGroupbox("ESP Control")
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera

        vars.ShowSkeleton = vars.ShowSkeleton or false
        vars.ShowTracer   = vars.ShowTracer or false
        vars.ShowDistance = vars.ShowDistance or false
        vars.ESPRange     = vars.ESPRange or 500

        local SkeletonColor = Color3.fromRGB(255, 255, 255)
        local TracerColor   = Color3.fromRGB(255, 0, 0)
        local DistanceColor = Color3.fromRGB(255, 255, 255)

        local ActiveESP = {}
        local ESPConnection, DescendantConnection

        -- Bagian depan deklarasi biar bisa dipanggil di mana pun
        local startESP, stopESP

        -- Utility: cek NPC valid
        local function isValidNPC(model)
            if not model:IsA("Model") or model.Name ~= "Male" then return false end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return false end
            for _, c in ipairs(model:GetChildren()) do
                if c.Name:sub(1, 3) == "AI_" then
                    return true
                end
            end
            return false
        end

        -- Bagian skeleton
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

        -- Fungsi membuat Drawing
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

        local function removeESP(model)
            local esp = ActiveESP[model]
            if esp then
                for _, l in pairs(esp.Lines) do
                    pcall(function() l:Remove() end)
                end
                pcall(function() esp.Tracer:Remove() end)
                pcall(function() esp.Text:Remove() end)
                ActiveESP[model] = nil
            end
        end

        local function clearAllESP()
            for model in pairs(ActiveESP) do
                removeESP(model)
            end
        end

        local function createESP(model)
            if ActiveESP[model] or not isValidNPC(model) then return end

            local parts = getBodyParts(model)
            local lines = {}
            for i = 1, 14 do
                table.insert(lines, newLine(false))
            end

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

        -- Jalankan dan hentikan ESP
        startESP = function()
            clearAllESP()
            for _, obj in ipairs(workspace:GetChildren()) do
                if isValidNPC(obj) then
                    createESP(obj)
                end
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
                local halfX, halfY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2

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
                        local function drawLine(p1, p2, line)
                            if not p1 or not p2 then line.Visible = false return end
                            local p1v, on1 = Camera:WorldToViewportPoint(p1.Position)
                            local p2v, on2 = Camera:WorldToViewportPoint(p2.Position)
                            line.From = Vector2.new(p1v.X, p1v.Y)
                            line.To = Vector2.new(p2v.X, p2v.Y)
                            line.Visible = (on1 or on2)
                        end

                        local p = data.Parts
                        local L = data.Lines
                        local i = 1

                        drawLine(p.Head, p.UpperTorso, L[i]); i+=1
                        drawLine(p.UpperTorso, p.LowerTorso, L[i]); i+=1
                        drawLine(p.UpperTorso, p.LeftUpperArm, L[i]); i+=1
                        drawLine(p.LeftUpperArm, p.LeftLowerArm, L[i]); i+=1
                        drawLine(p.LeftLowerArm, p.LeftHand, L[i]); i+=1
                        drawLine(p.UpperTorso, p.RightUpperArm, L[i]); i+=1
                        drawLine(p.RightUpperArm, p.RightLowerArm, L[i]); i+=1
                        drawLine(p.RightLowerArm, p.RightHand, L[i]); i+=1
                        drawLine(p.LowerTorso, p.LeftUpperLeg, L[i]); i+=1
                        drawLine(p.LeftUpperLeg, p.LeftLowerLeg, L[i]); i+=1
                        drawLine(p.LeftLowerLeg, p.LeftFoot, L[i]); i+=1
                        drawLine(p.LowerTorso, p.RightUpperLeg, L[i]); i+=1
                        drawLine(p.RightUpperLeg, p.RightLowerLeg, L[i]); i+=1
                        drawLine(p.RightLowerLeg, p.RightFoot, L[i])
                    else
                        for _, l in pairs(data.Lines) do l.Visible = false end
                    end
                end
            end)
        end

        stopESP = function()
            if ESPConnection then ESPConnection:Disconnect(); ESPConnection = nil end
            if DescendantConnection then DescendantConnection:Disconnect(); DescendantConnection = nil end
            clearAllESP()
        end

        -- UI Controls
        local function updateESPState()
            local anyEnabled = vars.ShowSkeleton or vars.ShowTracer or vars.ShowDistance
            if anyEnabled and not ESPConnection then
                startESP()
            elseif not anyEnabled and ESPConnection then
                stopESP()
            end
        end

        Group:AddToggle("SkeletonESP", { Text = "Tampilkan Skeleton", Default = vars.ShowSkeleton, Callback = function(v)
            vars.ShowSkeleton = v
            updateESPState()
        end })

        Group:AddToggle("TracerESP", { Text = "Tampilkan Tracer", Default = vars.ShowTracer, Callback = function(v)
            vars.ShowTracer = v
            updateESPState()
        end })

        Group:AddToggle("DistanceESP", { Text = "Tampilkan Distance", Default = vars.ShowDistance, Callback = function(v)
            vars.ShowDistance = v
            updateESPState()
        end })

        Group:AddSlider("ESPRange", { Text = "ESP Range", Default = vars.ESPRange, Min = 100, Max = 2000, Rounding = 0, Callback = function(v)
            vars.ESPRange = v
        end })

        updateESPState()
        print("[ESP] Toggle siap di VisualTab")
    end
}
