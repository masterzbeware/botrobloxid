-- AutoWater.lua
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main

        if not MainTab then
            warn("[AutoWater] MainTab tidak ditemukan!")
            return
        end

        -- UI GROUP
        local Group = MainTab:AddLeftGroupbox("Auto Water System")

        -- DEFAULT VARS
        vars.AutoWater = vars.AutoWater or false
        vars.WellTarget = vars.WellTarget or "Brick Well"
        vars.TroughTarget = vars.TroughTarget or "Small Water Trough"
        vars.WaterDelay = vars.WaterDelay or 0.5
        _G.BotVars = vars

        -- TOGGLE
        Group:AddToggle("ToggleAutoWater", {
            Text = "Auto Water",
            Default = vars.AutoWater,
            Callback = function(v)
                vars.AutoWater = v
                print("[AutoWater] Toggle:", v and "ON" or "OFF")
            end
        })

        -- MODEL OPTIONS
        local wellModels = {
            "Brick Well",
            "Stone Well"
        }

        local troughModels = {
            "Small Water Trough",
            "Large Water Trough"
        }

        -- DROPDOWN WELL
        Group:AddDropdown("DropdownWellTarget", {
            Text = "Pilih Well",
            Values = wellModels,
            Default = vars.WellTarget,
            Multi = false,
            Callback = function(v)
                vars.WellTarget = v
                print("[AutoWater] Well dipilih:", v)
            end
        })

        -- DROPDOWN TROUGH
        Group:AddDropdown("DropdownTroughTarget", {
            Text = "Pilih Water Trough",
            Values = troughModels,
            Default = vars.TroughTarget,
            Multi = false,
            Callback = function(v)
                vars.TroughTarget = v
                print("[AutoWater] Trough dipilih:", v)
            end
        })

        -- DELAY SLIDER
        Group:AddSlider("SliderWaterDelay", {
            Text = "Delay Water",
            Default = vars.WaterDelay,
            Min = 0.2,
            Max = 3,
            Rounding = 1,
            Callback = function(v)
                vars.WaterDelay = v
            end
        })

        -- SERVICES
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local FillBucket = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Inventory")
            :WaitForChild("FillBucket")

        local InsertItem = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Blocks")
            :WaitForChild("InsertItem")

        -- LOOP SYSTEM
        coroutine.wrap(function()
            while true do
                if vars.AutoWater then
                    local wells = {}
                    local troughs = {}

                    -- FILTER BERDASARKAN DROPDOWN
                    for _, block in ipairs(LoadedBlocks:GetChildren()) do
                        if block:IsA("Model") then
                            if block.Name == vars.WellTarget then
                                table.insert(wells, block)
                            elseif block.Name == vars.TroughTarget then
                                table.insert(troughs, block)
                            end
                        end
                    end

                    -- PAIR OTOMATIS
                    local total = math.min(#wells, #troughs)

                    for i = 1, total do
                        local well = wells[i]
                        local trough = troughs[i]

                        -- FILL WELL
                        local wellVoxel = well:GetAttribute("VoxelPosition")
                        if wellVoxel then
                            pcall(function()
                                FillBucket:InvokeServer(
                                    vector.create(
                                        wellVoxel.X,
                                        wellVoxel.Y,
                                        wellVoxel.Z
                                    )
                                )
                            end)
                            print("[AutoWater] Fill Well ke-", i)
                        end

                        task.wait(vars.WaterDelay)

                        -- INSERT KE TROUGH
                        local troughVoxel = trough:GetAttribute("VoxelPosition")
                        if troughVoxel then
                            pcall(function()
                                InsertItem:InvokeServer(
                                    vector.create(
                                        troughVoxel.X,
                                        troughVoxel.Y,
                                        troughVoxel.Z
                                    )
                                )
                            end)
                            print("[AutoWater] Insert Trough ke-", i)
                        end

                        task.wait(vars.WaterDelay)
                    end

                else
                    task.wait(0.5)
                end
            end
        end)()

        print("[AutoWater] Sistem aktif")
    end
}
