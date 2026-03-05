-- AutoCraft.lua (UI FIXED VERSION)
return {
    Execute = function(tab)
        -- =========================
        -- GLOBAL VARS
        -- =========================
        local vars = _G.BotVars or {}
        vars.AutoCraft      = vars.AutoCraft or false
        vars.CraftDelay     = vars.CraftDelay or 1.5
        vars.SelectedItem   = vars.SelectedItem or "Chocolate Bar"
        vars._AutoCraftRun  = vars._AutoCraftRun or false
        _G.BotVars = vars

        -- =========================
        -- TAB & UI
        -- =========================
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main

        if not MainTab then
            warn("[AutoCraft] MainTab tidak ditemukan")
            return
        end

        local Group = (MainTab.AddRightGroupbox and MainTab:AddRightGroupbox("Auto Craft"))
            or MainTab:AddLeftGroupbox("Auto Craft")

        -- TOGGLE
        Group:AddToggle("ToggleAutoCraft", {
            Text = "Auto Craft",
            Default = vars.AutoCraft,
            Callback = function(v)
                vars.AutoCraft = v
                print("[AutoCraft] Toggle:", v and "ON" or "OFF")
            end
        })

        -- DROPDOWN ITEM
        local craftableItems = {
            "Chocolate Bar"
        }

        if Group.AddDropdown then
            local dd = Group:AddDropdown("DropdownCraftItem", {
                Text = "Pilih Item Craft",
                Values = craftableItems,
                Default = vars.SelectedItem,
                Callback = function(v)
                    vars.SelectedItem = v
                    print("[AutoCraft] Item:", v)
                end
            })
            dd:SetValue(vars.SelectedItem)
        end

        -- SLIDER DELAY
        Group:AddSlider("SliderCraftDelay", {
            Text = "Delay Craft",
            Min = 0.3,
            Max = 3,
            Default = vars.CraftDelay,
            Rounding = 1,
            Callback = function(v)
                vars.CraftDelay = v
            end
        })

        -- =========================
        -- SERVICES
        -- =========================
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local CraftRemote = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Inventory")
            :WaitForChild("CraftItem")

        -- =========================
        -- FUNCTION: SCAN OVEN
        -- =========================
        local function GetOvenPositions()
            local ovens = {}

            for _, block in ipairs(LoadedBlocks:GetChildren()) do
                if block.Name == "Baker's Oven" then
                    local voxel = block:GetAttribute("VoxelPosition")
                    if voxel then
                        table.insert(ovens, voxel)
                    end
                end
            end

            return ovens
        end

        -- =========================
        -- AUTO CRAFT LOOP (SAFE)
        -- =========================
        if vars._AutoCraftRun then
            warn("[AutoCraft] Loop sudah berjalan, skip init")
            return
        end

        vars._AutoCraftRun = true

        task.spawn(function()
            while true do
                if vars.AutoCraft then
                    local ovenPositions = GetOvenPositions()

                    if #ovenPositions == 0 then
                        warn("[AutoCraft] Tidak ada Baker's Oven!")
                        task.wait(2)
                        continue
                    end

                    print("[AutoCraft] Oven ditemukan:", #ovenPositions)

                    for i, pos in ipairs(ovenPositions) do
                        if not vars.AutoCraft then break end

                        local ok, err = pcall(function()
                            CraftRemote:InvokeServer(
                                "Baker's Oven",
                                vars.SelectedItem,
                                pos
                            )
                        end)

                        if ok then
                            print(string.format(
                                "[AutoCraft] Craft %s | Oven #%d",
                                vars.SelectedItem,
                                i
                            ))
                        else
                            warn("[AutoCraft] Gagal craft:", err)
                        end

                        task.wait(vars.CraftDelay)
                    end
                else
                    task.wait(0.5)
                end
            end
        end)

        print("[AutoCraft] System Loaded")
    end
}
