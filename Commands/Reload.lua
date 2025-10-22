-- Modules/Reload.lua
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local CombatTab = tab or Tabs.Combat

        if not CombatTab then
            warn("[Reload] Tab Combat tidak ditemukan!")
            return
        end

        -- Buat group di CombatTab
        local Group = CombatTab:AddLeftGroupbox("Auto Reload")

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        local RemoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvent")
        local player = Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()

        -- Variabel default
        vars.AutoReload = vars.AutoReload ~= false
        vars.ReloadDelay = vars.ReloadDelay or 1.8
        vars.Reloading = vars.Reloading or false
        vars.MagCheckInterval = vars.MagCheckInterval or 0.1

        -- Toggle AutoReload
            Group:AddToggle("ToggleAutoReload", {
                Text = "Aktifkan Auto Reload",
                Default = vars.AutoReload,
                Callback = function(v)
                    vars.AutoReload = v
                end
            })

        -- Fungsi reload
        local function doReload()
            if vars.Reloading then return end
            vars.Reloading = true
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

        -- Loop auto reload
        task.spawn(function()
            while task.wait(vars.MagCheckInterval) do
                if vars.AutoReload and not vars.Reloading then
                    local weapon = char:FindFirstChildWhichIsA("Tool")
                    if weapon and weapon:FindFirstChild("Ammo") then
                        if weapon.Ammo.Value <= 0 then
                            doReload()
                        end
                    end
                end
            end
        end)

        print("[Reload] Auto reload siap di CombatTab.")
    end
}
