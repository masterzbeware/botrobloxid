-- AutoBucket.lua (REWORK FINAL-V3)
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
        -- DEFAULT VARIABLES
        -- ========================
        vars.AutoFill = vars.AutoFill or false
        vars.FillDelay = vars.FillDelay or 0.2
        vars.FillTarget = vars.FillTarget or {"Brick Well", "Stone Well"}
        _G.BotVars = vars -- global sync

        -- ========================
        -- UI GROUP
        -- ========================
        local Group = (typeof(MainTab.AddRightGroupbox) == "function")
            and MainTab:AddRightGroupbox("Auto Fill")
            or MainTab:AddLeftGroupbox("Auto Fill")

        -- SERVICES
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local vector = _G.vector or vector
        local FillBucket = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Inventory")
            :WaitForChild("FillBucket")

        -- ========================
        -- UI ELEMENTS
        -- ========================
        Group:AddToggle("ToggleAutoFill", {
            Text = "Auto Fill Well",
            Default = vars.AutoFill,
            Callback = function(value)
                vars.AutoFill = value
                _G.BotVars.AutoFill = value
                print("[AutoBucket] Status:", value and "Aktif" or "Mati")
            end
        })

        task.delay(0.7, function()
            if Group.AddDropdown then
                Group:AddDropdown("DropdownFillTarget", {
                    Text = "Target Well",
                    Values = {"Brick Well", "Stone Well"},
                    Multi = true,
                    Default = vars.FillTarget,
                    Callback = function(value)
                        vars.FillTarget = value
                        _G.BotVars.FillTarget = value
                    end
                })
            end
        end)

        Group:AddSlider("FillDelaySlider", {
            Text = "Delay (detik)",
            Default = vars.FillDelay,
            Min = 0.1,
            Max = 2,
            Rounding = 0.01,
            Callback = function(v)
                v = tonumber(string.format("%.2f", v))
                vars.FillDelay = v
                _G.BotVars.FillDelay = v
                print("[AutoBucket] Delay =", v)
            end
        })

        -- ========================
        -- MAIN AUTO FILL LOOP
        -- ========================
        task.spawn(function()
            while true do
                task.wait(vars.FillDelay or 0.2)

                if not vars.AutoFill then continue end

                local blocks = LoadedBlocks:GetChildren()
                for i, block in ipairs(blocks) do
                    if not vars.AutoFill then break end
                    if not block:IsA("Model") then continue end
                    if not table.find(vars.FillTarget, block.Name) then continue end

                    local voxel = block:GetAttribute("VoxelPosition")
                    if not voxel then continue end

                    task.spawn(function()
                        local args = {
                            vector.create(voxel.X, voxel.Y, voxel.Z)
                        }

                        local ok, err = pcall(function()
                            FillBucket:InvokeServer(unpack(args))
                        end)

                        if not ok then
                            warn("[AutoBucket] Gagal:", block.Name, err)
                        end
                    end)

                    task.wait(0.03) -- smoothing
                end
            end
        end)

        print("[AutoBucket] Siap berjalan ✓")
    end
}
