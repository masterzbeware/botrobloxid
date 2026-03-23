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
        -- LIST POSITION FIXED
        -- DIRAPIHKAN AGAR TIDAK KEPANJANGAN
        -- =========================
        local ovenPositions = {}

        local function addRange(x, y, zStart, zEnd)
            for z = zStart, zEnd do
                table.insert(ovenPositions, Vector3.new(x, y, z))
            end
        end

        -- Baris 1 - 6 lama
        addRange(-14, 1, -1, 12)
        addRange(-15, 1, -1, 12)
        addRange(-16, 1, -1, 12)
        addRange(-17, 1, -1, 12)
        addRange(-18, 1, -1, 12)
        addRange(-19, 1, -1, 12)

        -- Tambahan list baru
        addRange(-14, 1, 21, 36)
        addRange(-15, 1, 21, 36)
        addRange(-16, 1, 21, 36)
        addRange(-17, 1, 21, 36)
        addRange(-18, 1, 21, 36)
        addRange(-19, 1, 21, 36)

        -- Baris 7
        addRange(-20, 1, -1, 12)

        -- Baris 8 - 14
        addRange(-5, 1, -1, 17)
        addRange(-4, 1, -1, 17)
        addRange(-3, 1, -1, 17)
        addRange(-2, 1, -1, 17)
        addRange(-1, 1, -1, 17)
        addRange(0, 1, -1, 17)
        addRange(1, 1, -1, 17)

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

        print("[AutoCraft] System Loaded (Clean List + Extra Range Added)")
    end
}