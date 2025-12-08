-- AutoInsert.lua
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main

        if not MainTab then
            warn("[Auto Insert] Tab tidak ditemukan!")
            return
        end

        -- UI GROUP
        local Group = MainTab:AddLeftGroupbox("Auto Insert Items")

        -- MODEL YANG DIIZINKAN (hapus Mushroom Box)
        local allowedModels = {"Compost Bin", "Large Water Trough", "Small Water Trough"}

        -- DEFAULT VARS
        vars.InsertDelay = vars.InsertDelay or 1
        vars.InsertTarget = vars.InsertTarget or "Compost Bin"
        vars.AutoInsert = vars.AutoInsert or true -- set true supaya toggle default ON
        _G.BotVars = vars

        -- TOGGLE
        local toggle = Group:AddToggle("ToggleAutoInsert", {
            Text = "Auto Insert",
            Default = vars.AutoInsert,
            Callback = function(v)
                vars.AutoInsert = v
            end
        })
        -- pastikan vars mengikuti toggle default
        vars.AutoInsert = toggle:GetState() -- Obsidian toggle state

        -- DROPDOWN PILIH BLOCK (Obsidian format)
        task.spawn(function()
            task.wait(0.5)
            if Group.AddDropdown then
                local dropdown = Group:AddDropdown("DropdownInsertTarget", {
                    Text = "Pilih Block",
                    Values = allowedModels,
                    Default = vars.InsertTarget,
                    Multi = false,
                    Callback = function(v)
                        vars.InsertTarget = v
                        print("[Auto Insert] Target diubah ke:", v)
                    end
                })
                dropdown:SetValue(vars.InsertTarget)
            end
        end)

        -- SLIDER DELAY
        Group:AddSlider("SliderInsertDelay", {
            Text = "Delay Insert",
            Default = vars.InsertDelay,
            Min = 0.5,
            Max = 2,
            Rounding = 1,
            Compact = false,
            Callback = function(v)
                vars.InsertDelay = v
            end
        })

        -- SERVICES
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Blocks = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks")
        local InsertItem = Blocks:WaitForChild("InsertItem")

        -- LOOP SYSTEM
        coroutine.wrap(function()
            while true do
                if not vars.AutoInsert then
                    task.wait(0.1)
                else
                    local LoadedBlocks = workspace:FindFirstChild("LoadedBlocks")
                    if LoadedBlocks then
                        for _, block in ipairs(LoadedBlocks:GetChildren()) do
                            if block.Name == vars.InsertTarget and table.find(allowedModels, block.Name) then
                                local voxel = block:GetAttribute("VoxelPosition")
                                if voxel then
                                    local success, err = pcall(function()
                                        InsertItem:InvokeServer(vector.create(voxel.X, voxel.Y, voxel.Z))
                                    end)
                                    if success then
                                        print("Berhasil insert ke:", block.Name)
                                    else
                                        warn("Gagal insert ke:", block.Name, err)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(vars.InsertDelay)
                end
            end
        end)()

        print("[Auto Insert] Sistem aktif. Target:", vars.InsertTarget)
    end
}
