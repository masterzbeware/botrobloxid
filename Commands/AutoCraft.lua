-- AutoCraft.lua
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

        -- =========================
        -- TOGGLE
        -- =========================
        Group:AddToggle("ToggleAutoCraft", {
            Text = "Auto Craft",
            Default = vars.AutoCraft,
            Callback = function(v)
                vars.AutoCraft = v
                print("[AutoCraft] Toggle:", v and "ON" or "OFF")
            end
        })

        -- =========================
        -- ITEM LIST
        -- =========================
        local craftableItems = {
            "Chocolate Bar"
        }

        -- =========================
        -- DROPDOWN
        -- =========================
        Group:AddDropdown("DropdownCraftItem", {
            Text = "Pilih Item Craft",
            Values = craftableItems,
            Default = vars.SelectedItem,
            Multi = false,
            Callback = function(v)
                vars.SelectedItem = v
                print("[AutoCraft] Item:", v)
            end
        })

        -- =========================
        -- SLIDER DELAY
        -- =========================
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
        -- FUNCTION SCAN OVEN
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
        -- CRAFT FUNCTION
        -- =========================
        local function ScanAndCraft()

            local ovens = GetOvenPositions()

            if #ovens == 0 then
                warn("[AutoCraft] Tidak ada Baker's Oven!")
                return
            end

            for i, pos in ipairs(ovens) do

                if not vars.AutoCraft then
                    return
                end

                local ok, err = pcall(function()
                    CraftRemote:InvokeServer(
                        "Baker's Oven",
                        vars.SelectedItem,
                        pos
                    )
                end)

                if ok then
                    print("[AutoCraft] Craft", vars.SelectedItem, "| Oven", i)
                else
                    warn("[AutoCraft] Gagal craft:", err)
                end

                task.wait(vars.CraftDelay)
            end
        end

        -- =========================
        -- AUTO LOOP
        -- =========================
        if vars._AutoCraftRun then
            warn("[AutoCraft] Loop sudah berjalan")
            return
        end

        vars._AutoCraftRun = true

        task.spawn(function()

            while true do

                if vars.AutoCraft then
                    ScanAndCraft()
                end

                task.wait(vars.CraftDelay)
            end

        end)

        print("[AutoCraft] System Loaded (Fixed)")
    end
}