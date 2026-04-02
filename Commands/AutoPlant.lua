-- AutoPlanter.lua (robust simple)
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
        vars.PlanterDelay = vars.PlanterDelay or 0.6
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
                    -- ambil snapshot children supaya aman terhadap perubahan realtime
                    local children = LoadedBlocks:GetChildren()
                    for _, block in ipairs(children) do
                        if not vars.AutoPlanter then break end

                        -- pastikan masih valid dan nama Farmland
                        if block and block.Name == "Farmland" and block.Parent then
                            local voxel = nil
                            if block.GetAttribute then
                                voxel = block:GetAttribute("VoxelPosition")
                            end
                            local state = nil
                            if block.GetAttribute then
                                state = block:GetAttribute("State")
                            end

                            -- hanya coba jika voxel ada dan farmland kosong (state == nil)
                            if voxel and state == nil then
                                -- 1) coba invoke dengan voxel langsung
                                local ok, res = pcall(function()
                                    return UsePlanterCart:InvokeServer(vector.create(voxel.X, voxel.Y, voxel.Z))
                                end)

                                if ok and res == true then
                                    -- sukses
                                    -- print minimal supaya console tidak penuh
                                    print(("[AutoPlanter] planted at %d,%d,%d"):format(voxel.X, voxel.Y, voxel.Z))
                                else
                                    -- kalau gagal coba fallback Y+1 (banyak game expect posisi di atas tanah)
                                    local ok2, res2 = pcall(function()
                                        return UsePlanterCart:InvokeServer(vector.create(voxel.X, voxel.Y + 1, voxel.Z))
                                    end)
                                    if ok2 and res2 == true then
                                        print(("[AutoPlanter] planted (fallback) at %d,%d,%d"):format(voxel.X, voxel.Y + 1, voxel.Z))
                                    else
                                        -- jika masih gagal, print ringkas hasil return (nil / false / error)
                                        print(("[AutoPlanter] invoke failed at %d,%d,%d (r1=%s, r2=%s)"):format(
                                            voxel.X, voxel.Y, voxel.Z,
                                            tostring(res), tostring(res2)
                                        ))
                                    end
                                end

                                -- jeda antar invoke agar tidak spam server
                                task.wait(vars.PlanterDelay)
                            end
                        end
                    end

                    -- setelah iterasi semua farmland, beri jeda kecil sebelum loop ulang
                    task.wait(0.5)
                else
                    repeat task.wait(0.5) until vars.AutoPlanter
                end
            end
        end)()

        print("[Auto Planter] Sistem aktif (safe mode)")
    end
}