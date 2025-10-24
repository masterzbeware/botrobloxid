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

        -- Inisialisasi variabel ESP
        vars.ShowSkeleton = vars.ShowSkeleton or false
        vars.ShowTracer   = vars.ShowTracer or false
        vars.ShowDistance = vars.ShowDistance or false
        vars.ShowBox      = vars.ShowBox or false  -- Toggle untuk Box ESP
        vars.ESPRange     = vars.ESPRange or 500

        local SkeletonColor = Color3.fromRGB(255, 255, 255)
        local TracerColor   = Color3.fromRGB(255, 0, 0)
        local DistanceColor = Color3.fromRGB(255, 255, 255)
        local BoxColor      = Color3.fromRGB(255, 255, 255)  -- Warna putih untuk Box ESP

        local ActiveESP = {}
        local ESPConnection, DescendantConnection

        -- Optimasi: Cache untuk mengurangi pembuatan objek berulang
        local Vector2New = Vector2.new
        local WorldToViewportPoint = Camera.WorldToViewportPoint

        local function updateESPState()
            local anyEnabled = vars.ShowSkeleton or vars.ShowTracer or vars.ShowDistance or vars.ShowBox
            if anyEnabled and not ESPConnection then
                startESP()
            elseif not anyEnabled and ESPConnection then
                stopESP()
            end
        end

        -- Toggle untuk berbagai jenis ESP
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

        -- Toggle baru untuk Box ESP
        Group:AddToggle("ToggleBoxESP", {
            Text = "Tampilkan Box ESP",
            Default = vars.ShowBox,
            Callback = function(v)
                vars.ShowBox = v
                updateESPState()
            end
        })

        Group:AddSlider("ESPRangeSlider", {
            Text = "ESP Range",
            Default = vars.ESPRange,
            Min = 100,
            Max = 2000,
            Rounding = 0,
            Callback = function(v)
                vars.ESPRange = v
            end
        })

        local function isValidNPC(model)
            if not model:IsA("Model") or model.Name ~= "Male" then return false end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return false end
            
            -- Optimasi: Cek AI_ hanya sekali
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

        -- Fungsi untuk membuat drawing objects
        local function newLine(isTracer, isBox)
            local line = Drawing.new("Line")
            if isBox then
                line.Color = BoxColor
            else
                line.Color = isTracer and TracerColor or SkeletonColor
            end
            line.Thickness = isBox and 1.5 or 1.3
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

        -- Fungsi untuk menghapus ESP
        local function removeESP(model)
            local esp = ActiveESP[model]
            if esp then
                for _, l in pairs(esp.Lines) do l:Remove() end
                for _, l in pairs(esp.BoxLines or {}) do l:Remove() end
                esp.Tracer:Remove()
                esp.Text:Remove()
                ActiveESP[model] = nil
            end
        end

        -- Fungsi untuk membuat ESP
        local function createESP(model)
            if ActiveESP[model] or not isValidNPC(model) then return end
            
            local parts = getBodyParts(model)
            local lines = {}
            for _ in pairs(parts) do table.insert(lines, newLine(false)) end
            
            -- Buat garis untuk box ESP (8 garis untuk box 3D)
            local boxLines = {}
            for i = 1, 8 do
                table.insert(boxLines, newLine(false, true))
            end

            local tracer = newLine(true)
            local distanceText = newText()

            ActiveESP[model] = {
                Parts = parts,
                Lines = lines,
                BoxLines = boxLines,
                Tracer = tracer,
                Text = distanceText
            }

            -- Event listeners untuk cleanup
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

        -- Fungsi untuk menghitung bounding box
        local function calculateBoundingBox(parts)
            local minX, minY, minZ = math.huge, math.huge, math.huge
            local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
            
            for _, part in pairs(parts) do
                if part and part:IsA("BasePart") then
                    local cf = part.CFrame
                    local size = part.Size
                    
                    local corners = {
                        cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
                        cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
                        cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
                        cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
                        cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
                        cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
                        cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
                        cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2)
                    }
                    
                    for _, corner in ipairs(corners) do
                        local pos = corner.Position
                        minX = math.min(minX, pos.X)
                        minY = math.min(minY, pos.Y)
                        minZ = math.min(minZ, pos.Z)
                        maxX = math.max(maxX, pos.X)
                        maxY = math.max(maxY, pos.Y)
                        maxZ = math.max(maxZ, pos.Z)
                    end
                end
            end
            
            if minX == math.huge then return nil end
            
            local corners = {
                Vector3.new(minX, minY, minZ),
                Vector3.new(maxX, minY, minZ),
                Vector3.new(maxX, maxY, minZ),
                Vector3.new(minX, maxY, minZ),
                Vector3.new(minX, minY, maxZ),
                Vector3.new(maxX, minY, maxZ),
                Vector3.new(maxX, maxY, maxZ),
                Vector3.new(minX, maxY, maxZ)
            }
            
            return corners
        end

        -- Optimasi: Gunakan delta time untuk mengurangi update frequency
        local lastUpdate = 0
        local UPDATE_INTERVAL = 0.033 -- ~30 FPS

        function startESP()
            clearAllESP()
            
            -- Initial scan untuk NPC yang sudah ada
            for _, obj in ipairs(workspace:GetDescendants()) do
                if isValidNPC(obj) then createESP(obj) end
            end

            -- Optimasi: Gunakan DescendantAdded dengan debounce
            if DescendantConnection then DescendantConnection:Disconnect() end
            DescendantConnection = workspace.DescendantAdded:Connect(function(obj)
                if isValidNPC(obj) then 
                    task.wait(0.1) -- Debounce kecil
                    createESP(obj) 
                end
            end)

            if ESPConnection then ESPConnection:Disconnect() end
            ESPConnection = RunService.RenderStepped:Connect(function(deltaTime)
                lastUpdate = lastUpdate + deltaTime
                if lastUpdate < UPDATE_INTERVAL then return end
                lastUpdate = 0

                if not (vars.ShowSkeleton or vars.ShowTracer or vars.ShowDistance or vars.ShowBox) then
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
                        for _, l in pairs(data.BoxLines) do l.Visible = false end
                        continue
                    end

                    local pos, onScreen = WorldToViewportPoint(Camera, torso.Position)
                    if not onScreen then
                        data.Tracer.Visible = false
                        data.Text.Visible = false
                        for _, l in pairs(data.Lines) do l.Visible = false end
                        for _, l in pairs(data.BoxLines) do l.Visible = false end
                        continue
                    end

                    -- Update Distance Text
                    if vars.ShowDistance then
                        data.Text.Position = Vector2New(pos.X, pos.Y - 25)
                        data.Text.Text = string.format("%.1fm", dist)
                        data.Text.Visible = true
                    else
                        data.Text.Visible = false
                    end

                    -- Update Tracer
                    if vars.ShowTracer then
                        data.Tracer.From = Vector2New(halfX, Camera.ViewportSize.Y)
                        data.Tracer.To = Vector2New(pos.X, pos.Y)
                        data.Tracer.Visible = true
                    else
                        data.Tracer.Visible = false
                    end

                    -- Update Skeleton
                    if vars.ShowSkeleton then
                        local function drawLine(p1, p2, line)
                            if not p1 or not p2 then line.Visible = false return end
                            local p1v, on1 = WorldToViewportPoint(Camera, p1.Position)
                            local p2v, on2 = WorldToViewportPoint(Camera, p2.Position)
                            line.From = Vector2New(p1v.X, p1v.Y)
                            line.To = Vector2New(p2v.X, p2v.Y)
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

                    -- Update Box ESP
                    if vars.ShowBox then
                        local corners = calculateBoundingBox(data.Parts)
                        if corners then
                            local screenCorners = {}
                            local anyOnScreen = false
                            
                            -- Convert 3D corners ke 2D screen points
                            for i, corner in ipairs(corners) do
                                local screenPos, onScreen = WorldToViewportPoint(Camera, corner)
                                screenCorners[i] = Vector2New(screenPos.X, screenPos.Y)
                                if onScreen then anyOnScreen = true end
                            end
                            
                            if anyOnScreen then
                                -- Draw box edges
                                local connections = {
                                    {1,2}, {2,3}, {3,4}, {4,1}, -- Front face
                                    {5,6}, {6,7}, {7,8}, {8,5}, -- Back face
                                    {1,5}, {2,6}, {3,7}, {4,8}  -- Connecting edges
                                }
                                
                                for i, conn in ipairs(connections) do
                                    local line = data.BoxLines[i]
                                    if line then
                                        line.From = screenCorners[conn[1]]
                                        line.To = screenCorners[conn[2]]
                                        line.Visible = true
                                    end
                                end
                            else
                                for _, l in pairs(data.BoxLines) do l.Visible = false end
                            end
                        else
                            for _, l in pairs(data.BoxLines) do l.Visible = false end
                        end
                    else
                        for _, l in pairs(data.BoxLines) do l.Visible = false end
                    end
                end
            end)
        end

        function stopESP()
            if ESPConnection then ESPConnection:Disconnect(); ESPConnection = nil end
            if DescendantConnection then DescendantConnection:Disconnect(); DescendantConnection = nil end
            clearAllESP()
        end

        updateESPState()
        print("[ESP] Toggle siap di VisualTab - Box ESP ditambahkan!")
    end
}