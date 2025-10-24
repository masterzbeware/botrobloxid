-- Silent Aim (optimized)
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local CombatTab = tab or Tabs.Combat

        if not CombatTab then
            warn("[Silent Aim] Tab Combat tidak ditemukan!")
            return
        end

        local Group = CombatTab:AddLeftGroupbox("Silent Aim")

        -- Settings (default)
        vars.SilentAim = vars.SilentAim or false
        vars.FOV = vars.FOV or 100
        vars.MaxDistance = vars.MaxDistance or 400
        vars.SilentAimDebug = vars.SilentAimDebug or false -- optional debug

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local localPlayer = Players.LocalPlayer
        local Camera = workspace.CurrentCamera

        -- Visual FOV circle
        local circle = Drawing.new("Circle")
        circle.Visible = false
        circle.Radius = vars.FOV
        circle.Color = Color3.fromRGB(255, 255, 255)
        circle.Thickness = 2
        circle.Position = Camera.ViewportSize / 2

        -- Cached table of candidate Male NPCs (model -> true)
        local trackedMales = {}
        local trackedCount = 0

        -- Helper small functions
        local function startsWithAI(name)
            return name:sub(1,3) == "AI_"
        end

        local function hasAIChild(model)
            -- Fast iteration; don't allocate intermediate tables
            for _, child in ipairs(model:GetChildren()) do
                if startsWithAI(child.Name) then
                    return true
                end
            end
            return false
        end

        local function isLocalPlayerModel(model)
            return localPlayer and localPlayer.Character and model == localPlayer.Character
        end

        local function isValidMaleModel(model)
            if not model or not model.Parent then return false end
            if not model:IsA("Model") then return false end
            if model.Name ~= "Male" then return false end
            if isLocalPlayerModel(model) then return false end
            if not model:FindFirstChild("Head") then return false end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return false end
            if not hasAIChild(model) then return false end
            return true
        end

        local function addTracked(model)
            if trackedMales[model] then return end
            trackedMales[model] = true
            trackedCount = trackedCount + 1
        end

        local function removeTracked(model)
            if trackedMales[model] then
                trackedMales[model] = nil
                trackedCount = trackedCount - 1
            end
        end

        -- Initialize trackedMales once (only top-level children to reduce cost)
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj.Name == "Male" and isValidMaleModel(obj) then
                addTracked(obj)
            end
        end

        -- Workspace listeners: event-driven updates (efficient)
        local descAddedConn
        local descRemovingConn
        descAddedConn = workspace.DescendantAdded:Connect(function(obj)
            -- If a whole Model "Male" is added
            if obj:IsA("Model") and obj.Name == "Male" then
                if isValidMaleModel(obj) then addTracked(obj) end
                return
            end
            -- If an AI_ child (or Head) added under a model, check its ancestor model
            if startsWithAI(obj.Name) or obj.Name == "Head" then
                local m = obj:FindFirstAncestorWhichIsA and obj:FindFirstAncestorWhichIsA("Model")
                if m and m.Name == "Male" and isValidMaleModel(m) then
                    addTracked(m)
                end
            end
        end)

        descRemovingConn = workspace.DescendantRemoving:Connect(function(obj)
            -- If a Model Male removed entirely
            if obj:IsA("Model") and obj.Name == "Male" then
                removeTracked(obj)
                return
            end
            -- If a child that made a model valid got removed, re-evaluate that ancestor model
            if startsWithAI(obj.Name) or obj.Name == "Head" then
                local m = obj:FindFirstAncestorWhichIsA and obj:FindFirstAncestorWhichIsA("Model")
                if m and m.Name == "Male" and not isValidMaleModel(m) then
                    removeTracked(m)
                end
            end
        end)

        -- Efficient function: return closest valid Male model within FOV radius (screen-space) and distance
        local function getClosestMaleNPC()
            if trackedCount == 0 then return nil end

            local cam = Camera
            local center = cam.ViewportSize / 2
            local fovRadius = vars.FOV
            local fovRadiusSq = fovRadius * fovRadius
            local maxDistSq = vars.MaxDistance * vars.MaxDistance
            local best = nil
            local bestDistSq = fovRadiusSq -- compare squared screen distance

            -- Localize some functions/vars for speed
            local tracked = trackedMales
            local CFramePos = cam.CFrame.Position

            for model,_ in pairs(tracked) do
                -- quick validity re-check (cheap)
                if not model or not model.Parent then
                    tracked[model] = nil
                    trackedCount = trackedCount - 1
                else
                    -- Use head as aim point
                    local head = model:FindFirstChild("Head")
                    if head then
                        local toCamVec = head.Position - CFramePos
                        local distSq = toCamVec:Dot(toCamVec)
                        if distSq <= maxDistSq then
                            local screenPos3, onScreen = cam:WorldToViewportPoint(head.Position)
                            if onScreen then
                                -- compute screen space delta squared
                                local dx = center.X - screenPos3.X
                                local dy = center.Y - screenPos3.Y
                                local screenDistSq = dx*dx + dy*dy
                                if screenDistSq < bestDistSq then
                                    bestDistSq = screenDistSq
                                    best = model
                                end
                            end
                        end
                    end
                end
            end

            return best
        end

        -- Hook BulletService.Discharge safely (pcall) and only once
        local ok, BulletService = pcall(function()
            return require(ReplicatedStorage.Shared.Services.BulletService)
        end)

        if ok and BulletService and not getgenv().SilentAimHooked then
            getgenv().SilentAimHooked = true
            local originalDischarge = BulletService.Discharge

            BulletService.Discharge = function(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                -- If silent aim disabled -> call original quickly
                if not vars.SilentAim then
                    return originalDischarge(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                end

                -- Find candidate (fast, uses trackedMales only)
                local targetNPC = getClosestMaleNPC()
                if targetNPC and targetNPC.Parent then
                    local head = targetNPC:FindFirstChild("Head")
                    if head then
                        -- Build newCFrame pointing from origin to head (no heavy math)
                        local newCFrame = CFrame.lookAt(originCFrame.Position, head.Position)
                        return originalDischarge(self, newCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
                    end
                end

                -- fallback - no change
                return originalDischarge(self, originCFrame, caliber, velocity, replicate, localShooter, ignore, tracer, ...)
            end
        end

        -- UI Elements
        Group:AddToggle("ToggleSilentAim", {
            Text = "Silent Aim",
            Default = vars.SilentAim,
            Callback = function(v)
                vars.SilentAim = v
                circle.Visible = v
            end
        })

        Group:AddSlider("FOVSlider", {
            Text = "FOV Size",
            Default = vars.FOV,
            Min = 5,
            Max = 500,
            Rounding = 0,
            Callback = function(v)
                vars.FOV = v
                circle.Radius = v
            end
        })

        Group:AddSlider("MaxDistanceSlider", {
            Text = "Max Distance",
            Default = vars.MaxDistance,
            Min = 50,
            Max = 1000,
            Rounding = 0,
            Callback = function(v)
                vars.MaxDistance = v
            end
        })

        -- Optional lightweight debug toggle (does not iterate heavy unless enabled)
        Group:AddToggle("SilentAimDebug", {
            Text = "Debug Info (light)",
            Default = vars.SilentAimDebug,
            Callback = function(v) vars.SilentAimDebug = v end
        })

        -- Update circle position each frame (cheap)
        local circleConn = RunService.RenderStepped:Connect(function()
            -- update camera reference in case it changed
            Camera = workspace.CurrentCamera
            if Camera then
                circle.Position = Camera.ViewportSize / 2
            end
        end)

        -- Very light debug printer every 3 seconds if enabled (task.wait used)
        task.spawn(function()
            while true do
                task.wait(3)
                if vars.SilentAim and vars.SilentAimDebug then
                    local target = getClosestMaleNPC()
                    if target and target:FindFirstChild("Head") then
                        local dist = (target.Head.Position - (Camera and Camera.CFrame.Position or Vector3.new())).Magnitude
                        local aiCount = 0
                        for _,ch in ipairs(target:GetChildren()) do
                            if startsWithAI(ch.Name) then aiCount = aiCount + 1 end
                        end
                        print(string.format("SilentAim Debug -> Target: %s | Dist: %.1f | AI parts: %d", tostring(target), dist, aiCount))
                    else
                        if trackedCount > 0 then
                            print("SilentAim Debug -> No on-screen target. TrackedCount:", trackedCount)
                        else
                            -- nothing to print (keeps console quiet)
                        end
                    end
                end
            end
        end)

        -- Clean up function if needed (not strictly required but good practice)
        local function cleanup()
            if descAddedConn then descAddedConn:Disconnect(); descAddedConn = nil end
            if descRemovingConn then descRemovingConn:Disconnect(); descRemovingConn = nil end
            if circleConn then circleConn:Disconnect(); circleConn = nil end
            for m in pairs(trackedMales) do trackedMales[m] = nil end
            trackedCount = 0
        end

        -- Expose cleanup in vars so other scripts can stop it if needed
        vars.SilentAimCleanup = cleanup

        print("✅ [Silent Aim NPC Male AI] Sistem aktif (optimized). Tracked count:", trackedCount)
    end
}
