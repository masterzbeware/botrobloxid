-- AIM_OnlyAimbot.lua
-- Aimbot: langsung mengarahkan kamera ke kepala NPC "Male" (AI_) — tanpa auto-fire

return {
    Execute = function()
        local vars = _G.BotVars
        vars.ToggleAIM = vars.ToggleAIM or false
        vars.AimSmoothness = vars.AimSmoothness or 0 -- 0 = instant snap (aimbot)
        vars.AimRange = vars.AimRange or 500

        local Window = vars.MainWindow
        local Camera = workspace.CurrentCamera
        local RunService = game:GetService("RunService")

        -- UI
        if Window then
            local Tabs = { Aim = Window:AddTab("AIM", "crosshair") }
            local Group = Tabs.Aim:AddLeftGroupbox("AIMBOT Control")

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
        end

        -- helper: valid NPC detection (Male + AI_ child + alive)
        local function isValidNPC(model)
            if not model or not model:IsA("Model") or model.Name ~= "Male" then return false end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return false end
            for _, c in ipairs(model:GetChildren()) do
                if type(c.Name) == "string" and c.Name:find("AI_") then return true end
            end
            return false
        end

        -- cari kepala terdekat dalam range
        local function getNearestHead()
            local nearest, dist = nil, math.huge
            local camPos = Camera.CFrame.Position
            local maxRange = vars.AimRange or 500

            -- iterate GetDescendants untuk akurat menemukan model walau nested
            for _, model in ipairs(workspace:GetDescendants()) do
                if model:IsA("Model") and isValidNPC(model) then
                    local head = model:FindFirstChild("Head")
                    if head and head:IsA("BasePart") then
                        local d = (head.Position - camPos).Magnitude
                        if d <= maxRange and d < dist then
                            nearest = head
                            dist = d
                        end
                    end
                end
            end

            return nearest
        end

        -- RenderStepped: aimbot — snap / lerp kamera ke kepala target
        RunService:BindToRenderStep("AIMBOT_LockHead", Enum.RenderPriority.Camera.Value + 1, function()
            if not vars.ToggleAIM then return end
            local head = getNearestHead()
            if not head then return end

            local currentCF = Camera.CFrame
            -- target CFrame menghadap kepala (tetap posisi kamera, hanya rotasi)
            local targetCF = CFrame.lookAt(currentCF.Position, head.Position)
            local smooth = vars.AimSmoothness or 0

            -- Jika smooth == 0, lakukan snap instan (aimbot)
            if smooth <= 0 then
                Camera.CFrame = targetCF
            else
                Camera.CFrame = currentCF:Lerp(targetCF, math.clamp(smooth, 0, 1))
            end
        end)

        print("✅ AIM_OnlyAimbot.lua aktif — aimbot (snap/lerp) ke kepala, tanpa auto-fire")
    end
}
