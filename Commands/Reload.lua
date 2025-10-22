return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local CombatTab = tab or Tabs.Combat

        if not CombatTab then
            warn("[AutoReload] Tab Combat tidak ditemukan!")
            return
        end

        -- Buat group sendiri
        local Group = CombatTab:AddLeftGroupbox("Auto Reload")

        -- Variabel toggle & delay
        vars.AutoReload = vars.AutoReload ~= false
        vars.ReloadDelay = vars.ReloadDelay or 0.2
        vars.Reloading = false
        vars.MagCheckInterval = 0.1

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        local RemoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvent")

        -- Toggle Auto Reload
        Group:AddToggle("ToggleAutoReload", {
            Text = "Auto Reload",
            Default = vars.AutoReload,
            Callback = function(v)
                vars.AutoReload = v
            end
        })

        -- Slider Reload Delay
        Group:AddSlider("ReloadDelaySlider", {
            Text = "Reload Delay (s)",
            Default = vars.ReloadDelay,
            Min = 0.2,
            Max = 60,
            Rounding = 1,
            Callback = function(v)
                vars.ReloadDelay = v
            end
        })

        -- Fungsi reload
        local function doReload()
            if vars.Reloading then return end
            vars.Reloading = true

            -- Kirim event Reload dari RemoteSpy
            RemoteEvent:FireServer("ActionActor", "b6ca2d2d-dc75-4987-b8b8-085a9a89539c", 0, "Reload", false)

            task.delay(vars.ReloadDelay, function()
                RemoteEvent:FireServer("ActionActor", "cd6c81a7-3f9a-4288-baaa-eb9514dce761", 0, "Reloaded", {
                    Capacity = 30,
                    Name = "M4A1_Stanag_Default",
                    Caliber = "intermediaterifle_556x45mmNATO_M855",
                    UID = "07a4535b-fc24-48c0-9dc4-94d68dddd0df"
                })
                vars.Reloading = false
            end)
        end

        -- Loop pengecekan magazine
        task.spawn(function()
            while task.wait(vars.MagCheckInterval) do
                if vars.AutoReload and not vars.Reloading then
                    local char = player.Character
                    if char then
                        local weapon = char:FindFirstChildWhichIsA("Tool")
                        if weapon and weapon:FindFirstChild("Ammo") then
                            if weapon.Ammo.Value <= 0 then
                                doReload()
                            end
                        end
                    end
                end
            end
        end)

        print("✅ [AutoReload] Toggle siap di CombatTab")
    end
}
