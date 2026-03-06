-- AutoPlanter.lua
return {
    Execute = function(tab)

        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}

        local PlantTab = tab or Tabs.Plant
        if not PlantTab then
            warn("[Auto Planter] Tab Plant tidak ditemukan!")
            return
        end

        local Group = PlantTab:AddLeftGroupbox("Auto Planter")

        vars.AutoPlanter  = vars.AutoPlanter or false
        vars.PlanterDelay = vars.PlanterDelay or 0.3
        _G.BotVars = vars

        Group:AddToggle("ToggleAutoPlanter", {
            Text = "Auto Planter",
            Default = vars.AutoPlanter,
            Callback = function(v)
                vars.AutoPlanter = v
                print("[Auto Planter]", v and "ON" or "OFF")
            end
        })

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

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local UsePlanterCart = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Blocks")
            :WaitForChild("UsePlanterCart")

        coroutine.wrap(function()

            while true do

                if vars.AutoPlanter then

                    for _, block in ipairs(LoadedBlocks:GetChildren()) do

                        if not vars.AutoPlanter then break end

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

                                task.wait(vars.PlanterDelay)

                            end
                        end
                    end

                else
                    repeat task.wait(0.5) until vars.AutoPlanter
                end

            end

        end)()

        print("[Auto Planter] Sistem aktif")

    end
}