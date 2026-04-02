-- AutoPlanter.lua (simple fix)
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
        vars.PlanterDelay = vars.PlanterDelay or 0.6 -- sedikit lebih aman
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

                        -- pastikan block punya voxel position dan kosong (tidak punya State)
                        local voxel = nil
                        if block.GetAttribute then
                            voxel = block:GetAttribute("VoxelPosition")
                        end
                        local state = nil
                        if block.GetAttribute then
                            state = block:GetAttribute("State")
                        end

                        if voxel and state == nil then
                            -- coba tanpa offset Y terlebih dahulu (banyak server pakai voxel langsung)
                            local ok, res = pcall(function()
                                return UsePlanterCart:InvokeServer(vector.create(voxel.X, voxel.Y, voxel.Z))
                            end)

                            -- jika gagal / nil, coba fallback Y+1
                            if not (ok and res == true) then
                                pcall(function()
                                    UsePlanterCart:InvokeServer(vector.create(voxel.X, voxel.Y + 1, voxel.Z))
                                end)
                            end

                            task.wait(vars.PlanterDelay)
                        end
                    end

                else
                    repeat task.wait(0.5) until vars.AutoPlanter
                end
            end
        end)()

        print("[Auto Planter] Sistem aktif (simple mode)")

    end
}