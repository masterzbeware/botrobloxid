-- AutoBucket.lua (FINAL STRUCTURE)
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main

        if not MainTab then
            warn("[AutoBucket] Tab tidak ditemukan!")
            return
        end

        -- =========================
        -- UI GROUP
        -- =========================
        local Group = (MainTab.AddRightGroupbox and MainTab:AddRightGroupbox("Auto Bucket"))
            or MainTab:AddLeftGroupbox("Auto Bucket")

        -- DEFAULT SETTINGS
        vars.AutoBucket = vars.AutoBucket or false
        vars.BucketDelay = vars.BucketDelay or 0.3
        vars.SelectedWell = vars.SelectedWell or "Brick Well"
        _G.BotVars = vars

        -- TOGGLE
        Group:AddToggle("ToggleAutoBucket", {
            Text = "Auto Bucket",
            Default = vars.AutoBucket,
            Callback = function(v)
                vars.AutoBucket = v
                print("[AutoBucket] Status:", v and "ON" or "OFF")
            end
        })

        -- DROPDOWN JENIS WELL
        local wellTypes = {"Brick Well", "Stone Well"}
        task.defer(function()
            local dd = Group:AddDropdown("DropdownWellType", {
                Text = "Target Well",
                Values = wellTypes,
                Default = vars.SelectedWell,
                Callback = function(v)
                    vars.SelectedWell = v
                    print("[AutoBucket] Target Well:", v)
                end
            })
            dd:SetValue(vars.SelectedWell)
        end)

        -- SLIDER DELAY
        Group:AddSlider("SliderBucketDelay", {
            Text = "Delay Fill",
            Min = 0.1, Max = 2,
            Rounding = 2,
            Default = vars.BucketDelay,
            Callback = function(value)
                vars.BucketDelay = value
                print("[AutoBucket] Delay:", value)
            end
        })

        -- =========================
        -- SERVICES
        -- =========================
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local FillBucket = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Inventory")
            :WaitForChild("FillBucket")

        -- =========================
        -- AUTO BUCKET LOOP
        -- =========================
        coroutine.wrap(function()
            while true do
                if vars.AutoBucket then
                    for _, block in ipairs(LoadedBlocks:GetChildren()) do
                        if block:IsA("Model") and block.Name == vars.SelectedWell then
                            local voxel = block:GetAttribute("VoxelPosition")

                            if voxel then
                                pcall(function()
                                    FillBucket:InvokeServer(
                                        vector.create(voxel.X, voxel.Y, voxel.Z)
                                    )
                                end)

                                print("[AutoBucket] Fill:", block.Name)
                                task.wait(vars.BucketDelay)

                                if not vars.AutoBucket then break end
                            end
                        end
                    end
                else
                    repeat task.wait(0.5) until vars.AutoBucket
                end
                task.wait()
            end
        end)()

        print("[AutoBucket] System Loaded ✔")
    end
}
