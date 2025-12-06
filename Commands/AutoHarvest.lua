return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main

        if not MainTab then
            warn("[Auto Harvest] Tab tidak ditemukan!")
            return
        end

        -- UI GROUP
        local Group = MainTab:AddRightGroupbox("Auto Harvest Blocks")

        vars.AutoHarvest = vars.AutoHarvest or false
        vars.HarvestDelay = vars.HarvestDelay or 1 -- default 1 detik
        vars.HarvestTarget = vars.HarvestTarget or "Mushroom Box" -- default target

        -- TOGGLE
        Group:AddToggle("ToggleAutoHarvest", {
            Text = "Auto Harvest",
            Default = vars.AutoHarvest,
            Callback = function(v)
                vars.AutoHarvest = v
            end
        })

        -- DROPDOWN PILIH MODEL
        Group:AddDropdown("DropdownHarvestTarget", {
            Text = "Pilih Model",
            Default = vars.HarvestTarget,
            Options = {"Mushroom Box", "White Cow", "Treetap", "Compost Bin"},
            Callback = function(v)
                vars.HarvestTarget = v
            end
        })

        -- SLIDER DELAY
        Group:AddSlider("SliderHarvestDelay", {
            Text = "Delay Harvest",
            Default = vars.HarvestDelay,
            Min = 0.5,
            Max = 2,
            Rounding = 1,
            Compact = false,
            Callback = function(v)
                vars.HarvestDelay = v
            end
        })

        -- SERVICES
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local HarvestCrop = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks"):WaitForChild("HarvestCrop")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        -- LOOP SYSTEM (lebih efisien)
        coroutine.wrap(function()
            while true do
                if not vars.AutoHarvest then
                    task.wait(0.1) -- delay kecil supaya CPU ringan
                else
                    -- LOOP SEMUA BLOCK
                    for _, block in ipairs(LoadedBlocks:GetChildren()) do
                        if block.Name == vars.HarvestTarget then
                            local voxel = block:GetAttribute("VoxelPosition")
                            if voxel then
                                local args = { vector.create(voxel.X, voxel.Y, voxel.Z) }
                                local success, err = pcall(function()
                                    HarvestCrop:InvokeServer(unpack(args))
                                end)
                                if not success then
                                    warn("Gagal harvest:", err)
                                end
                            end
                        end
                    end

                    task.wait(vars.HarvestDelay)
                end
            end
        end)()

        print("[Auto Harvest] Sistem aktif. Target:", vars.HarvestTarget)
    end
}
