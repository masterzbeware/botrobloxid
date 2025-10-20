-- AIM.lua
-- 🎯 Smooth Aim Assist: Kamera otomatis mengikuti kepala NPC bernama "Male" secara halus

return {
    Execute = function()
        local vars = _G.BotVars
        local Window = vars.MainWindow
        local Camera = workspace.CurrentCamera
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        -- 🪶 UI Tab
        local Tabs = {
            Aim = Window:AddTab("AIM", "crosshair"),
        }
        local Group = Tabs.Aim:AddLeftGroupbox("AIM Assist Control")

        Group:AddToggle("EnableAIM", {
            Text = "Aktifkan Aim Assist (Lock Kepala)",
            Default = false,
            Callback = function(Value)
                vars.ToggleAIM = Value
                print(Value and "[AIM] Smooth Aim Assist Aktif ✅" or "[AIM] Nonaktif ❌")
            end
        })

        Group:AddSlider("AimSmoothness", {
            Text = "Kelembutan Aim",
            Default = 0.2, -- Semakin kecil semakin halus, semakin besar semakin cepat
            Min = 0.05,
            Max = 1,
            Rounding = 2,
            Callback = function(Value)
                vars.AimSmoothness = Value
            end
        })

        -- 🔍 Cari NPC terdekat
        local function getNearestHead()
            local nearest, dist = nil, math.huge
            for _, model in ipairs(workspace:GetChildren()) do
                if model:IsA("Model") and model.Name == "Male" and model:FindFirstChildOfClass("Humanoid") then
                    local head = model:FindFirstChild("Head") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
                    if head then
                        local magnitude = (head.Position - Camera.CFrame.Position).Magnitude
                        if magnitude < dist then
                            nearest = head
                            dist = magnitude
                        end
                    end
                end
            end
            return nearest
        end

        -- 🎯 Smooth Aim Assist Logic
        RunService.RenderStepped:Connect(function()
            if not vars.ToggleAIM then
                vars.CurrentAimTarget = nil
                return
            end

            local head = getNearestHead()
            if not head then
                vars.CurrentAimTarget = nil
                return
            end

            vars.CurrentAimTarget = head

            -- 🎥 Smooth rotate kamera menuju kepala target
            local currentCF = Camera.CFrame
            local targetCF = CFrame.lookAt(currentCF.Position, head.Position)
            local smoothness = vars.AimSmoothness or 0.2
            Camera.CFrame = currentCF:Lerp(targetCF, smoothness)
        end)

        print("✅ AIM.lua aktif — Smooth Aim Assist siap digunakan")
    end
}
