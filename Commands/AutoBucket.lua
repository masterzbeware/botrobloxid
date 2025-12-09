-- AutoBucket.lua (REWORK FINAL-V2)
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main

        if not MainTab then
            warn("[AutoBucket] Tab tidak ditemukan!")
            return
        end

        -- ========================
        -- UI GROUP SAFE CHECK
        -- ========================
        local Group = (typeof(MainTab.AddRightGroupbox) == "function")
            and MainTab:AddRightGroupbox("Auto Fill")
            or MainTab:AddLeftGroupbox("Auto Fill")

        -- DEFAULT VARIABLES
        vars.AutoFill = vars.AutoFill or false
        vars.FillDelay = vars.FillDelay or 0.2
        vars.FillTarget = vars.FillTarget or {"Brick Well", "Stone Well"}
        _G.BotVars = vars

        -- SERVICES
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local vector = _G.vector or vector
        local FillBucket = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Inventory")
            :WaitForChild("FillBucket")

        -- ========================
        -- UI COMPONENTS
        -- ========================
        Group:AddToggle("ToggleAutoFill", {
            Text = "Auto Fill Well",
            Default = vars.AutoFill,
            Callback = function(v)
                vars.AutoFill = v
            end
        })

        task.delay(0.7, function()
            if Group.AddDropdown then
                Group:AddDropdown("DropdownFillTarget", {
                    Text = "Target Well",
                    Values = {"Brick Well", "Stone Well"},
                    Multi = true,
                    Default = vars.FillTarget,
                    Callback = function(v)
                        vars.FillTarget = v
                    end
                })
            end
        end)

        Group:AddSlider("FillDelaySlider", {
            Text = "Delay Fill",
            Default = vars.FillDelay,
            Min = 0.1,
            Max = 1,
            Rounding = 0.1,
            Callback = function(v)
                vars.FillDelay = v
            end
        })

        -- ========================
        -- MAIN AUTO BUCKET LOOP
        -- ========================
        task.spawn(function()
            while true do
                task.wait(vars.FillDelay)

                if not vars.AutoFill then continue end

                local wells = LoadedBlocks:GetChildren()
                for i, block in ipairs(wells) do
                    if not vars.AutoFill then break end
                    if not block:IsA("Model") then continue end
                    if not table.find(vars.FillTarget, block.Name) then continue end

                    local voxel = block:GetAttribute("VoxelPosition")
                    if not voxel then continue end

                    task.spawn(function()
                        local args = {
                            vector.create(voxel.X, voxel.Y, voxel.Z)
                        }

                        local success, err = pcall(function()
                            FillBucket:InvokeServer(unpack(args))
                        end)

                        if not success then
                            warn("[AutoBucket] Gagal:", block.Name, err)
                        else
                            -- print disabled agar tidak spam console
                            -- print("Fill:", block.Name, "index:", i)
                        end
                    end)

                    task.wait(0.03) -- micro spacing
                end
            end
        end)

        print("[AutoBucket] Siap digunakan ✓")
    end
}
