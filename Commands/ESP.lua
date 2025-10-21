-- ESP.lua
-- Skeleton ESP + Tracer + Distance untuk Male AI_
-- Harus menerima tab dari WindowTab.lua: Execute(tab)

return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        _G.BotVars = vars
        vars.ToggleESP = vars.ToggleESP or false

        -- fallback tab Visual
        local Tabs = vars.Tabs or {}
        tab = tab or Tabs.Visual
        if not tab then
            if vars.MainWindow and vars.MainWindow.AddTab then
                tab = vars.MainWindow:AddTab("Visual", "eye")
                vars.Tabs = vars.Tabs or {}
                vars.Tabs.Visual = tab
                print("[ESP] Tab Visual dibuat otomatis.")
            else
                warn("[ESP] Tab Visual tidak tersedia.")
                return
            end
        end

        -- Services
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera

        -- UI
        local Group = tab:AddLeftGroupbox("ESP Control")
        local ESPRange = 600
        local SkeletonColor = Color3.fromRGB(255, 255, 255)
        local TracerColor = Color3.fromRGB(255, 0, 0)
        local TextColor = Color3.fromRGB(255, 255, 255)

        -- Cache
        local ActiveESP = {}
        local ESPConn, AddConn

        -- Helpers
        local function isValidNPC(model)
            if not model:IsA("Model") or model.Name ~= "Male" then return false end
            local hum = model:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return false end
            for _, c in ipairs(model:GetChildren()) do
                if c.Name:find("AI_") then return true end
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

        local function getParts(model)
            local parts = {}
            for _, n in ipairs(partNames) do
                local p = model:FindFirstChild(n)
                if p and p:IsA("BasePart") then
                    parts[n] = p
                end
            end
            return parts
        end

        local function newLine(color)
            local line = Drawing.new("Line")
            line.Color = color
            line.Thickness = 1.2
            line.Visible = false
            return line
        end

        local function newText()
            local t = Drawing.new("Text")
            t.Color = TextColor
            t.Size = 14
            t.Center = true
            t.Outline = true
            t.Visible = false
            return t
        end

        local function createESP(model)
            if ActiveESP[model] or not isValidNPC(model) then return end
            local parts = getParts(model)
            local lines = {}
            for _ in pairs(parts) do
                table.insert(lines, newLine(SkeletonColor))
            end
            local tracer = newLine(TracerColor)
            local text = newText()

            ActiveESP[model] = { Parts = parts, Lines = lines, Tracer = tracer, Text = text }

            local function cleanup()
                if not ActiveESP[model] then return end
                for _, l in pairs(ActiveESP[model].Lines) do l:Remove() end
                ActiveESP[model].Tracer:Remove()
                ActiveESP[model].Text:Remove()
                ActiveESP[model] = nil
            end

            local hum = model:FindFirstChildOfClass("Humanoid")
            if hum then hum.Died:Connect(cleanup) end
            model.AncestryChanged:Connect(function(_, parent)
                if not parent then cleanup() end
            end)
        end

        local function clearAll()
            for _, data in pairs(ActiveESP) do
                for _, l in pairs(data.Lines) do l:Remove() end
                data.Tracer:Remove()
                data.Text:Remove()
            end
            ActiveESP = {}
        end

        local function drawLine(a, b, line)
            if not a or not b then line.Visible = false return end
            local p1, on1 = Camera:WorldToViewportPoint(a.Position)
            local p2, on2 = Camera:WorldToViewportPoint(b.Position)
            line.From = Vector2.new(p1.X, p1.Y)
            line.To = Vector2.new(p2.X, p2.Y)
            line.Visible = on1 or on2
        end

        local function startESP()
            -- scan awal
            for _, o in ipairs(workspace:GetChildren()) do
                if isValidNPC(o) then createESP(o) end
            end

            -- update visual
            ESPConn = RunService.RenderStepped:Connect(function()
                local camPos = Camera.CFrame.Position
                local halfX, halfY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2

                for model, data in pairs(ActiveESP) do
                    if not isValidNPC(model) then
                        for _, l in pairs(data.Lines) do l.Visible = false end
                        data.Tracer.Visible = false
                        data.Text.Visible = false
                        ActiveESP[model] = nil
                        continue
                    end

                    local torso = data.Parts.UpperTorso or data.Parts.LowerTorso
                    if not torso then continue end

                    local dist = (torso.Position - camPos).Magnitude
                    if dist > ESPRange then
                        for _, l in pairs(data.Lines) do l.Visible = false end
                        data.Tracer.Visible = false
                        data.Text.Visible = false
                        continue
                    end

                    local pos, onScreen = Camera:WorldToViewportPoint(torso.Position)
                    if not onScreen then
                        data.Tracer.Visible = false
                        data.Text.Visible = false
                    else
                        data.Tracer.From = Vector2.new(halfX, Camera.ViewportSize.Y)
                        data.Tracer.To = Vector2.new(pos.X, pos.Y)
                        data.Tracer.Visible = true

                        data.Text.Position = Vector2.new(pos.X, pos.Y - 25)
                        data.Text.Text = string.format("%.1fm", dist)
                        data.Text.Visible = true
                    end

                    local i = 1
                    drawLine(data.Parts.Head, data.Parts.UpperTorso, data.Lines[i]); i+=1
                    drawLine(data.Parts.UpperTorso, data.Parts.LowerTorso, data.Lines[i]); i+=1
                    drawLine(data.Parts.UpperTorso, data.Parts.LeftUpperArm, data.Lines[i]); i+=1
                    drawLine(data.Parts.LeftUpperArm, data.Parts.LeftLowerArm, data.Lines[i]); i+=1
                    drawLine(data.Parts.LeftLowerArm, data.Parts.LeftHand, data.Lines[i]); i+=1
                    drawLine(data.Parts.UpperTorso, data.Parts.RightUpperArm, data.Lines[i]); i+=1
                    drawLine(data.Parts.RightUpperArm, data.Parts.RightLowerArm, data.Lines[i]); i+=1
                    drawLine(data.Parts.RightLowerArm, data.Parts.RightHand, data.Lines[i]); i+=1
                    drawLine(data.Parts.LowerTorso, data.Parts.LeftUpperLeg, data.Lines[i]); i+=1
                    drawLine(data.Parts.LeftUpperLeg, data.Parts.LeftLowerLeg, data.Lines[i]); i+=1
                    drawLine(data.Parts.LeftLowerLeg, data.Parts.LeftFoot, data.Lines[i]); i+=1
                    drawLine(data.Parts.LowerTorso, data.Parts.RightUpperLeg, data.Lines[i]); i+=1
                    drawLine(data.Parts.RightUpperLeg, data.Parts.RightLowerLeg, data.Lines[i]); i+=1
                    drawLine(data.Parts.RightLowerLeg, data.Parts.RightFoot, data.Lines[i])
                end
            end)

            -- Tambah ESP untuk NPC baru
            AddConn = workspace.DescendantAdded:Connect(function(obj)
                if isValidNPC(obj) then createESP(obj) end
            end)
        end

        local function stopESP()
            if ESPConn then ESPConn:Disconnect(); ESPConn = nil end
            if AddConn then AddConn:Disconnect(); AddConn = nil end
            clearAll()
        end

        -- Cleanup global supaya bisa direset oleh script utama
        vars._ESP_Cleanup = function()
            stopESP()
        end

        -- Toggle UI
        Group:AddToggle("EnableESPSystem", {
            Text = "Aktifkan ESP Skeleton (AI_)",
            Default = vars.ToggleESP,
            Callback = function(val)
                vars.ToggleESP = val
                if val then startESP() else stopESP() end
                print(val and "[ESP] Aktif ✅" or "[ESP] Nonaktif ❌")
            end
        })

        print("✅ [ESP] Module aktif — Skeleton, tracer, dan jarak di tab Visual.")
    end
}
