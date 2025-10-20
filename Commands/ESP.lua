-- ESP.lua
-- ✨ ESP Otomatis + Skeleton Stickman untuk Model bernama "Male"

return {
    Execute = function()
        local vars = _G.BotVars
        local Window = vars.MainWindow

        -- UI
        local Tabs = {
            ESP = Window:AddTab("ESP", "eye"),
        }

        local Group = Tabs.ESP:AddLeftGroupbox("ESP Control")

        -- Variabel
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera
        local LocalPlayer = Players.LocalPlayer
        local ESPColor = Color3.fromRGB(0, 255, 0)
        local ActiveESP = {}
        local ESPConnection, DescendantConnection

        -- Validasi model NPC
        local function isValidMale(model)
            if not model:IsA("Model") or model.Name ~= "Male" then return false end
            if not model:FindFirstChildOfClass("Humanoid") then return false end
            for _, c in ipairs(model:GetChildren()) do
                if string.sub(c.Name, 1, 3) == "AI_" then
                    return true
                end
            end
            return false
        end

        -- Ambil part utama dari model
        local function getPart(model, name)
            return model:FindFirstChild(name)
        end

        -- Buat garis baru
        local function newLine()
            local l = Drawing.new("Line")
            l.Color = ESPColor
            l.Thickness = 1.5
            l.Transparency = 1
            return l
        end

        -- Buat skeleton (stickman)
        local function createSkeleton(model)
            if ActiveESP[model] then return end
            if not isValidMale(model) then return end

            local skeleton = {
                Head = newLine(),
                Torso = newLine(),
                LeftArm = newLine(),
                RightArm = newLine(),
                LeftLeg = newLine(),
                RightLeg = newLine(),
            }
            ActiveESP[model] = skeleton

            model.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    for _, line in pairs(skeleton) do
                        if line then line.Visible = false line:Remove() end
                    end
                    ActiveESP[model] = nil
                end
            end)
        end

        -- Hapus semua ESP
        local function clearAllESP()
            for _, skeleton in pairs(ActiveESP) do
                for _, line in pairs(skeleton) do
                    line.Visible = false
                    line:Remove()
                end
            end
            ActiveESP = {}
        end

        -- Jalankan ESP
        local function startESP()
            print("[ESP] Sistem ESP aktif ✅")

            for _, obj in ipairs(workspace:GetDescendants()) do
                if isValidMale(obj) then
                    createSkeleton(obj)
                end
            end

            ESPConnection = RunService.RenderStepped:Connect(function()
                for model, skeleton in pairs(ActiveESP) do
                    if not model or not model.Parent then
                        for _, l in pairs(skeleton) do l.Visible = false end
                        continue
                    end

                    local parts = {
                        Head = getPart(model, "Head"),
                        UpperTorso = getPart(model, "UpperTorso"),
                        LowerTorso = getPart(model, "LowerTorso"),
                        LeftUpperArm = getPart(model, "LeftUpperArm"),
                        LeftLowerArm = getPart(model, "LeftLowerArm"),
                        RightUpperArm = getPart(model, "RightUpperArm"),
                        RightLowerArm = getPart(model, "RightLowerArm"),
                        LeftUpperLeg = getPart(model, "LeftUpperLeg"),
                        LeftLowerLeg = getPart(model, "LeftLowerLeg"),
                        RightUpperLeg = getPart(model, "RightUpperLeg"),
                        RightLowerLeg = getPart(model, "RightLowerLeg"),
                    }

                    -- Konversi ke 2D
                    local function to2D(part)
                        if not part then return nil end
                        local pos, visible = Camera:WorldToViewportPoint(part.Position)
                        if visible then
                            return Vector2.new(pos.X, pos.Y)
                        end
                        return nil
                    end

                    local head2D = to2D(parts.Head)
                    local torsoU2D = to2D(parts.UpperTorso)
                    local torsoL2D = to2D(parts.LowerTorso)
                    local leftArmU2D = to2D(parts.LeftUpperArm)
                    local leftArmL2D = to2D(parts.LeftLowerArm)
                    local rightArmU2D = to2D(parts.RightUpperArm)
                    local rightArmL2D = to2D(parts.RightLowerArm)
                    local leftLegU2D = to2D(parts.LeftUpperLeg)
                    local leftLegL2D = to2D(parts.LeftLowerLeg)
                    local rightLegU2D = to2D(parts.RightUpperLeg)
                    local rightLegL2D = to2D(parts.RightLowerLeg)

                    -- Gambar stickman
                    local function drawLine(line, from, to)
                        if from and to then
                            line.From = from
                            line.To = to
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    end

                    drawLine(skeleton.Head, head2D, torsoU2D)
                    drawLine(skeleton.Torso, torsoU2D, torsoL2D)
                    drawLine(skeleton.LeftArm, torsoU2D, leftArmL2D or leftArmU2D)
                    drawLine(skeleton.RightArm, torsoU2D, rightArmL2D or rightArmU2D)
                    drawLine(skeleton.LeftLeg, torsoL2D, leftLegL2D or leftLegU2D)
                    drawLine(skeleton.RightLeg, torsoL2D, rightLegL2D or rightLegU2D)
                end
            end)

            DescendantConnection = workspace.DescendantAdded:Connect(function(obj)
                if isValidMale(obj) then
                    createSkeleton(obj)
                end
            end)
        end

        local function stopESP()
            print("[ESP] Sistem ESP dimatikan ❌")
            if ESPConnection then ESPConnection:Disconnect() ESPConnection = nil end
            if DescendantConnection then DescendantConnection:Disconnect() DescendantConnection = nil end
            clearAllESP()
        end

        -- Toggle UI
        Group:AddToggle("EnableESPSystem", {
            Text = "Aktifkan ESP Stickman",
            Default = false,
            Callback = function(Value)
                vars.ToggleESP = Value
                if Value then startESP() else stopESP() end
            end
        })

        print("✅ ESP.lua loaded — menampilkan NPC sebagai manusia lidi (stickman)")
    end
}
