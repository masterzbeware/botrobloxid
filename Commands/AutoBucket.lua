-- AutoBucket.lua (REWORK FINAL FIX)

return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main

        if not MainTab then
            warn("[AutoBucket] Tab tidak ditemukan!")
            return
        end

        -- UI GROUP
        local Group = (typeof(MainTab.AddRightGroupbox) == "function")
            and MainTab:AddRightGroupbox("Auto Fill")
            or MainTab:AddLeftGroupbox("Auto Fill")

        -- DEFAULT SETTINGS
        vars.AutoFill = vars.AutoFill or false
        vars.FillDelay = vars.FillDelay or 0.2 -- DEFAULT MATCH YOUR MANUAL CODE
        vars.FillTarget = vars.FillTarget or {"Brick Well", "Stone Well"}

        _G.BotVars = vars

        -- SERVICES
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local FillBucket = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Inventory")
            :WaitForChild("FillBucket")

        local vector = _G.vector or vector -- ***IMPORTANT FIX***
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        -- UI: TOGGLE
        Group:AddToggle("ToggleAutoFill", {
            Text = "Auto Fill Well",
            Default = vars.AutoFill,
            Callback = function(v)
                vars.AutoFill = v
                print("[AutoBucket] Status:", v and "Aktif" or "Mati")
            end
        })

        -- UI: DROPDOWN TARGET
        task.delay(0.7, function()
            if Group.AddDropdown then
                Group:AddDropdown("DropdownFillTarget", {
                    Text = "Pilih Well",
                    Values = {"Brick Well", "Stone Well"},
                    Multi = true,
                    Default = vars.FillTarget,
                    Callback = function(v)
                        vars.FillTarget = v
                        print("[AutoBucket] Target:", table.concat(v, ", "))
                    end
                })
            end
        end)

        -- UI: SLIDER DELAY
        Group:AddSlider("FillDelaySlider", {
            Text = "Delay Fill (detik)",
            Default = vars.FillDelay,
            Min = 0.1,
            Max = 2,
            Rounding = 0.1,
            Callback = function(v)
                vars.FillDelay = v
            end
        })

        --------------------------------------------------------------------
        --                      MAIN LOOP FIXED                           --
        --------------------------------------------------------------------
        task.spawn(function()
            while task.wait(vars.FillDelay) do
                if not vars.AutoFill then continue end

                local blocks = LoadedBlocks:GetChildren()
                for i, block in ipairs(blocks) do
                    if not vars.AutoFill then break end
                    if not block:IsA("Model") then continue end
                    if not table.find(vars.FillTarget, block.Name) then continue end

                    local voxel = block:GetAttribute("VoxelPosition")
                    if not voxel then continue end

                    -- Spawn agar tidak freeze (MATCH ORIGINAL SCRIPT)
                    task.spawn(function()
                        local args = {
                            vector.create(voxel.X, voxel.Y, voxel.Z)
                        }

                        local ok, err = pcall(function()
                            FillBucket:InvokeServer(unpack(args))
                        end)

                        if ok then
                            print("Fill Well ke-", i, block.Name, "✓")
                        else
                            warn("Gagal Fill", block.Name, "ke-", i, err)
                        end
                    end)

                    task.wait(0.05) -- optimized smooth loop
                end
            end
        end)

        print("[AutoBucket] System Ready ✓")
    end
}
