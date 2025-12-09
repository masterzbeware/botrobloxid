-- AutoCraft.lua (FINAL FIX)
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main

        if not MainTab then
            warn("[Auto Craft] Tab tidak ditemukan!")
            return
        end

        -- =========================
        -- UI GROUP
        -- =========================
        local Group = (MainTab.AddRightGroupbox and MainTab:AddRightGroupbox("Auto Craft"))
            or MainTab:AddLeftGroupbox("Auto Craft")

        -- DEFAULTS
        vars.AutoCraft    = vars.AutoCraft or false
        vars.CraftDelay   = vars.CraftDelay or 1.5
        vars.SelectedItem = vars.SelectedItem or "Chocolate Bar"
        _G.BotVars = vars

        -- TOGGLE
        Group:AddToggle("ToggleAutoCraft", {
            Text = "Auto Craft",
            Default = vars.AutoCraft,
            Callback = function(v)
                vars.AutoCraft = v
                print("[Auto Craft] Toggle:", v and "ON" or "OFF")
            end
        })

        -- DROPDOWN (ITEM KRAFT)
        local craftableItems = {"Chocolate Bar"}
        task.defer(function()
            if Group.AddDropdown then
                local dd = Group:AddDropdown("DropdownCraftItem", {
                    Text = "Pilih Item Craft",
                    Values = craftableItems,
                    Default = vars.SelectedItem,
                    Callback = function(v)
                        vars.SelectedItem = v
                        print("[Auto Craft] Item berubah:", v)
                    end
                })
                dd:SetValue(vars.SelectedItem)
            end
        end)

        -- DELAY SLIDER
        Group:AddSlider("SliderCraftDelay", {
            Text = "Delay Craft",
            Min = 0.3, Max = 3,
            Default = vars.CraftDelay,
            Rounding = 1,
            Callback = function(v) vars.CraftDelay = v end
        })

        -- =========================
        -- SERVICES
        -- =========================
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
        local CraftRemote = ReplicatedStorage:WaitForChild("Relay")
            :WaitForChild("Inventory")
            :WaitForChild("CraftItem")

        -- =========================
        -- SCAN OVEN POSITIONS
        -- =========================
        local ovenPositions = {}

        for _, block in ipairs(LoadedBlocks:GetChildren()) do
            if block.Name == "Baker's Oven" then
                local voxel = block:GetAttribute("VoxelPosition")
                if voxel then
                    table.insert(ovenPositions, voxel)
                end
            end
        end

        print("[Auto Craft] Oven ditemukan:", #ovenPositions)

        if #ovenPositions == 0 then
            warn("[Auto Craft] Tidak ada Baker's Oven ditemukan!")
        end

        -- =========================
        -- AUTO CRAFT LOOP
        -- =========================
        coroutine.wrap(function()
            while true do
                if vars.AutoCraft then
                    for i, pos in ipairs(ovenPositions) do
                        pcall(function()
                            CraftRemote:InvokeServer("Baker's Oven", vars.SelectedItem, pos)
                        end)

                        print("[Auto Craft] Craft", vars.SelectedItem, "di oven", i)
                        task.wait(vars.CraftDelay)

                        if not vars.AutoCraft then break end
                    end
                else
                    repeat task.wait(0.5) until vars.AutoCraft
                end
                task.wait()
            end
        end)()

        print("[Auto Craft] System Loaded. Target:", vars.SelectedItem)
    end
}
