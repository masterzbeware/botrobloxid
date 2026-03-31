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
        local CraftTab = tab or Tabs.Craft

        if not CraftTab then
            warn("[AutoCraft] Tab Craft tidak ditemukan")
            return
        end

        local Group = (CraftTab.AddRightGroupbox and CraftTab:AddRightGroupbox("Auto Craft"))
            or CraftTab:AddLeftGroupbox("Auto Craft")

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

        local CraftRemote = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Inventory")
            :WaitForChild("CraftItem")

        -- =========================
        -- LIST POSITION BARU
        -- x = 1 sampai -19
        -- y = 1
        -- z = -1 sampai 32
        -- =========================
        local ovenPositions = {}

        local function addRange(x, y, zStart, zEnd)
            local step = (zStart <= zEnd) and 1 or -1
            for z = zStart, zEnd, step do
                table.insert(ovenPositions, Vector3.new(x, y, z))
            end
        end

        for x = 1, -19, -1 do
            addRange(x, 1, -1, 32)
        end

        -- =========================
        -- CRAFT FUNCTION
        -- =========================
        local function ScanAndCraft()
            if #ovenPositions == 0 then
                warn("[AutoCraft] List oven kosong!")
                return
            end

            for i, pos in ipairs(ovenPositions) do
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
                    print("[AutoCraft] Craft", vars.SelectedItem, "| Posisi", i, "|", pos)
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

        print("[AutoCraft] System Loaded (New Position Range Applied)")
    end
}