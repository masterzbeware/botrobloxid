return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local OvenTab = tab or Tabs.Main

        if not OvenTab then
            warn("[Auto Oven] Tab Oven tidak ditemukan!")
            return
        end

        local Group = OvenTab:AddLeftGroupbox("Auto Oven")
        vars.AutoOven = vars.AutoOven or false

        Group:AddToggle("ToggleAutoOven", {
            Text = "Auto Oven",
            Default = vars.AutoOven,
            Callback = function(v)
                vars.AutoOven = v
            end
        })

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local CraftItem = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Inventory"):WaitForChild("CraftItem")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        coroutine.wrap(function()
            while true do
                if vars.AutoOven then
                    for _, oven in ipairs(LoadedBlocks:GetChildren()) do
                        if oven.Name == "Baker's Oven" and oven:IsA("Model") then
                            local pos = oven:GetAttribute("VoxelPosition")
                            if pos then
                                pcall(function()
                                    CraftItem:InvokeServer("Baker's Oven", "Chocolate Bar", pos)
                                end)
                                task.wait(0.3)
                            end
                        end
                    end
                    print("Semua oven selesai dicraft!")
                else
                    task.wait(1)
                end
            end
        end)()

        print("Sistem Auto Oven aktif.")
    end
}
