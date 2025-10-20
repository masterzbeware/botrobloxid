-- ESP.lua
-- ESP Otomatis + Skeleton (manusia lidi) untuk Model bernama "Male"

return {
    Execute = function()
        local vars = _G.BotVars
        local Window = vars.MainWindow

        -- Tab ESP
        local Tabs = {
            ESP = Window:AddTab("ESP", "eye"),
        }

        local Group = Tabs.ESP:AddLeftGroupbox("ESP Control")

        -- Services
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera
        local LocalPlayer = Players.LocalPlayer
        local ESPColor = Color3.fromRGB(0, 255, 0)
        local ActiveESP = {}
        local ESPConnection = nil
        local DescendantConnection = nil

        -- Validasi model
        local function isValidMale(model)
            if not model:IsA("Model") then return false end
            if model.Name ~= "Male" then return false end
            if not model:FindFirstChildOfClass("Humanoid") then return false end
            return true
        end

        -- Posisi tengah tubuh
        local function getBodyCenter(model)
            local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
            if torso and torso:IsA("BasePart") then
                return torso.Position
            end
            return nil
        end

        -- 🔹 Membuat skeleton (garis manusia lidi)
        local function createSkeleton(model)
            local parts = {
                Head = model:FindFirstChild("Head"),
                UpperTorso = model:FindFirstChild("UpperTorso"),
                LowerTorso = model:FindFirstChild("LowerTorso"),
                LeftUpperArm = model:FindFirstChild("LeftUpperArm"),
                LeftLowerArm = model:FindFirstChild("LeftLowerArm"),
                RightUpperArm = model:FindFirstChild("RightUpperArm"),
                RightLowerArm = model:FindFirstChild("RightLowerArm"),
                LeftUpperLeg = model:FindFirstChild("LeftUpperLeg"),
                LeftLowerLeg = model:FindFirstChild("LeftLowerLeg"),
                RightUpperLeg = model:FindFirstChild("RightUpperLeg"),
                RightLowerLeg = model:FindFirstChild("RightLowerLeg"),
            }

            local bones = {
                {"Head", "UpperTorso"},
                {"UpperTorso", "LowerTorso"},
                {"UpperTorso", "LeftUpperArm"},
                {"LeftUpperArm", "LeftLowerArm"},
                {"UpperTorso", "RightUpperArm"},
                {"RightUpperArm", "RightLowerArm"},
                {"LowerTorso", "LeftUpperLeg"},
                {"LeftUpperLeg", "LeftLowerLeg"},
                {"LowerTorso", "RightUpperLeg"},
                {"RightUpperLeg", "RightLowerLeg"},
            }

            local lines = {}
            for _, bone in ipairs(bones) do
                local line = Drawing.new("Line")
                line.Color = ESPColor
                line.Thickness = 1
                line.Transparency = 1
                line.Visible = true
                table.insert(lines, {line = line, from = bone[1], to = bone[2]})
            end

            return {parts = parts, lines = lines}
        end

        -- 🔹 Buat ESP (tracer + skeleton)
        local function createESP(model)
            if ActiveESP[model] then return end
            if not isValidMale(model) then return end

            local tracer = Drawing.new("Line")
            tracer.Color = ESPColor
            tracer.Thickness = 1.5
            tracer.Transparency = 1
            tracer.Visible = true

            local skeleton = createSkeleton(model)
            ActiveESP[model] = {tracer = tracer, skeleton = skeleton}

            model.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    for _, bone in ipairs(skeleton.lines) do
                        bone.line.Visible = false
                        bone.line:Remove()
                    end
                    tracer.Visible = false
                    tracer:Remove()
                    ActiveESP[model] = nil
                end
            end)
        end

        -- 🔹 Bersihkan semua ESP
        local function clearAllESP()
            for _, esp in pairs(ActiveESP) do
                if esp.tracer then
                    esp.tracer.Visible = false
                    esp.tracer:Remove()
                end
                if esp.skeleton and esp.skeleton.lines then
                    for _, bone in ipairs(esp.skeleton.lines) do
                        bone.line.Visible = false
                        bone.line:Remove()
                    end
                end
            end
            ActiveESP = {}
        end

        -- 🔹 Jalankan ESP
        local function startESP()
            print("[ESP] ESP + Skeleton aktif ✅")

            for _, obj in ipairs(workspace:GetChildren()) do
                if isValidMale(obj) then
                    createESP(obj)
                end
            end

            ESPConnection = RunService.RenderStepped:Connect(function()
                for model, esp in pairs(ActiveESP) do
                    if model and model.Parent then
                        local bodyCenter = getBodyCenter(model)
                        if bodyCenter then
                            local pos, onScreen = Camera:WorldToViewportPoint(bodyCenter)
                            if onScreen then
                                -- tracer
                                esp.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                esp.tracer.To = Vector2.new(pos.X, pos.Y)
                                esp.tracer.Visible = true
                            else
                                esp.tracer.Visible = false
                            end
                        end

                        -- skeleton
                        if esp.skeleton then
                            for _, bone in ipairs(esp.skeleton.lines) do
                                local part1 = esp.skeleton.parts[bone.from]
                                local part2 = esp.skeleton.parts[bone.to]
                                if part1 and part2 and part1:IsA("BasePart") and part2:IsA("BasePart") then
                                    local p1, on1 = Camera:WorldToViewportPoint(part1.Position)
                                    local p2, on2 = Camera:WorldToViewportPoint(part2.Position)
                                    if on1 and on2 then
                                        bone.line.From = Vector2.new(p1.X, p1.Y)
                                        bone.line.To = Vector2.new(p2.X, p2.Y)
                                        bone.line.Visible = true
                                    else
                                        bone.line.Visible = false
                                    end
                                else
                                    bone.line.Visible = false
                                end
                            end
                        end
                    end
                end
            end)

            DescendantConnection = workspace.DescendantAdded:Connect(function(obj)
                if isValidMale(obj) then
                    createESP(obj)
                end
            end)
        end

        local function stopESP()
            print("[ESP] ESP dimatikan ❌")
            if ESPConnection then ESPConnection:Disconnect() ESPConnection = nil end
            if DescendantConnection then DescendantConnection:Disconnect() DescendantConnection = nil end
            clearAllESP()
        end

        -- Toggle ESP di UI
        Group:AddToggle("EnableESPSystem", {
            Text = "Aktifkan ESP + Skeleton",
            Default = false,
            Callback = function(Value)
                vars.ToggleESP = Value
                if Value then startESP() else stopESP() end
            end
        })

        print("✅ ESP.lua loaded — tracer + skeleton aktif untuk semua Model 'Male'")
    end
}
