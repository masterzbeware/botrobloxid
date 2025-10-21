-- AIM.lua
-- 🎯 Auto Aim Lengket ke Kepala NPC "Male"

return {
    Execute = function()
        local vars = _G.BotVars
        local Window = vars.MainWindow
        local Camera = workspace.CurrentCamera
        local RunService = game:GetService("RunService")

        -- UI Tab
        local Tabs = { Aim = Window:AddTab("AIM", "crosshair") }
        local Group = Tabs.Aim:AddLeftGroupbox("AIM Assist Control")

        Group:AddToggle("EnableAIM", {
            Text = "Aktifkan Aim Assist Lengket (Lock Kepala)",
            Default = false,
            Callback = function(Value)
                vars.ToggleAIM = Value
                print(Value and "[AIM] Lengket Aim Assist Aktif ✅" or "[AIM] Nonaktif ❌")
            end
        })

        -- Cari kepala NPC terdekat (head only)
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

        -- Auto Aim Lock Kepala
        RunService.RenderStepped:Connect(function()
            if not vars.ToggleAIM then return end

            local head = getNearestHead()
            if not head then return end

            -- Kamera langsung lock ke kepala target
            local currentCF = Camera.CFrame
            local targetCF = CFrame.lookAt(currentCF.Position, head.Position)
            Camera.CFrame = currentCF:Lerp(targetCF, 0.01) -- 0.01 = super lengket
        end)

        print("✅ AIM.lua aktif — kamera otomatis lengket ke kepala NPC")
    end
}
