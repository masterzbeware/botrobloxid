-- AutoPlanter.lua
return {
    Execute = function(tab)

        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main

        if not MainTab then
            warn("[Auto Planter] Tab tidak ditemukan!")
            return
        end

        local Group = MainTab:AddLeftGroupbox("Auto Planter")

        vars.AutoPlanter  = vars.AutoPlanter or false
        vars.PlanterDelay = vars.PlanterDelay or 0.5
        vars.PlanterType  = vars.PlanterType or "Planter Cart"

        _G.BotVars = vars

        --------------------------------------------------
        -- UI
        --------------------------------------------------

        Group:AddToggle("ToggleAutoPlanter", {
            Text = "Auto Planter",
            Default = vars.AutoPlanter,
            Callback = function(v)
                vars.AutoPlanter = v
                print("[Auto Planter] Toggle:", v and "ON" or "OFF")
            end
        })

        Group:AddSlider("SliderPlanterDelay", {
            Text = "Delay Antar Batch",
            Default = vars.PlanterDelay,
            Min = 0.2,
            Max = 4,
            Rounding = 1,
            Callback = function(v)
                vars.PlanterDelay = v
            end
        })

        Group:AddDropdown("DropdownPlanterType", {
            Text = "Planter Mode",
            Values = {"Planter Cart","Plant"},
            Default = vars.PlanterType,
            Callback = function(v)
                vars.PlanterType = v
            end
        })

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local Relay = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Blocks")

        local UsePlanterCart = Relay:WaitForChild("UsePlanterCart")
        local PlantCrop = Relay:WaitForChild("PlantCrop")

        --------------------------------------------------
        -- OCCUPIED CHECK
        --------------------------------------------------

        local function isOccupied(voxel)

            for _,block in ipairs(LoadedBlocks:GetChildren()) do

                local v = block:GetAttribute("VoxelPosition")

                if v and
                   v.X == voxel.X and
                   v.Y == voxel.Y and
                   v.Z == voxel.Z then

                    return true

                end
            end

            return false
        end

        --------------------------------------------------
        -- LOOP
        --------------------------------------------------

        task.spawn(function()

            while true do

                if vars.AutoPlanter then

                    local blocks = LoadedBlocks:GetChildren()

                    for i,block in ipairs(blocks) do

                        if block.Name == "Farmland" then

                            local voxel = block:GetAttribute("VoxelPosition")

                            if voxel then

                                local target = {
                                    X = voxel.X,
                                    Y = voxel.Y + 1,
                                    Z = voxel.Z
                                }

                                if not isOccupied(target) then

                                    local pos = vector.create(
                                        target.X,
                                        target.Y,
                                        target.Z
                                    )

                                    pcall(function()

                                        if vars.PlanterType == "Planter Cart" then
                                            UsePlanterCart:InvokeServer(pos)
                                        else
                                            PlantCrop:InvokeServer(pos)
                                        end

                                    end)

                                end

                            end

                        end

                    end

                end

                task.wait(vars.PlanterDelay)

            end

        end)

        print("[Auto Planter] System Loaded")

    end
}