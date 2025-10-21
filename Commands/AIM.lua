-- AIM.lua
-- Aimbot halus dan ringan, lock ke kepala semua Male AI_
-- Harus menerima tab dari WindowTab.lua: Execute(tab)

return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        _G.BotVars = vars
        local Tabs = vars.Tabs or {}

        -- fallback otomatis ke tab Combat
        tab = tab or Tabs.Combat
        if not tab then
            warn("[AIM] Tab Combat tidak ditemukan! Pastikan WindowTab.lua sudah dimuat.")
            return
        end

        -- Inisialisasi variabel global
        vars.ToggleAIM = vars.ToggleAIM or false
        vars.AimSmoothness = vars.AimSmoothness or 0.03
        vars.AimRange = vars.AimRange or 600

        -- Pastikan tab valid
        if type(tab) ~= "table" or not tab.AddLeftGroupbox then
            warn("[AIM] Objek tab tidak valid.")
            return
        end

        -- UI
        local Group = tab:AddLeftGroupbox("AIMBOT Control")
        Group:AddToggle("EnableAIM", {
            Text = "Aktifkan Aimbot",
            Default = vars.ToggleAIM,
            Callback = function(v)
                vars.ToggleAIM = v
                print(v and "[AIMBOT] Aktif ✅" or "[AIMBOT] Nonaktif ❌")
            end
        })

        Group:AddSlider("AimSmoothness", {
            Text = "Kelembutan Aim (0 = snap instan)",
            Default = vars.AimSmoothness,
            Min = 0,
            Max = 0.2,
            Rounding = 3,
            Callback = function(v)
                vars.AimSmoothness = v
            end
        })

        Group:AddSlider("AimRange", {
            Text = "Jarak Maksimal Target (studs)",
            Default = vars.AimRange,
            Min = 50,
            Max = 2000,
            Rounding = 0,
            Callback = function(v)
                vars.AimRange = v
            end
        })

        -- Services
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera

        -- Cache target NPC
        local CachedNPCs, ValidModelsSet = {}, {}
        local descConn, hbConn
        local renderBind = "AIMBOT_RenderLock"

        -- Helpers
        local function modelHasAINode(mdl)
            for _, child in ipairs(mdl:GetChildren()) do
                if type(child.Name) == "string" and child.Name:find("AI_") then
                    return true
                end
            end
            return false
        end

        local function addModel(mdl)
            if not mdl or not mdl:IsA("Model") or mdl.Name ~= "Male" then return end
            if ValidModelsSet[mdl] then return end
            if not modelHasAINode(mdl) then return end
            local hum = mdl:FindFirstChildOfClass("Humanoid")
            local head = mdl:FindFirstChild("Head")
            if not hum or hum.Health <= 0 or not head then return end

            CachedNPCs[mdl] = head
            ValidModelsSet[mdl] = true

            mdl.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    CachedNPCs[mdl] = nil
                    ValidModelsSet[mdl] = nil
                end
            end)
            hum.Died:Connect(function()
                CachedNPCs[mdl] = nil
                ValidModelsSet[mdl] = nil
            end)
        end

        -- Scan awal workspace
        for _, obj in ipairs(workspace:GetChildren()) do
            addModel(obj)
        end

        -- Tambah otomatis kalau ada model baru
        descConn = workspace.DescendantAdded:Connect(function(inst)
            local root = inst
            for _ = 1, 5 do
                if not root then break end
                if root:IsA("Model") then
                    addModel(root)
                    break
                end
                root = root.Parent
            end
        end)

        -- Targeting
        local currentTarget
        local targetUpdateInterval = 0.12
        local accumulator = 0

        local function findNearestTarget()
            local camPos = Camera.CFrame.Position
            local nearest, bestDist = nil, math.huge
            local range = vars.AimRange or 600

            for mdl, head in pairs(CachedNPCs) do
                if head and head.Parent then
                    local hum = mdl:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local dist = (head.Position - camPos).Magnitude
                        if dist < range and dist < bestDist then
                            bestDist = dist
                            nearest = head
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

            currentTarget = nearest
        end

        -- Bersihkan binding lama
        pcall(function()
            RunService:UnbindFromRenderStep(renderBind)
        end)

        -- Lock kamera ke target
        RunService:BindToRenderStep(renderBind, Enum.RenderPriority.Camera.Value + 1, function()
            if not vars.ToggleAIM then return end
            local target = currentTarget
            if not target or not target.Parent then return end

            local curCF = Camera.CFrame
            local targetCF = CFrame.lookAt(curCF.Position, target.Position)
            local smooth = vars.AimSmoothness or 0

            if smooth <= 0 then
                Camera.CFrame = targetCF
            else
                Camera.CFrame = curCF:Lerp(targetCF, math.clamp(smooth, 0, 1))
            end
        end)

        -- Update target tiap interval
        hbConn = RunService.Heartbeat:Connect(function(dt)
            if not vars.ToggleAIM then return end
            accumulator += dt
            if accumulator >= targetUpdateInterval then
                accumulator = 0
                task.spawn(findNearestTarget)
            end
        end)

        -- Cleanup callable
        vars._AIM_Cleanup = function()
            if descConn then descConn:Disconnect(); descConn = nil end
            if hbConn then hbConn:Disconnect(); hbConn = nil end
            pcall(function() RunService:UnbindFromRenderStep(renderBind) end)
            CachedNPCs = {}
            ValidModelsSet = {}
        end

        print("✅ [AIM] Aimbot aktif — halus, ringan, otomatis lock ke kepala Male AI_.")
    end
}
