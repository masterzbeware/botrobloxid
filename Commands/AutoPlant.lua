-- AutoPlanter.lua (one-by-one, batch delay + dropdown)
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

        vars.AutoPlanter   = vars.AutoPlanter or false
        vars.PlanterDelay  = vars.PlanterDelay or 0.5
        vars.PlanterType   = vars.PlanterType or "Planter Cart" -- 🔥 default
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

        -- Slider Delay
        Group:AddSlider("SliderPlanterDelay", {
            Text = "Delay Antar Batch",
            Default = vars.PlanterDelay,
            Min = 0.5,
            Max = 4,
            Rounding = 1,
            Callback = function(v)
                vars.PlanterDelay = v
            end
        })

        -- 🔽 DROPDOWN PLANTER TYPE
        Group:AddDropdown("DropdownPlanterType", {
            Text = "Planter Mode",
            Values = { "Planter Cart", "Plant" },
            Default = vars.PlanterType,
            Callback = function(v)
                vars.PlanterType = v
                print("[Auto Planter] Mode:", v)
            end
        })

        -- Services
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
        local Relay = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks")

        local UsePlanterCart = Relay:WaitForChild("UsePlanterCart")
        local PlantCrop = Relay:WaitForChild("PlantCrop")

        -- Cek voxel kosong
        local function isOccupied(voxel)
            for _, block in ipairs(LoadedBlocks:GetChildren()) do
                local v2 = block:GetAttribute("VoxelPosition")
                if v2 and v2.X == voxel.X and v2.Y == voxel.Y and v2.Z == voxel.Z then
                    return true
                end
            end
            return false
        end

        -- Loop utama
        coroutine.wrap(function()
            while true do
                if vars.AutoPlanter then
                    for i, block in ipairs(LoadedBlocks:GetChildren()) do
                        if block.Name == "Farmland" then
                            local voxel = block:GetAttribute("VoxelPosition")
                            if voxel then
                                local above = Vector3.new(voxel.X, voxel.Y + 1, voxel.Z)
                                if not isOccupied(above) then
                                    task.spawn(function()
                                        local success, err = pcall(function()
                                            if vars.PlanterType == "Planter Cart" then
                                                UsePlanterCart:InvokeServer(above)
                                            else
                                                PlantCrop:InvokeServer(above)
                                            end
                                        end)

                                        if success then
                                            print(vars.PlanterType, "ke-", i, "berhasil")
                                        else
                                            warn("Gagal", vars.PlanterType, "ke-", i, err)
                                        end
                                    end)
                                    task.wait(0.1)
                                end
                            end
                        end
                    end
                    task.wait(vars.PlanterDelay)
                else
                    task.wait(1)
                end
            end
        end)()

        print("[Auto Planter] Sistem aktif.")
    end
}
