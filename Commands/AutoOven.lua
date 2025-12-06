return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main

        if not MainTab then
            warn("[Auto Craft Oven] Tab tidak ditemukan!")
            return
        end

        -- UI GROUP
        local Group = MainTab:AddLeftGroupbox("Auto Craft Oven")

        vars.AutoCraftOven = vars.AutoCraftOven or false
        vars.CraftDelay = vars.CraftDelay or 1 -- default 1 detik

        -- TOGGLE
        Group:AddToggle("ToggleAutoCraftOven", {
            Text = "Auto Craft Oven",
            Default = vars.AutoCraftOven,
            Callback = function(v)
                vars.AutoCraftOven = v
            end
        })

        -- SLIDER DELAY
        Group:AddSlider("SliderCraftDelay", {
            Text = "Delay Craft",
            Default = vars.CraftDelay,
            Min = 0.5,
            Max = 2,
            Rounding = 1,
            Compact = false,
            Callback = function(v)
                vars.CraftDelay = v
            end
        })

        -- SERVICES
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local CraftItem = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Inventory"):WaitForChild("CraftItem")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        -- LOOP SYSTEM (lebih efisien)
        coroutine.wrap(function()
            while true do
                -- tunggu sampai AutoCraftOven aktif
                if not vars.AutoCraftOven then
                    task.wait(0.1) -- delay kecil supaya CPU ringan
                else
                    -- AMBIL SEMUA POSISI OVEN
                    local ovenPositions = {}
                    for _, block in ipairs(LoadedBlocks:GetChildren()) do
                        if block.Name == "Baker's Oven" then
                            local voxel = block:GetAttribute("VoxelPosition")
                            if voxel then
                                table.insert(ovenPositions, voxel)
                            end
                        end
                    end

                    print("Total oven ditemukan:", #ovenPositions)

                    -- AUTO CRAFT SEMUA OVEN
                    for i, pos in ipairs(ovenPositions) do
                        local success, err = pcall(function()
                            CraftItem:InvokeServer("Baker's Oven", "Chocolate Bar", pos)
                        end)

                        if success then
                            print("Craft oven", i, "pada posisi", pos)
                        else
                            warn("Gagal craft oven", i, err)
                        end

                        task.wait(vars.CraftDelay)
                    end
                end
            end
        end)()

        print("[Auto Craft Oven] Sistem aktif.")
    end
}
