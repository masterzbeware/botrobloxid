return {
    Execute = function()
        local vars = _G.BotVars
        vars.ToggleAIM = vars.ToggleAIM or false
        local Window = vars.MainWindow
        local Camera = workspace.CurrentCamera
        local RunService = game:GetService("RunService")

        -- UI
        local Tabs = { Aim = Window:AddTab("AIM", "crosshair") }
        local Group = Tabs.Aim:AddLeftGroupbox("AIM Assist Control")

        Group:AddToggle("EnableAIM", {
            Text = "Aktifkan Aim Assist Lengket (Lock Kepala)",
            Default = vars.ToggleAIM,
            Callback = function(Value)
                vars.ToggleAIM = Value
                print(Value and "[AIM] Lengket Aim Aktif ✅" or "[AIM] Nonaktif ❌")
            end
        })

        Group:AddSlider("AimSmoothness", {
            Text = "Kelembutan Aim (0 = instan)",
            Default = 0,
            Min = 0,
            Max = 0.1,
            Rounding = 3,
            Callback = function(Value)
                vars.AimSmoothness = Value
            end
        })

        local function getNearestHead()
            local nearest, dist = nil, math.huge
            for _, model in ipairs(workspace:GetChildren()) do
                if model:IsA("Model") and model.Name == "Male" and model:FindFirstChildOfClass("Humanoid") then
                    for _, child in ipairs(model:GetChildren()) do
                        if string.sub(child.Name,1,3) == "AI_" then
                            local head = model:FindFirstChild("Head")
                            if head then
                                local magnitude = (head.Position - Camera.CFrame.Position).Magnitude
                                if magnitude < dist then
                                    nearest = head
                                    dist = magnitude
                                end
                            end
                            break
                        end
                    end
                end
            end
            return nearest
        end

        RunService.RenderStepped:Connect(function()
            if not vars.ToggleAIM then return end
            local head = getNearestHead()
            if not head then return end

            local currentCF = Camera.CFrame
            local targetCF = CFrame.lookAt(currentCF.Position, head.Position)
            local smooth = vars.AimSmoothness or 0
            Camera.CFrame = currentCF:Lerp(targetCF, smooth)
        end)

        print("✅ AIM_LockHead.lua kompatibel aktif")
    end
}
