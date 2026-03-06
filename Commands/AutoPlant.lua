-- AutoPlanter.lua
return {
    Execute = function(tab)

        -- =========================
        -- GLOBAL VARS
        -- =========================
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}

        local PlantTab = tab or Tabs.Plant

        if not PlantTab then
            warn("[Auto Planter] Tab Plant tidak ditemukan!")
            return
        end

        -- =========================
        -- UI GROUP
        -- =========================
        local Group = PlantTab:AddLeftGroupbox("Auto Planter")

        -- =========================
        -- DEFAULT VARS
        -- =========================
        vars.AutoPlanter = vars.AutoPlanter or false
        vars.PlanterDelay = vars.PlanterDelay or 0.4

        _G.BotVars = vars

        -- =========================
        -- TOGGLE
        -- =========================
        Group:AddToggle("ToggleAutoPlanter", {
            Text = "Auto Planter",
            Default = vars.AutoPlanter,
            Callback = function(v)
                vars.AutoPlanter = v
                print("[Auto Planter]", v and "ON" or "OFF")
            end
        })

        -- =========================
        -- DELAY SLIDER
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

                        if not vars.AutoPlanter then
                            break
                        end

                        -- hanya farmland
                        if block.Name == "Farmland" then

                            local voxel = block:GetAttribute("VoxelPosition")

                            if voxel then

                                local success, err = pcall(function()

                                    UsePlanterCart:InvokeServer(
                                        vector.create(
                                            voxel.X,
                                            voxel.Y,
                                            voxel.Z
                                        )
                                    )

                                end)

                                if not success then
                                    warn("[AutoPlanter Error]", err)
                                end

                                -- delay agar tidak spam server
                                task.wait(vars.PlanterDelay)

                            end

                        end

                    end

                    -- jeda sebelum scan ulang
                    task.wait(0.2)

                else
                    repeat task.wait(0.5) until vars.AutoPlanter
                end

            end

        end)()

        print("[Auto Planter] Sistem aktif")

    end
}