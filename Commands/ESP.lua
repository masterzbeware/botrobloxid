-- ESP.lua
-- ESP khusus untuk NPC dengan bagian AI_ (skeleton + tracer + darah real-time)

return {
    Execute = function()
        local vars = _G.BotVars
        local Window = vars.MainWindow

        -- UI Tab
        local Tabs = {
            ESP = Window:AddTab("ESP", "eye"),
        }

        local Group = Tabs.ESP:AddLeftGroupbox("ESP Control")

        -- Services
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera

        -- Warna
        local ESPColor = Color3.fromRGB(255, 255, 255)
        local HPColor = Color3.fromRGB(255, 60, 60) -- merah untuk darah

        local ActiveESP = {}

        -- Validasi NPC Male dengan AI_
        local function isValidNPC(model)
            if not model:IsA("Model") or model.Name ~= "Male" then return false end
            if not model:FindFirstChildOfClass("Humanoid") then return false end
            for _, c in ipairs(model:GetChildren()) do
                if string.sub(c.Name, 1, 3) == "AI_" then
                    return true
                end
            end
            return false
        end

        -- Ambil bagian tubuh
        local function getBodyParts(model)
            local parts = {}
            for _, partName in ipairs({
                "Head", "UpperTorso", "LowerTorso",
                "LeftUpperArm", "LeftLowerArm", "LeftHand",
                "RightUpperArm", "RightLowerArm", "RightHand",
                "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
                "RightUpperLeg", "RightLowerLeg", "RightFoot"
            }) do
                local part = model:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    parts[partName] = part
                end
            end
            return parts
        end

        -- Drawing helper
        local function newLine()
            local line = Drawing.new("Line")
            line.Color = ESPColor
            line.Thickness = 1.2
            line.Transparency = 1
            line.Visible = true
            return line
        end

        local function newText(color)
            local text = Drawing.new("Text")
            text.Color = color or ESPColor
            text.Size = 14
            text.Center = true
            text.Outline = true
            text.Visible = true
            return text
        end

        -- Buat ESP untuk NPC
        local function createESP(model)
            if ActiveESP[model] or not isValidNPC(model) then return end

            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local parts = getBodyParts(model)

            local lines = {}
            for _, _ in pairs(parts) do
                table.insert(lines, newLine())
            end

            local tracer = newLine()
            local hpText = newText(HPColor)

            ActiveESP[model] = {
                Lines = lines,
                Tracer = tracer,
                HP = hpText,
                Parts = parts,
                Humanoid = humanoid,
            }

            -- Update darah realtime
            if humanoid then
                humanoid.HealthChanged:Connect(function(newHP)
                    if ActiveESP[model] and ActiveESP[model].HP then
                        ActiveESP[model].HP.Text = string.format("HP: %.0f", newHP)
                        ActiveESP[model].HP.Visible = newHP > 0
                    end
                end)
            end

            -- Hapus saat NPC hilang
            model.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    if ActiveESP[model] then
                        for _, obj in pairs(ActiveESP[model].Lines) do obj:Remove() end
                        ActiveESP[model].Tracer:Remove()
                        ActiveESP[model].HP:Remove()
                        ActiveESP[model] = nil
                    end
                end
            end)
        end

        -- Bersihkan semua ESP
        local function clearAllESP()
            for _, data in pairs(ActiveESP) do
                for _, obj in pairs(data.Lines) do obj:Remove() end
                data.Tracer:Remove()
                data.HP:Remove()
            end
            ActiveESP = {}
        end

        -- Jalankan ESP
        local function startESP()
            print("[ESP] Sistem ESP + HP aktif ✅")

            for _, obj in ipairs(workspace:GetDescendants()) do
                if isValidNPC(obj) then
                    createESP(obj)
                end
            end

            -- Update skeleton & tracer statis
            RunService.RenderStepped:Connect(function()
                for model, data in pairs(ActiveESP) do
                    if not (model and model.Parent) then continue end
                    local parts = data.Parts

                    -- Tracer dari bawah layar ke torso
                    local torso = parts.UpperTorso or parts.LowerTorso
                    if torso then
                        local pos, onScreen = Camera:WorldToViewportPoint(torso.Position)
                        if onScreen then
                            data.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                            data.Tracer.To = Vector2.new(pos.X, pos.Y)
                            data.Tracer.Visible = true
                        else
                            data.Tracer.Visible = false
                        end
                    end

                    -- Skeleton lines (tidak berubah)
                    local function drawLine(part1, part2, line)
                        if part1 and part2 then
                            local p1, on1 = Camera:WorldToViewportPoint(part1.Position)
                            local p2, on2 = Camera:WorldToViewportPoint(part2.Position)
                            if on1 or on2 then
                                line.From = Vector2.new(p1.X, p1.Y)
                                line.To = Vector2.new(p2.X, p2.Y)
                                line.Visible = true
                            else
                                line.Visible = false
                            end
                        else
                            line.Visible = false
                        end
                    end

                    local i = 1
                    drawLine(parts.Head, parts.UpperTorso, data.Lines[i]); i+=1
                    drawLine(parts.UpperTorso, parts.LowerTorso, data.Lines[i]); i+=1
                    drawLine(parts.UpperTorso, parts.LeftUpperArm, data.Lines[i]); i+=1
                    drawLine(parts.LeftUpperArm, parts.LeftLowerArm, data.Lines[i]); i+=1
                    drawLine(parts.LeftLowerArm, parts.LeftHand, data.Lines[i]); i+=1
                    drawLine(parts.UpperTorso, parts.RightUpperArm, data.Lines[i]); i+=1
                    drawLine(parts.RightUpperArm, parts.RightLowerArm, data.Lines[i]); i+=1
                    drawLine(parts.RightLowerArm, parts.RightHand, data.Lines[i]); i+=1
                    drawLine(parts.LowerTorso, parts.LeftUpperLeg, data.Lines[i]); i+=1
                    drawLine(parts.LeftUpperLeg, parts.LeftLowerLeg, data.Lines[i]); i+=1
                    drawLine(parts.LeftLowerLeg, parts.LeftFoot, data.Lines[i]); i+=1
                    drawLine(parts.LowerTorso, parts.RightUpperLeg, data.Lines[i]); i+=1
                    drawLine(parts.RightUpperLeg, parts.RightLowerLeg, data.Lines[i]); i+=1
                    drawLine(parts.RightLowerLeg, parts.RightFoot, data.Lines[i])
                end
            end)

            workspace.DescendantAdded:Connect(function(obj)
                if isValidNPC(obj) then
                    createESP(obj)
                end
            end)
        end

        -- Toggle UI
        Group:AddToggle("EnableESPSystem", {
            Text = "Aktifkan ESP Skeleton (AI_)",
            Default = false,
            Callback = function(Value)
                vars.ToggleESP = Value
                if Value then startESP() else clearAllESP() end
            end
        })

        print("✅ ESP.lua loaded — skeleton statis + darah update realtime")
    end
}
