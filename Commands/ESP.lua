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
        vars.ShowWeapon   = vars.ShowWeapon or false  -- Fitur baru: tampilkan senjata
        vars.ESPRange     = vars.ESPRange or 500

        local SkeletonColor = Color3.fromRGB(255, 255, 255)
        local TracerColor   = Color3.fromRGB(255, 0, 0)
        local DistanceColor = Color3.fromRGB(255, 255, 255)
        local WeaponColor   = Color3.fromRGB(0, 255, 0)  -- Warna hijau untuk teks senjata

        local ActiveESP = {}
        local ESPConnection, DescendantConnection

        local function updateESPState()
            local anyEnabled = vars.ShowSkeleton or vars.ShowTracer or vars.ShowDistance or vars.ShowWeapon
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

        -- Toggle baru untuk menampilkan senjata
        Group:AddToggle("ToggleWeaponESP", {
            Text = "Tampilkan Senjata",
            Default = vars.ShowWeapon,
            Callback = function(v)
                vars.ShowWeapon = v
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
            for _, c in ipairs(model:GetChildren()) do
                if string.sub(c.Name, 1, 3) == "AI_" then
                    return true
                end
            end
            return false
        end

        -- Fungsi baru untuk mendapatkan nama senjata dari NPC
        local function getWeaponName(model)
            for _, child in ipairs(model:GetChildren()) do
                -- Cek jika ada senjata dengan awalan AI_
                if string.sub(child.Name, 1, 3) == "AI_" then
                    local weaponName = child.Name
                    -- Hapus awalan "AI_" untuk tampilan yang lebih bersih
                    if string.sub(weaponName, 1, 3) == "AI_" then
                        weaponName = string.sub(weaponName, 4)
                    end
                    return weaponName
                end
            end
            return "Unknown"
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

        local function newLine(isTracer)
            local line = Drawing.new("Line")
            line.Color = isTracer and TracerColor or SkeletonColor
            line.Thickness = 1.3
            line.Transparency = 1
            line.Visible = false
            return line
        end

        local function newText(isWeaponText)
            local text = Drawing.new("Text")
            text.Color = isWeaponText and WeaponColor or DistanceColor
            text.Size = isWeaponText and 12 or 14  -- Ukuran lebih kecil untuk teks senjata
            text.Center = true
            text.Outline = true
            text.Visible = false
            return text
        end

        local function removeESP(model)
            local esp = ActiveESP[model]
            if esp then
                for _, l in pairs(esp.Lines) do l:Remove() end
                esp.Tracer:Remove()
                esp.DistanceText:Remove()
                if esp.WeaponText then
                    esp.WeaponText:Remove()
                end
                ActiveESP[model] = nil
            end
        end

        local function createESP(model)
            if ActiveESP[model] or not isValidNPC(model) then return end
            local parts = getBodyParts(model)
            local lines = {}
            for _ in pairs(parts) do table.insert(lines, newLine(false)) end
            local tracer = newLine(true)
            local distanceText = newText(false)
            local weaponText = newText(true)  -- Teks khusus untuk senjata

            ActiveESP[model] = {
                Parts = parts,
                Lines = lines,
                Tracer = tracer,
                DistanceText = distanceText,
                WeaponText = weaponText,
                WeaponName = getWeaponName(model)  -- Simpan nama senjata
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
                if not (vars.ShowSkeleton or vars.ShowTracer or vars.ShowDistance or vars.ShowWeapon) then
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
                        data.DistanceText.Visible = false
                        if data.WeaponText then
                            data.WeaponText.Visible = false
                        end
                        for _, l in pairs(data.Lines) do l.Visible = false end
                        continue
                    end

                    local pos, onScreen = Camera:WorldToViewportPoint(torso.Position)
                    if not onScreen then
                        data.Tracer.Visible = false
                        data.DistanceText.Visible = false
                        if data.WeaponText then
                            data.WeaponText.Visible = false
                        end
                        for _, l in pairs(data.Lines) do l.Visible = false end
                        continue
                    end

                    -- Update teks jarak
                    if vars.ShowDistance then
                        data.DistanceText.Position = Vector2.new(pos.X, pos.Y - 25)
                        data.DistanceText.Text = string.format("%.1fm", dist)
                        data.DistanceText.Visible = true
                    else
                        data.DistanceText.Visible = false
                    end

                    -- Update teks senjata (FITUR BARU)
                    if vars.ShowWeapon and data.WeaponText then
                        data.WeaponText.Position = Vector2.new(pos.X, pos.Y - 40)  -- Posisi di bawah teks jarak
                        data.WeaponText.Text = data.WeaponName
                        data.WeaponText.Visible = true
                    elseif data.WeaponText then
                        data.WeaponText.Visible = false
                    end

                    if vars.ShowTracer then
                        data.Tracer.From = Vector2.new(halfX, Camera.ViewportSize.Y)
                        data.Tracer.To = Vector2.new(pos.X, pos.Y)
                        data.Tracer.Visible = true
                    else
                        data.Tracer.Visible = false
                    end

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

        updateESPState()
        print("[ESP] Toggle siap di VisualTab - Fitur senjata ditambahkan!")
    end
}