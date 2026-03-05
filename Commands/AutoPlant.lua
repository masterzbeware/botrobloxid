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

        ---------------------------------
        -- UI
        ---------------------------------

        local Group = MainTab:AddLeftGroupbox("Auto Planter")

        vars.AutoPlanter  = vars.AutoPlanter or false
        vars.PlanterDelay = vars.PlanterDelay or 0.3
        vars.PlanterMode  = vars.PlanterMode or "Planter Cart"

        _G.BotVars = vars

        -- Toggle
        Group:AddToggle("ToggleAutoPlanter", {
            Text = "Auto Planter",
            Default = vars.AutoPlanter,
            Callback = function(v)
                vars.AutoPlanter = v
                print("[Auto Planter] Toggle:", v and "ON" or "OFF")
            end
        })

        -- Dropdown mode
        Group:AddDropdown("DropdownPlanterMode", {
            Text = "Mode",
            Values = {"Planter Cart","Plant"},
            Default = vars.PlanterMode,
            Multi = false,
            Callback = function(v)
                vars.PlanterMode = v
                print("[Auto Planter] Mode:", v)
            end
        })

        -- Slider delay
        Group:AddSlider("SliderPlanterDelay", {
            Text = "Delay Tanam",
            Default = vars.PlanterDelay,
            Min = 0.1,
            Max = 3,
            Rounding = 1,
            Callback = function(v)
                vars.PlanterDelay = v
            end
        })

        ---------------------------------
        -- SERVICES
        ---------------------------------

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local Relay = ReplicatedStorage
        :WaitForChild("Relay")
        :WaitForChild("Blocks")

        local UsePlanterCart = Relay:WaitForChild("UsePlanterCart")
        local PlantCrop = Relay:WaitForChild("PlantCrop")

        ---------------------------------
        -- LOOP
        ---------------------------------

        coroutine.wrap(function()

            while true do

                if vars.AutoPlanter then

                    for _,block in ipairs(LoadedBlocks:GetChildren()) do

                        if block.Name == "Farmland" then

                            local voxel = block:GetAttribute("VoxelPosition")

                            if voxel then

                                task.spawn(function()

                                    pcall(function()

                                        local pos = vector.create(
                                            voxel.X,
                                            voxel.Y + 1,
                                            voxel.Z
                                        )

                                        if vars.PlanterMode == "Planter Cart" then
                                            UsePlanterCart:InvokeServer(pos)
                                        else
                                            PlantCrop:InvokeServer(pos)
                                        end

                                    end)

                                end)

                                task.wait(0.05)

                            end

                        end

                    end

                    task.wait(vars.PlanterDelay)

                else
                    task.wait(0.5)
                end

            end

        end)()

        print("[Auto Planter] Sistem aktif")

    end
}