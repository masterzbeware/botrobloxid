-- AutoPlanter (improved/debug)
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

        -- helper: try invoke and log result
        local function tryInvokeVoxel(vox)
            if not vox then return false, "no_voxel" end
            local ok, res = pcall(function()
                return UsePlanterCart:InvokeServer(vector.create(vox.X, vox.Y, vox.Z))
            end)
            print(("[AutoPlant] InvokeServer voxel=%s ok=%s res=%s"):format(tostring(vox), tostring(ok), tostring(res)))
            return ok and res, (ok and res) or res
        end

        coroutine.wrap(function()
            while true do
                if vars.AutoPlanter then
                    local count = #LoadedBlocks:GetChildren()
                    print("[AutoPlant] loadedblocks_count=", count)
                    local anyTried = false

                    for _, block in ipairs(LoadedBlocks:GetChildren()) do
                        if not vars.AutoPlanter then break end

                        -- prefer attribute "VoxelPosition" (safer than Name)
                        local voxel = nil
                        if block.GetAttribute then
                            voxel = block:GetAttribute("VoxelPosition")
                        end
                        -- fallback: if block has a Vector3 child named VoxelPosition (unlikely) or property
                        if not voxel and block:FindFirstChild("VoxelPosition") and block.VoxelPosition.Value then
                            voxel = block.VoxelPosition.Value
                        end

                        if voxel and typeof(voxel) == "Vector3" then
                            anyTried = true
                            -- try without offset first
                            local success = false
                            local ok, res = tryInvokeVoxel(voxel)
                            if ok then
                                success = true
                            else
                                -- fallback: try Y+1 (some servers expect top coordinate)
                                local voxUp = Vector3.new(voxel.X, voxel.Y + 1, voxel.Z)
                                ok, res = tryInvokeVoxel(voxUp)
                                if ok then success = true end
                            end

                            task.wait(vars.PlanterDelay)
                        end
                    end

                    if not anyTried then
                        -- nothing to try right now
                        task.wait(1)
                    end

                else
                    repeat task.wait(0.5) until vars.AutoPlanter
                end
            end
        end)()

        print("[Auto Planter] Sistem aktif (improved)")

    end
}