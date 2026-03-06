-- AutoMine.lua
return {
    Execute = function(tab)

        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}

        -- gunakan tab Harvest
        local HarvestTab = tab or Tabs.Harvest

        if not HarvestTab then
            warn("[Auto Mine] Tab Harvest tidak ditemukan!")
            return
        end

        -- UI GROUP
        local Group = HarvestTab:AddLeftGroupbox("Auto Mine Rocks")

        -- DEFAULT VARS
        vars.AutoMine = vars.AutoMine or false
        vars.MineDelay = vars.MineDelay or 0.3

        _G.BotVars = vars

        -- ROCK LIST
        local validRocks = {
            ["Rocky Nature Bunch"] = true,
            ["Small Rock"] = true,
            ["Copper Ore"] = true,
            ["Silver Ore"] = true,
            ["Gold Ore"] = true
        }

        -- TOGGLE AUTO MINE
        Group:AddToggle("ToggleAutoMine", {
            Text = "Auto Mine Rocks",
            Default = vars.AutoMine,
            Callback = function(v)
                vars.AutoMine = v
            end
        })

        -- SLIDER DELAY
        Group:AddSlider("SliderMineDelay", {
            Text = "Mine Delay",
            Default = vars.MineDelay,
            Min = 0.1,
            Max = 2,
            Rounding = 2,
            Callback = function(v)
                vars.MineDelay = v
            end
        })

        -- SERVICES
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local MineBlock = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks"):WaitForChild("MineBlock")

        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        -- SCAN ROCK
        local function scanAndMine()

            for _, block in ipairs(LoadedBlocks:GetChildren()) do

                if validRocks[block.Name] then

                    local voxel = block:GetAttribute("VoxelPosition")

                    if voxel then
                        pcall(function()
                            MineBlock:InvokeServer(
                                vector.create(voxel.X, voxel.Y, voxel.Z)
                            )
                        end)

                        task.wait(vars.MineDelay)
                    end

                end

            end

        end

        -- LOOP
        task.spawn(function()

            while true do

                if vars.AutoMine then
                    scanAndMine()
                else
                    task.wait(0.5)
                end

            end

        end)

        print("[Auto Mine] Loaded")

    end
}