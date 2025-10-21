return {
    Execute = function()
        local vars = _G.BotVars
        local Window = vars.MainWindow

        local Tabs = { ESP = Window:AddTab("ESP", "eye") }
        local Group = Tabs.ESP:AddLeftGroupbox("ESP Control")

        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera

        local ESPColor = Color3.fromRGB(255, 255, 255)
        local ActiveESP = {}
        local ESPConnection, DescendantConnection

        local function isValidNPC(model)
            if not model:IsA("Model") or model.Name ~= "Male" then return false end
            if not model:FindFirstChildOfClass("Humanoid") then return false end
            for _, c in ipairs(model:GetChildren()) do
                if string.sub(c.Name,1,3) == "AI_" then return true end
            end
            return false
        end

        local function getBodyParts(model)
            local parts = {}
            for _, name in ipairs({
                "Head","UpperTorso","LowerTorso",
                "LeftUpperArm","LeftLowerArm","LeftHand",
                "RightUpperArm","RightLowerArm","RightHand",
                "LeftUpperLeg","LeftLowerLeg","LeftFoot",
                "RightUpperLeg","RightLowerLeg","RightFoot"
            }) do
                local p = model:FindFirstChild(name)
                if p and p:IsA("BasePart") then
                    parts[name] = p
                end
            end
            return parts
        end

        local function newLine()
            local line = Drawing.new("Line")
            line.Color = ESPColor
            line.Thickness = 1.2
            line.Transparency = 1
            line.Visible = false
            return line
        end

        local function newText()
            local text = Drawing.new("Text")
            text.Color = ESPColor
            text.Size = 14
            text.Center = true
            text.Outline = true
            text.Visible = false
            return text
        end

        local function createESP(model)
            if ActiveESP[model] or not isValidNPC(model) then return end

            local parts = getBodyParts(model)
            local lines = {}
            for _ in pairs(parts) do table.insert(lines, newLine()) end
            local tracer = newLine()
            local distanceText = newText()

            ActiveESP[model] = {
                Lines = lines,
                Tracer = tracer,
                Text = distanceText,
                Parts = parts,
                Initialized = false
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

        local function clearAllESP()
            for _, data in pairs(ActiveESP) do
                for _, obj in pairs(data.Lines) do obj:Remove() end
                data.Tracer:Remove()
                data.Text:Remove()
            end
            ActiveESP = {}
        end

        local function startESP()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if isValidNPC(obj) then createESP(obj) end
            end

            ESPConnection = RunService.RenderStepped:Connect(function()
                for model, data in pairs(ActiveESP) do
                    if not (model and model.Parent) then continue end
                    local parts = data.Parts
                    local torso = parts.UpperTorso or parts.LowerTorso
                    if torso then
                        local pos, onScreen = Camera:WorldToViewportPoint(torso.Position)

                        -- pastikan frame pertama selesai sebelum visible
                        if not data.Initialized then
                            data.Initialized = true
                        else
                            local visible = onScreen
                            data.Text.Position = Vector2.new(pos.X,pos.Y-25)
                            data.Text.Text = string.format("%.1fm",(Camera.CFrame.Position - torso.Position).Magnitude)
                            if data.Text.Visible ~= visible then data.Text.Visible = visible end

                            data.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                            data.Tracer.To = Vector2.new(pos.X,pos.Y)
                            if data.Tracer.Visible ~= visible then data.Tracer.Visible = visible end
                        end
                    end

                    local function drawLine(p1,p2,line)
                        if p1 and p2 then
                            local p1v,on1 = Camera:WorldToViewportPoint(p1.Position)
                            local p2v,on2 = Camera:WorldToViewportPoint(p2.Position)
                            local vis = on1 or on2
                            line.From = Vector2.new(p1v.X,p1v.Y)
                            line.To = Vector2.new(p2v.X,p2v.Y)
                            if line.Visible ~= vis then line.Visible = vis end
                        else
                            if line.Visible ~= false then line.Visible = false end
                        end
                    end

                    local i=1
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

            DescendantConnection = workspace.DescendantAdded:Connect(function(obj)
                if isValidNPC(obj) then createESP(obj) end
            end)
        end

        local function stopESP()
            if ESPConnection then ESPConnection:Disconnect(); ESPConnection=nil end
            if DescendantConnection then DescendantConnection:Disconnect(); DescendantConnection=nil end
            clearAllESP()
        end

        Group:AddToggle("EnableESPSystem", {
            Text="Aktifkan ESP Skeleton (AI_)",
            Default=false,
            Callback=function(Value)
                vars.ToggleESP = Value
                if Value then startESP() else stopESP() end
            end
        })
    end
}
