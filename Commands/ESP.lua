-- ESP.lua
-- ESP Otomatis untuk Model bernama "Male"

return {
    Execute = function()
        local vars = _G.BotVars
        local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
        local Window = Library:CreateWindow({
            Title = "MasterZ ESP Control",
            Footer = "ESP Panel",
            Icon = 0,
            ShowCustomCursor = true,
        })

        local Tabs = {
            Control = Window:AddTab("Control", "eye"),
        }

        local Group = Tabs.Control:AddLeftGroupbox("ESP Control")

        -- Variabel internal ESP
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera
        local LocalPlayer = Players.LocalPlayer
        local ESPColor = Color3.fromRGB(0, 255, 0)
        local ActiveESP = {}
        local ESPConnection = nil
        local DescendantConnection = nil

        -- Fungsi validasi model
        local function isValidMale(model)
            if not model:IsA("Model") then return false end
            if model.Name ~= "Male" then return false end
            if not model:FindFirstChildOfClass("Humanoid") then return false end
            for _, child in ipairs(model:GetChildren()) do
                if string.sub(child.Name, 1, 3) == "AI_" then
                    return true
                end
            end
            return false
        end

        local function getBodyCenter(model)
            local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("LowerTorso")
            if torso and torso:IsA("BasePart") then
                return torso.Position
            else
                local total, count = Vector3.zero, 0
                for _, part in ipairs(model:GetDescendants()) do
                    if part:IsA("BasePart") then
                        total += part.Position
                        count += 1
                    end
                end
                if count > 0 then
                    return total / count
                end
            end
            return nil
        end

        local function createTracer(model)
            if ActiveESP[model] then return end
            if not isValidMale(model) then return end

            local line = Drawing.new("Line")
            line.Color = ESPColor
            line.Thickness = 1.5
            line.Transparency = 1
            line.Visible = true
            ActiveESP[model] = line

            model.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    if line then
                        line.Visible = false
                        line:Remove()
                    end
                    ActiveESP[model] = nil
                end
            end)
        end

        local function clearAllESP()
            for _, line in pairs(ActiveESP) do
                if line then
                    line.Visible = false
                    line:Remove()
                end
            end
            ActiveESP = {}
        end

        local function startESP()
            print("[ESP] Sistem ESP diaktifkan")
            -- Buat semua ESP yang sudah ada
            for _, obj in ipairs(workspace:GetDescendants()) do
                if isValidMale(obj) then
                    createTracer(obj)
                end
            end

            -- Update posisi setiap frame
            ESPConnection = RunService.RenderStepped:Connect(function()
                for model, line in pairs(ActiveESP) do
                    if model and model.Parent then
                        local humanoid = model:FindFirstChildOfClass("Humanoid")
                        local player = humanoid and Players:GetPlayerFromCharacter(model)
                        if player == LocalPlayer then
                            line.Visible = false
                            continue
                        end

                        local bodyPos = getBodyCenter(model)
                        if bodyPos then
                            local pos, onScreen = Camera:WorldToViewportPoint(bodyPos)
                            if onScreen then
                                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                line.To = Vector2.new(pos.X, pos.Y)
                                line.Visible = true
                            else
                                line.Visible = false
                            end
                        else
                            line.Visible = false
                        end
                    else
                        line.Visible = false
                    end
                end
            end)

            -- Tambah ESP jika ada model baru
            DescendantConnection = workspace.DescendantAdded:Connect(function(obj)
                if isValidMale(obj) then
                    createTracer(obj)
                end
            end)
        end

        local function stopESP()
            print("[ESP] Sistem ESP dimatikan")
            if ESPConnection then
                ESPConnection:Disconnect()
                ESPConnection = nil
            end
            if DescendantConnection then
                DescendantConnection:Disconnect()
                DescendantConnection = nil
            end
            clearAllESP()
        end

        -- ✅ Toggle utama ESP
        Group:AddToggle("EnableESPSystem", {
            Text = "Aktifkan ESP System",
            Default = false,
            Callback = function(Value)
                vars.ToggleAktif = Value
                if Value then
                    startESP()
                else
                    stopESP()
                end
            end
        })

        print("✅ ESP.lua loaded — toggle akan hidupkan ESP otomatis")
    end
}
