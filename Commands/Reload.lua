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
        vars.AutoReload = vars.AutoReload or false -- default OFF
        vars.ReloadDelay = vars.ReloadDelay or 0.2
        vars.Reloading = false
        vars.CheckInterval = 0.1

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

            RemoteEvent:FireServer("ActionActor", "9c2920ee-d73e-4cb5-a424-cee16330ff40", 0, "Reload", true)

            task.delay(vars.ReloadDelay, function()
                vars.Reloading = false
            end)
        end

        -- Loop pengecekan magazine
        task.spawn(function()
            while task.wait(vars.CheckInterval) do
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
