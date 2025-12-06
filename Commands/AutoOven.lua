return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local OvenTab = tab or Tabs.Oven

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
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
        local CraftItem = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Inventory"):WaitForChild("CraftItem")

        coroutine.wrap(function()
            while true do
                if vars.AutoOven then
                    for i, block in ipairs(LoadedBlocks:GetChildren()) do
                        if block.Name == "Baker's Oven" then
                            local voxel = block:GetAttribute("VoxelPosition")
                            if voxel then
                                local success, err = pcall(function()
                                    CraftItem:InvokeServer("Baker's Oven", "Chocolate Bar", voxel)
                                end)
                                if success then
                                    print("Craft oven ke", i, "selesai")
                                else
                                    warn("Gagal craft oven ke", i, err)
                                end
                                task.wait(0.3)
                            end
                        end
                    end

                    task.wait(181) -- delay antar loop
                else
                    task.wait(1) -- cek toggle
                end
            end
        end)()

        print("Auto Oven siap digunakan di tab Oven.")
    end
}
