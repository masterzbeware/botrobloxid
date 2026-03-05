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

        ------------------------------------------------
        -- UI
        ------------------------------------------------

        local Group = MainTab:AddLeftGroupbox("Auto Planter")

        vars.AutoPlanter  = vars.AutoPlanter or false
        vars.PlanterDelay = vars.PlanterDelay or 0.2
        _G.BotVars = vars

        Group:AddToggle("ToggleAutoPlanter", {
            Text = "Auto Planter",
            Default = vars.AutoPlanter,
            Callback = function(v)
                vars.AutoPlanter = v
                print("[Auto Planter] Toggle:", v and "ON" or "OFF")
            end
        })

        Group:AddSlider("SliderPlanterDelay", {
            Text = "Delay Batch",
            Default = vars.PlanterDelay,
            Min = 0.05,
            Max = 2,
            Rounding = 2,
            Callback = function(v)
                vars.PlanterDelay = v
            end
        })

        ------------------------------------------------
        -- SERVICES
        ------------------------------------------------

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local UsePlanterCart = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Blocks")
            :WaitForChild("UsePlanterCart")

        ------------------------------------------------
        -- AUTO LOOP
        ------------------------------------------------

        coroutine.wrap(function()

            while true do

                if vars.AutoPlanter then

                    local blocks = LoadedBlocks:GetChildren()

                    for i = 1, #blocks do

                        local block = blocks[i]

                        if block.Name == "Farmland" then

                            local voxel = block:GetAttribute("VoxelPosition")

                            if voxel then

                                pcall(function()

                                    UsePlanterCart:InvokeServer(
                                        vector.create(
                                            voxel.X,
                                            voxel.Y + 1,
                                            voxel.Z
                                        )
                                    )

                                end)

                            end

                        end

                    end

                    task.wait(vars.PlanterDelay)

                else
                    repeat task.wait(0.5) until vars.AutoPlanter
                end

            end

        end)()

        print("[Auto Planter] Fast System Loaded")

    end
}