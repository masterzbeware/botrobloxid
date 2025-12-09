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

        -- DEFAULT VARS
        vars.AutoInsert = vars.AutoInsert or false
        vars.InsertDelay = vars.InsertDelay or 1
        vars.InsertTarget = vars.InsertTarget or "Compost Bin"
        _G.BotVars = vars -- simpan global

        -- TOGGLE
        Group:AddToggle("ToggleAutoInsert", {
            Text = "Auto Insert",
            Default = vars.AutoInsert,
            Callback = function(v)
                vars.AutoInsert = v
                print("[Auto Insert] Toggle:", v and "ON" or "OFF")
            end
        })

        -- MODEL YANG DIIZINKAN
        local allowedModels = {"Handmill","Preserves Barrel","Small Food Trough","Butter Churn","Compost Bin", "Large Water Trough", "Small Water Trough"}

        -- DROPDOWN PILIH BLOCK
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
            else
                warn("[Auto Insert] AddDropdown tidak tersedia di Group")
            end
        end)

        -- SLIDER DELAY
        Group:AddSlider("SliderInsertDelay", {
            Text = "Delay Insert",
            Default = vars.InsertDelay,
            Min = 0.3,
            Max = 3,
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

        -- LOOP SYSTEM (hanya insert jika toggle ON)
        coroutine.wrap(function()
            while true do
                if vars.AutoInsert then
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
                else
                    -- toggle OFF → tunggu lebih lama supaya CPU tidak terbebani
                    task.wait(0.5)
                end
            end
        end)()

        print("[Auto Insert] Sistem aktif. Target:", vars.InsertTarget)
    end
}
