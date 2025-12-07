-- Cow.lua
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Harvest

        if not MainTab then
            warn("[Auto Harvest White Cow] Tab tidak ditemukan!")
            return
        end

        -- UI GROUP
        local Group = MainTab:AddRightGroupbox("Auto Harvest White Cow")

        -- DEFAULT VARS
        vars.AutoHarvestCow = vars.AutoHarvestCow or false
        vars.HarvestDelay = vars.HarvestDelay or 1 -- default 1 detik
        _G.BotVars = vars -- simpan global

        -- TOGGLE
        Group:AddToggle("ToggleAutoHarvestCow", {
            Text = "Auto Harvest White Cow",
            Default = vars.AutoHarvestCow,
            Callback = function(v)
                vars.AutoHarvestCow = v
            end
        })

        -- SLIDER DELAY
        Group:AddSlider("SliderHarvestDelay", {
            Text = "Delay Harvest",
            Default = vars.HarvestDelay,
            Min = 0.1,
            Max = 2,
            Rounding = 1,
            Compact = false,
            Callback = function(v)
                vars.HarvestDelay = v
            end
        })

        -- SERVICES
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local HarvestCrop = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks"):WaitForChild("HarvestCrop")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        -- LOOP SYSTEM
        coroutine.wrap(function()
            while true do
                if not vars.AutoHarvestCow then
                    task.wait(0.1)
                else
                    local cowPositions = {}
                    for _, block in ipairs(LoadedBlocks:GetChildren()) do
                        if block.Name == "White Cow" then
                            local voxel = block:GetAttribute("VoxelPosition")
                            if voxel then
                                table.insert(cowPositions, voxel)
                            end
                        end
                    end

                    for i, voxel in ipairs(cowPositions) do
                        local success, err = pcall(function()
                            HarvestCrop:InvokeServer(vector.create(voxel.X, voxel.Y, voxel.Z))
                        end)

                        if success then
                            print("Harvest White Cow ke", i, "berhasil")
                        else
                            warn("Gagal harvest White Cow ke", i, err)
                        end

                        task.wait(vars.HarvestDelay)
                    end
                end
            end
        end)()

        print("[Auto Harvest White Cow] Sistem aktif.")
    end
}
