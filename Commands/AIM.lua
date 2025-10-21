-- AIM.lua
-- Aimbot kuat & presisi hanya untuk Model "Male" yang punya child AI_
-- Dengan Circle Aim, Wallcheck (default off), dan Toggle kontrol

return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        _G.BotVars = vars
        local Tabs = vars.Tabs or {}
        tab = tab or Tabs.Combat
        if not tab then
            warn("[AIM] Tab Combat tidak ditemukan! Pastikan WindowTab.lua sudah dimuat.")
            return
        end

        -- Default
        vars.AimbotEnabled = vars.AimbotEnabled or false
        vars.ShowCircle    = vars.ShowCircle or false
        vars.CircleSize    = vars.CircleSize or 150
        vars.Wallcheck     = vars.Wallcheck or false -- 🔧 sekarang wallcheck default nonaktif

        -- UI
        local Group = tab:AddLeftGroupbox("Aimbot")

        Group:AddToggle("AimbotEnabled", {
            Text = "Aktifkan Aimbot",
            Default = vars.AimbotEnabled,
            Callback = function(v)
                vars.AimbotEnabled = v
                print(v and "[AIMBOT] Aktif ✅" or "[AIMBOT] Nonaktif ❌")
            end
        })

        Group:AddToggle("ShowAimCircle", {
            Text = "Tampilkan Circle Aim",
            Default = vars.ShowCircle,
            Callback = function(v)
                vars.ShowCircle = v
            end
        })

        Group:AddSlider("CircleSize", {
            Text = "Ukuran Circle Aim",
            Default = vars.CircleSize,
            Min = 50,
            Max = 400,
            Rounding = 0,
            Callback = function(v)
                vars.CircleSize = v
            end
        })

        Group:AddToggle("WallcheckToggle", {
            Text = "Aktifkan Wallcheck",
            Default = vars.Wallcheck, -- default: false
            Callback = function(v)
                vars.Wallcheck = v
                print(v and "[AIM] Wallcheck aktif 🧱" or "[AIM] Wallcheck dimatikan 🚫")
            end
        })

        -- Services
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera

        -- Circle
        local aimCircle = Drawing.new("Circle")
        aimCircle.Color = Color3.fromRGB(0, 255, 255)
        aimCircle.Thickness = 1.5
        aimCircle.Transparency = 0.8
        aimCircle.Filled = false

        -------------------------------------------------
        -- NPC Detection: Male model + child "AI_"
        -------------------------------------------------
        local function isValidNPC(model)
            if not model:IsA("Model") or model.Name ~= "Male" then return false end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return false end
            for _, c in ipairs(model:GetChildren()) do
                if typeof(c.Name) == "string" and string.sub(c.Name, 1, 3) == "AI_" then
                    return true
                end
            end
            return false
        end

        -------------------------------------------------
        -- Wallcheck: Raycast dari kamera ke target
        -------------------------------------------------
        local function isVisible(part)
            if not vars.Wallcheck then return true end
            local origin = Camera.CFrame.Position
            local direction = (part.Position - origin)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Blacklist
            params.FilterDescendantsInstances = {Camera}

            local result = workspace:Raycast(origin, direction, params)
            if not result then return true end
            return result.Instance:IsDescendantOf(part.Parent)
        end

        -------------------------------------------------
        -- Cari target terdekat di layar (head)
        -------------------------------------------------
        local validNPCs = {}

        -- cache NPC tiap 1.5 detik agar ringan
        task.spawn(function()
            while true do
                validNPCs = {}
                for _, model in ipairs(workspace:GetChildren()) do
                    if isValidNPC(model) then
                        local head = model:FindFirstChild("Head")
                        if head then table.insert(validNPCs, head) end
                    end
                end
                task.wait(1.5)
            end
        end)

        local function getClosestTarget()
            local mousePos = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            local closest, bestDist = nil, vars.CircleSize
            for _, head in ipairs(validNPCs) do
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < bestDist and isVisible(head) then
                        closest = head
                        bestDist = dist
                    end
                end
            end
            return closest
        end

        -------------------------------------------------
        -- Render Loop: Circle + Aim lock
        -------------------------------------------------
        RunService.RenderStepped:Connect(function()
            -- update circle
            aimCircle.Visible = vars.ShowCircle
            if vars.ShowCircle then
                local center = Camera.ViewportSize / 2
                aimCircle.Position = Vector2.new(center.X, center.Y)
                aimCircle.Radius = vars.CircleSize
            end

            -- Aimbot aktif
            if not vars.AimbotEnabled then return end
            local target = getClosestTarget()
            if target then
                local curCF = Camera.CFrame
                local targetCF = CFrame.lookAt(curCF.Position, target.Position)
                Camera.CFrame = curCF:Lerp(targetCF, 0.2) -- kuat dan halus
            end
        end)

        print("✅ [AIM] Aimbot siap — fokus ke Model 'Male' yang punya AI_. Wallcheck default: OFF")
    end
}
