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

        -- =========================
        -- UI GROUP
        -- =========================
        local Group = MainTab:AddLeftGroupbox("Auto Planter")

        -- =========================
        -- DEFAULT VARS
        -- =========================
        vars.AutoPlanter  = vars.AutoPlanter or false
        vars.PlanterDelay = vars.PlanterDelay or 0.3
        _G.BotVars = vars

        -- =========================
        -- TOGGLE
        -- =========================
        Group:AddToggle("ToggleAutoPlanter", {
            Text = "Auto Planter",
            Default = vars.AutoPlanter,
            Callback = function(v)
                vars.AutoPlanter = v
                print("[Auto Planter] Toggle:", v and "ON" or "OFF")
            end
        })

        -- =========================
        -- SLIDER DELAY
        -- =========================
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

        -- =========================
        -- SERVICES
        -- =========================
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local UsePlanterCart = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Blocks")
            :WaitForChild("UsePlanterCart")

        -- =========================
        -- AUTO PLANT LOOP
        -- =========================
        coroutine.wrap(function()
            while true do
                if vars.AutoPlanter then

                    for _, block in ipairs(LoadedBlocks:GetChildren()) do

                        if block.Name == "Farmland" then

                            local voxel = block:GetAttribute("VoxelPosition")

                            if voxel then
                                task.spawn(function()
                                    pcall(function()
                                        UsePlanterCart:InvokeServer(
                                            vector.create(
                                                voxel.X,
                                                voxel.Y + 1,
                                                voxel.Z
                                            )
                                        )
                                    end)
                                end)

                                task.wait(0.1)
                            end

                        end

                    end

                    task.wait(vars.PlanterDelay)

                else
                    repeat task.wait(0.5) until vars.AutoPlanter
                end
            end
        end)()

        print("[Auto Planter] Sistem aktif")
    end
}