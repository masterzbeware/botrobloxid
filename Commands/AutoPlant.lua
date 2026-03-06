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

        vars.AutoPlanter = vars.AutoPlanter or false
        vars.PlanterDelay = vars.PlanterDelay or 0.25
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
            Min = 0.05,
            Max = 3,
            Rounding = 2,
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
        -- FUNCTION CEK TANAMAN
        -- =========================
        local function hasCrop(voxel, blocks)

            for _, block in ipairs(blocks) do

                local id = block:GetAttribute("ID")
                local otherVoxel = block:GetAttribute("VoxelPosition")

                if id and id ~= 1 and otherVoxel then
                    if otherVoxel.X == voxel.X
                    and otherVoxel.Y == voxel.Y
                    and otherVoxel.Z == voxel.Z then
                        return true
                    end
                end

            end

            return false
        end

        -- =========================
        -- AUTO PLANT LOOP
        -- =========================
        coroutine.wrap(function()

            while true do

                if vars.AutoPlanter then

                    local blocks = LoadedBlocks:GetChildren()

                    for _, farmland in ipairs(blocks) do

                        if not vars.AutoPlanter then break end

                        local id = farmland:GetAttribute("ID")

                        -- hanya farmland
                        if id == 1 then

                            local voxel = farmland:GetAttribute("VoxelPosition")

                            if voxel and not hasCrop(voxel, blocks) then

                                pcall(function()

                                    UsePlanterCart:InvokeServer(
                                        vector.create(
                                            voxel.X,
                                            voxel.Y,
                                            voxel.Z
                                        )
                                    )

                                end)

                                task.wait(vars.PlanterDelay)

                            end

                        end

                    end

                    task.wait(0.2)

                else
                    repeat task.wait(0.5) until vars.AutoPlanter
                end

            end

        end)()

        print("[Auto Planter] Sistem aktif")

    end
}