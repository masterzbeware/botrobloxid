-- M4A1_Mod.lua
return {
    Execute = function(tab)
        local vars = _G.GunVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main

        if not MainTab then
            warn("[M4A1 MOD] Tab tidak ditemukan!")
            return
        end

        -- UI GROUP
        local Group = MainTab:AddLeftGroupbox("M4A1 Mod")

        -- DEFAULT VARS
        vars.M4A1Enabled = vars.M4A1Enabled or false
        _G.GunVars = vars

        -- TOGGLE
        Group:AddToggle("ToggleM4A1", {
            Text = "M4A1 1000 Damage + No Recoil",
            Default = vars.M4A1Enabled,
            Callback = function(v)
                vars.M4A1Enabled = v
                print("[M4A1 MOD]", v and "ON" or "OFF")
            end
        })

        -- SERVICES
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local CombatRE = ReplicatedStorage
            :WaitForChild("GunSystemAssest")
            :WaitForChild("Packages")
            :WaitForChild("Knit")
            :WaitForChild("Services")
            :WaitForChild("CombatService")
            :WaitForChild("RE")

        -- LOOP APPLY MOD
        coroutine.wrap(function()
            while true do
                if vars.M4A1Enabled then
                    local player = Players.LocalPlayer
                    local char = player.Character
                    if char and char:FindFirstChild("M4A1") then
                        local gun = char.M4A1

                        pcall(function()
                            CombatRE.Holster:FireServer(gun, {
                                Damage = 1000,
                                Recoil = 0,
                                Spread_X = 0,
                                Spread_Y = 0,
                                Spread_IncreasePS = 0,
                                RandomizedDamage = false
                            }, false)
                        end)
                    end
                    task.wait(0.3)
                else
                    task.wait(0.5)
                end
            end
        end)()

        print("[M4A1 MOD] Sistem aktif")
    end
}
