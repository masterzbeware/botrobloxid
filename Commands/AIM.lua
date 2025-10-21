-- AIM_OnlyAimbot.lua (Optimized, low-lag aimbot)
-- Harus menerima tab dari WindowTab.lua: Execute(tab)
return {
    Execute = function(tab)
        if not tab then
            warn("[AIM] Tab tidak diberikan! Panggil Execute(Tabs.Combat) agar AIM muncul di tab Combat.")
            return
        end

        -- Vars global
        local vars = _G.BotVars or {}
        _G.BotVars = vars

        vars.ToggleAIM = vars.ToggleAIM or false
        vars.AimSmoothness = vars.AimSmoothness or 0
        vars.AimRange = vars.AimRange or 500

        -- Pastikan tab valid (objek tab Obsidian)
        if type(tab) ~= "table" or not tab.AddLeftGroupbox then
            warn("[AIM] Objek tab tidak valid. Pastikan melewatkan Tabs.Combat dari WindowTab.lua.")
            return
        end

        -- UI (di tab yang diberikan)
        local Group = tab:AddLeftGroupbox("AIMBOT Control")
        Group:AddToggle("EnableAIM", {
            Text = "Aktifkan Aimbot",
            Default = vars.ToggleAIM,
            Callback = function(Value)
                vars.ToggleAIM = Value
                print(Value and "[AIMBOT] Aktif ✅" or "[AIMBOT] Nonaktif ❌")
            end
        })

        Group:AddSlider("AimSmoothness", {
            Text = "Kelembutan Aim (0 = snap instan)",
            Default = vars.AimSmoothness,
            Min = 0,
            Max = 0.1,
            Rounding = 3,
            Callback = function(Value)
                vars.AimSmoothness = Value
            end
        })

        Group:AddSlider("AimRange", {
            Text = "Max Range Target (studs)",
            Default = vars.AimRange,
            Min = 50,
            Max = 2000,
            Rounding = 0,
            Callback = function(Value)
                vars.AimRange = Value
            end
        })

        -- Services
        local RunService = game:GetService("RunService")
        local Players = game:GetService("Players")
        local Camera = workspace.CurrentCamera

        -- State / cache
        local CachedNPCs = {}        -- [model] = headPart
        local ValidModelsSet = {}
        local descConn, hbConn
        local renderBoundName = "AIMBOT_LockHead_Optimized"

        -- Helpers
        local function modelHasAINode(mdl)
            for _, child in ipairs(mdl:GetChildren()) do
                if type(child.Name) == "string" and child.Name:find("AI_") then
                    return true
                end
            end
            return false
        end

        local function addModelToCache(mdl)
            if not mdl or not mdl:IsA("Model") then return end
            if ValidModelsSet[mdl] then return end
            if mdl.Name ~= "Male" then return end
            if not modelHasAINode(mdl) then return end
            local humanoid = mdl:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return end
            local head = mdl:FindFirstChild("Head")
            if not head or not head:IsA("BasePart") then return end

            CachedNPCs[mdl] = head
            ValidModelsSet[mdl] = true

            -- cleanup when model removed or dead
            mdl.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    CachedNPCs[mdl] = nil
                    ValidModelsSet[mdl] = nil
                end
            end)
            if humanoid then
                humanoid.Died:Connect(function()
                    CachedNPCs[mdl] = nil
                    ValidModelsSet[mdl] = nil
                end)
            end
        end

        -- initial scan (top-level children)
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") then
                addModelToCache(obj)
            end
        end

        -- DescendantAdded listener (cheap climb)
        descConn = workspace.DescendantAdded:Connect(function(inst)
            local root = inst
            for i = 1, 5 do
                if not root then break end
                if root:IsA("Model") then
                    addModelToCache(root)
                    break
                end
                root = root.Parent
            end
        end)

        -- Target selection
        local currentTarget = nil
        local targetUpdateInterval = 0.12
        local accumulator = 0

        local function findNearestTarget()
            local camPos = Camera.CFrame.Position
            local best, bestDist = nil, math.huge
            local maxRange = vars.AimRange or 500

            for mdl, head in pairs(CachedNPCs) do
                if head and head.Parent then
                    local hum = mdl:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local d = (head.Position - camPos).Magnitude
                        if d <= maxRange and d < bestDist then
                            best = head
                            bestDist = d
                        end
                    else
                        CachedNPCs[mdl] = nil
                        ValidModelsSet[mdl] = nil
                    end
                else
                    CachedNPCs[mdl] = nil
                    ValidModelsSet[mdl] = nil
                end
            end

            currentTarget = best
        end

        -- Cleanup any previous bindings (berguna saat reload)
        pcall(function() RunService:UnbindFromRenderStep(renderBoundName) end)

        -- Bind to render step for camera snapping
        RunService:BindToRenderStep(renderBoundName, Enum.RenderPriority.Camera.Value + 1, function()
            if not vars.ToggleAIM then return end
            local target = currentTarget
            if not target or not target.Parent then return end

            local currentCF = Camera.CFrame
            local targetCF = CFrame.lookAt(currentCF.Position, target.Position)
            local smooth = vars.AimSmoothness or 0
            if smooth <= 0 then
                Camera.CFrame = targetCF
            else
                Camera.CFrame = currentCF:Lerp(targetCF, math.clamp(smooth, 0, 1))
            end
        end)

        -- Heartbeat loop (throttled target updates)
        hbConn = RunService.Heartbeat:Connect(function(dt)
            if not vars.ToggleAIM then return end
            accumulator = accumulator + dt
            if accumulator >= targetUpdateInterval then
                accumulator = 0
                task.spawn(findNearestTarget)
            end
        end)

        -- Expose cleanup in vars in case caller wants to stop
        vars._AIM_Cleanup = function()
            if descConn then descConn:Disconnect(); descConn = nil end
            if hbConn then hbConn:Disconnect(); hbConn = nil end
            pcall(function() RunService:UnbindFromRenderStep(renderBoundName) end)
            CachedNPCs = {}
            ValidModelsSet = {}
        end

        print("✅ AIM_OnlyAimbot.lua aktif — rendah lag, aimbot ke kepala (snap/lerp)")
    end
}
