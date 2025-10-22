return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local CombatTab = tab or Tabs.Combat

        if not CombatTab then
            warn("[FastReload] Tab Combat tidak ditemukan!")
            return
        end

        -- Buat group sendiri
        local Group = CombatTab:AddLeftGroupbox("Fast Reload (M4A1)")

        -- Variabel toggle & delay
        vars.FastReload = vars.FastReload or false -- default OFF
        vars.ReloadDelay = 0.2
        vars.Reloading = false
        vars.CheckInterval = 0.1

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        local RemoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvent")

        -- Toggle Fast Reload
        Group:AddToggle("ToggleFastReloadM4A1", {
            Text = "Fast Reload M4A1",
            Default = vars.FastReload,
            Callback = function(v)
                vars.FastReload = v
            end
        })

        -- Fungsi reload
        local function doReload()
            if vars.Reloading then return end
            vars.Reloading = true

            -- Fire reload event khusus M4A1
            RemoteEvent:FireServer("ActionActor", "1c00b1bc-e1c0-41fe-a364-a927ded71fb9", 0, "Reload", true)
            RemoteEvent:FireServer("InventoryAction", "034e5a27-6202-4760-b3b2-5ba0fec6d820", "Reload", {
                Capacity = 30,
                Name = "M4A1_Stanag_Default",
                Caliber = "intermediaterifle_556x45mmNATO_M855"
            })

            task.delay(vars.ReloadDelay, function()
                vars.Reloading = false
            end)
        end

        -- Loop pengecekan magazine M4A1
        task.spawn(function()
            while task.wait(vars.CheckInterval) do
                if vars.FastReload and not vars.Reloading then
                    local char = player.Character
                    if char then
                        local weapon = char:FindFirstChildWhichIsA("Tool")
                        if weapon and weapon.Name:match("M4A1") and weapon:FindFirstChild("Ammo") then
                            if weapon.Ammo.Value <= 0 then
                                doReload()
                            end
                        end
                    end
                end
            end
        end)

        print("✅ [FastReload] Toggle siap di CombatTab")
    end
}
