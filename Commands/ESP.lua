-- ESP.lua
-- ESP khusus untuk NPC dengan bagian AI_ (skeleton + tracer + jarak meter putih)

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
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera
        local LocalPlayer = Players.LocalPlayer

        -- Konfigurasi Warna
        local ESPColor = Color3.fromRGB(255, 255, 255)

        -- Variabel
        local ActiveESP = {}
        local ESPConnection, DescendantConnection

        -- 🔎 Validasi NPC “Male” dengan komponen “AI_”
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

        -- 🧍 Ambil posisi semua bagian tubuh untuk skeleton
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

        -- 🔗 Skeleton line helper
        local function newLine()
            local line = Drawing.new("Line")
            line.Color = ESPColor
            line.Thickness = 1.2
            line.Transparency = 1
            line.Visible = false
            return line
        end

        -- 🏷️ Distance text
        local function newText()
            local text = Drawing.new("Text")
            text.Color = ESPColor
            text.Size = 14
            text.Center = true
            text.Outline = true
            text.Visible = false
            return text
        end

        -- 🧩 Buat struktur ESP untuk NPC
        local function createESP(model)
            if ActiveESP[model] or not isValidNPC(model) then return end

            local parts = getBodyParts(model)
            local lines = {}
            for _, _ in pairs(parts) do
                table.insert(lines, newLine())
            end
            local tracer = newLine()
            local distanceText = newText()

            ActiveESP[model] = {
                Lines = lines,
                Tracer = tracer,
                Text = distanceText,
                Parts = parts,
            }

            model.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    if ActiveESP[model] then
                        for _, obj in pairs(ActiveESP[model].Lines) do obj:Remove() end
                        ActiveESP[model].Tracer:Remove()
                        ActiveESP[model].Text:Remove()
                        ActiveESP[model] = nil
                    end
                end
            end)
        end

        -- 🧹 Bersihkan semua ESP
        local function clearAllESP()
            for _, data in pairs(ActiveESP) do
                for _, obj in pairs(data.Lines) do obj:Remove() end
                data.Tracer:Remove()
                data.Text:Remove()
            end
            ActiveESP = {}
        end

        -- 🚀 Jalankan ESP
        local function startESP()
            print("[ESP] Sistem ESP Skeleton aktif ✅")

            for _, obj in ipairs(workspace:GetDescendants()) do
                if isValidNPC(obj) then
                    createESP(obj)
                end
            end

            -- Update terus menerus
            ESPConnection = RunService.RenderStepped:Connect(function()
                for model, data in pairs(ActiveESP) do
                    if not (model and model.Parent) then continue end
                    local parts = data.Parts
                    local tracer = data.Tracer
                    local text = data.Text

                    -- 📏 Hitung jarak dan posisi
                    local torso = parts.UpperTorso or parts.LowerTorso
                    if torso then
                        local pos, onScreen = Camera:WorldToViewportPoint(torso.Position)
                        if onScreen then
                            local distance = (Camera.CFrame.Position - torso.Position).Magnitude
                            text.Position = Vector2.new(pos.X, pos.Y - 25)
                            text.Text = string.format("%.1fm", distance)
                            text.Visible = true

                            tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            tracer.To = Vector2.new(pos.X, pos.Y)
                            tracer.Visible = true
                        else
                            text.Visible = false
                            tracer.Visible = false
                        end
                    end

                    -- 🔩 Update skeleton line (contoh: kepala ke torso, tangan, kaki)
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
                    drawLine(parts.Head, parts.UpperTorso, data.Lines[i]); i += 1
                    drawLine(parts.UpperTorso, parts.LowerTorso, data.Lines[i]); i += 1
                    drawLine(parts.UpperTorso, parts.LeftUpperArm, data.Lines[i]); i += 1
                    drawLine(parts.LeftUpperArm, parts.LeftLowerArm, data.Lines[i]); i += 1
                    drawLine(parts.LeftLowerArm, parts.LeftHand, data.Lines[i]); i += 1
                    drawLine(parts.UpperTorso, parts.RightUpperArm, data.Lines[i]); i += 1
                    drawLine(parts.RightUpperArm, parts.RightLowerArm, data.Lines[i]); i += 1
                    drawLine(parts.RightLowerArm, parts.RightHand, data.Lines[i]); i += 1
                    drawLine(parts.LowerTorso, parts.LeftUpperLeg, data.Lines[i]); i += 1
                    drawLine(parts.LeftUpperLeg, parts.LeftLowerLeg, data.Lines[i]); i += 1
                    drawLine(parts.LeftLowerLeg, parts.LeftFoot, data.Lines[i]); i += 1
                    drawLine(parts.LowerTorso, parts.RightUpperLeg, data.Lines[i]); i += 1
                    drawLine(parts.RightUpperLeg, parts.RightLowerLeg, data.Lines[i]); i += 1
                    drawLine(parts.RightLowerLeg, parts.RightFoot, data.Lines[i])
                end
            end)

            DescendantConnection = workspace.DescendantAdded:Connect(function(obj)
                if isValidNPC(obj) then
                    createESP(obj)
                end
            end)
        end

        -- 🚫 Matikan ESP
        local function stopESP()
            print("[ESP] Sistem ESP dimatikan ❌")
            if ESPConnection then ESPConnection:Disconnect() ESPConnection = nil end
            if DescendantConnection then DescendantConnection:Disconnect() DescendantConnection = nil end
            clearAllESP()
        end

        -- UI Toggle
        Group:AddToggle("EnableESPSystem", {
            Text = "Aktifkan ESP Skeleton (AI_)",
            Default = false,
            Callback = function(Value)
                vars.ToggleESP = Value
                if Value then startESP() else stopESP() end
            end
        })

        print("✅ ESP.lua loaded — hanya untuk NPC dengan AI_, warna putih & tampil jarak")
    end
}
