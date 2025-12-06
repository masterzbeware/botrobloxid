return { 
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local OvenTab = tab or Tabs.Main

        if not OvenTab then
            warn("[Auto Oven] Tab Oven tidak ditemukan!")
            return
        end

        local Group = OvenTab:AddLeftGroupbox("Auto Oven + Crop")

        vars.AutoOven = vars.AutoOven or false
        vars.AutoCrop = vars.AutoCrop or false

        Group:AddToggle("ToggleAutoOven", {
            Text = "Auto Oven",
            Default = vars.AutoOven,
            Callback = function(v)
                vars.AutoOven = v
            end
        })

        Group:AddToggle("ToggleAutoCrop", {
            Text = "Auto Crop",
            Default = vars.AutoCrop,
            Callback = function(v)
                vars.AutoCrop = v
            end
        })

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local CraftItem = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Inventory"):WaitForChild("CraftItem")
        local HarvestCrop = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks"):WaitForChild("HarvestCrop")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        -- Coroutine untuk loop auto oven & crop
        coroutine.wrap(function()
            while true do
                if vars.AutoOven then
                    -- Auto Craft semua Baker's Oven berdasarkan VoxelPosition
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
                    print("Semua oven selesai dicraft! Tunggu 3 menit 20 detik sebelum panen crop...")
                    task.wait(181)
                else
                    task.wait(1)
                end

                if vars.AutoCrop then
                    -- Auto Crop semua Mushroom Box berdasarkan VoxelPosition
                    for _, block in ipairs(LoadedBlocks:GetChildren()) do
                        if block.Name == "Mushroom Box" and block:IsA("Model") then
                            local pos = block:GetAttribute("VoxelPosition")
                            if pos then
                                pcall(function()
                                    HarvestCrop:InvokeServer(pos)
                                end)
                                task.wait(0.2)
                            end
                        end
                    end
                    print("Semua crop selesai dipanen! Ulangi dari awal...")
                else
                    task.wait(1)
                end
            end
        end)()

        print("Sistem Auto Oven + Crop aktif.")
    end
}
