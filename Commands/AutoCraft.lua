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
        -- URUTAN: BARIS 1 -> BARIS 14
        -- =========================
        local ovenPositions = {
            -- Baris 1
            Vector3.new(-14, 1, -1), Vector3.new(-14, 1, 0), Vector3.new(-14, 1, 1),
            Vector3.new(-14, 1, 2), Vector3.new(-14, 1, 3), Vector3.new(-14, 1, 4),
            Vector3.new(-14, 1, 5), Vector3.new(-14, 1, 6), Vector3.new(-14, 1, 7),
            Vector3.new(-14, 1, 8), Vector3.new(-14, 1, 9), Vector3.new(-14, 1, 10),
            Vector3.new(-14, 1, 11), Vector3.new(-14, 1, 12),

            -- Baris 2
            Vector3.new(-15, 1, -1), Vector3.new(-15, 1, 0), Vector3.new(-15, 1, 1),
            Vector3.new(-15, 1, 2), Vector3.new(-15, 1, 3), Vector3.new(-15, 1, 4),
            Vector3.new(-15, 1, 5), Vector3.new(-15, 1, 6), Vector3.new(-15, 1, 7),
            Vector3.new(-15, 1, 8), Vector3.new(-15, 1, 9), Vector3.new(-15, 1, 10),
            Vector3.new(-15, 1, 11), Vector3.new(-15, 1, 12),

            -- Baris 3
            Vector3.new(-16, 1, -1), Vector3.new(-16, 1, 0), Vector3.new(-16, 1, 1),
            Vector3.new(-16, 1, 2), Vector3.new(-16, 1, 3), Vector3.new(-16, 1, 4),
            Vector3.new(-16, 1, 5), Vector3.new(-16, 1, 6), Vector3.new(-16, 1, 7),
            Vector3.new(-16, 1, 8), Vector3.new(-16, 1, 9), Vector3.new(-16, 1, 10),
            Vector3.new(-16, 1, 11), Vector3.new(-16, 1, 12),

            -- Baris 4
            Vector3.new(-17, 1, -1), Vector3.new(-17, 1, 0), Vector3.new(-17, 1, 1),
            Vector3.new(-17, 1, 2), Vector3.new(-17, 1, 3), Vector3.new(-17, 1, 4),
            Vector3.new(-17, 1, 5), Vector3.new(-17, 1, 6), Vector3.new(-17, 1, 7),
            Vector3.new(-17, 1, 8), Vector3.new(-17, 1, 9), Vector3.new(-17, 1, 10),
            Vector3.new(-17, 1, 11), Vector3.new(-17, 1, 12),

            -- Baris 5
            Vector3.new(-18, 1, -1), Vector3.new(-18, 1, 0), Vector3.new(-18, 1, 1),
            Vector3.new(-18, 1, 2), Vector3.new(-18, 1, 3), Vector3.new(-18, 1, 4),
            Vector3.new(-18, 1, 5), Vector3.new(-18, 1, 6), Vector3.new(-18, 1, 7),
            Vector3.new(-18, 1, 8), Vector3.new(-18, 1, 9), Vector3.new(-18, 1, 10),
            Vector3.new(-18, 1, 11), Vector3.new(-18, 1, 12),

            -- Baris 6
            Vector3.new(-19, 1, -1), Vector3.new(-19, 1, 0), Vector3.new(-19, 1, 1),
            Vector3.new(-19, 1, 2), Vector3.new(-19, 1, 3), Vector3.new(-19, 1, 4),
            Vector3.new(-19, 1, 5), Vector3.new(-19, 1, 6), Vector3.new(-19, 1, 7),
            Vector3.new(-19, 1, 8), Vector3.new(-19, 1, 9), Vector3.new(-19, 1, 10),
            Vector3.new(-19, 1, 11), Vector3.new(-19, 1, 12),

            -- Baris 7
            Vector3.new(-20, 1, -1), Vector3.new(-20, 1, 0), Vector3.new(-20, 1, 1),
            Vector3.new(-20, 1, 2), Vector3.new(-20, 1, 3), Vector3.new(-20, 1, 4),
            Vector3.new(-20, 1, 5), Vector3.new(-20, 1, 6), Vector3.new(-20, 1, 7),
            Vector3.new(-20, 1, 8), Vector3.new(-20, 1, 9), Vector3.new(-20, 1, 10),
            Vector3.new(-20, 1, 11), Vector3.new(-20, 1, 12),

            -- Baris 8
            Vector3.new(-5, 1, -1), Vector3.new(-5, 1, 0), Vector3.new(-5, 1, 1),
            Vector3.new(-5, 1, 2), Vector3.new(-5, 1, 3), Vector3.new(-5, 1, 4),
            Vector3.new(-5, 1, 5), Vector3.new(-5, 1, 6), Vector3.new(-5, 1, 7),
            Vector3.new(-5, 1, 8), Vector3.new(-5, 1, 9), Vector3.new(-5, 1, 10),
            Vector3.new(-5, 1, 11), Vector3.new(-5, 1, 12), Vector3.new(-5, 1, 13),
            Vector3.new(-5, 1, 14), Vector3.new(-5, 1, 15), Vector3.new(-5, 1, 16),
            Vector3.new(-5, 1, 17),

            -- Baris 9
            Vector3.new(-4, 1, -1), Vector3.new(-4, 1, 0), Vector3.new(-4, 1, 1),
            Vector3.new(-4, 1, 2), Vector3.new(-4, 1, 3), Vector3.new(-4, 1, 4),
            Vector3.new(-4, 1, 5), Vector3.new(-4, 1, 6), Vector3.new(-4, 1, 7),
            Vector3.new(-4, 1, 8), Vector3.new(-4, 1, 9), Vector3.new(-4, 1, 10),
            Vector3.new(-4, 1, 11), Vector3.new(-4, 1, 12), Vector3.new(-4, 1, 13),
            Vector3.new(-4, 1, 14), Vector3.new(-4, 1, 15), Vector3.new(-4, 1, 16),
            Vector3.new(-4, 1, 17),

            -- Baris 10
            Vector3.new(-3, 1, -1), Vector3.new(-3, 1, 0), Vector3.new(-3, 1, 1),
            Vector3.new(-3, 1, 2), Vector3.new(-3, 1, 3), Vector3.new(-3, 1, 4),
            Vector3.new(-3, 1, 5), Vector3.new(-3, 1, 6), Vector3.new(-3, 1, 7),
            Vector3.new(-3, 1, 8), Vector3.new(-3, 1, 9), Vector3.new(-3, 1, 10),
            Vector3.new(-3, 1, 11), Vector3.new(-3, 1, 12), Vector3.new(-3, 1, 13),
            Vector3.new(-3, 1, 14), Vector3.new(-3, 1, 15), Vector3.new(-3, 1, 16),
            Vector3.new(-3, 1, 17),

            -- Baris 11
            Vector3.new(-2, 1, -1), Vector3.new(-2, 1, 0), Vector3.new(-2, 1, 1),
            Vector3.new(-2, 1, 2), Vector3.new(-2, 1, 3), Vector3.new(-2, 1, 4),
            Vector3.new(-2, 1, 5), Vector3.new(-2, 1, 6), Vector3.new(-2, 1, 7),
            Vector3.new(-2, 1, 8), Vector3.new(-2, 1, 9), Vector3.new(-2, 1, 10),
            Vector3.new(-2, 1, 11), Vector3.new(-2, 1, 12), Vector3.new(-2, 1, 13),
            Vector3.new(-2, 1, 14), Vector3.new(-2, 1, 15), Vector3.new(-2, 1, 16),
            Vector3.new(-2, 1, 17),

            -- Baris 12
            Vector3.new(-1, 1, -1), Vector3.new(-1, 1, 0), Vector3.new(-1, 1, 1),
            Vector3.new(-1, 1, 2), Vector3.new(-1, 1, 3), Vector3.new(-1, 1, 4),
            Vector3.new(-1, 1, 5), Vector3.new(-1, 1, 6), Vector3.new(-1, 1, 7),
            Vector3.new(-1, 1, 8), Vector3.new(-1, 1, 9), Vector3.new(-1, 1, 10),
            Vector3.new(-1, 1, 11), Vector3.new(-1, 1, 12), Vector3.new(-1, 1, 13),
            Vector3.new(-1, 1, 14), Vector3.new(-1, 1, 15), Vector3.new(-1, 1, 16),
            Vector3.new(-1, 1, 17),

            -- Baris 13
            Vector3.new(0, 1, -1), Vector3.new(0, 1, 0), Vector3.new(0, 1, 1),
            Vector3.new(0, 1, 2), Vector3.new(0, 1, 3), Vector3.new(0, 1, 4),
            Vector3.new(0, 1, 5), Vector3.new(0, 1, 6), Vector3.new(0, 1, 7),
            Vector3.new(0, 1, 8), Vector3.new(0, 1, 9), Vector3.new(0, 1, 10),
            Vector3.new(0, 1, 11), Vector3.new(0, 1, 12), Vector3.new(0, 1, 13),
            Vector3.new(0, 1, 14), Vector3.new(0, 1, 15), Vector3.new(0, 1, 16),
            Vector3.new(0, 1, 17),

            -- Baris 14
            Vector3.new(1, 1, -1), Vector3.new(1, 1, 0), Vector3.new(1, 1, 1),
            Vector3.new(1, 1, 2), Vector3.new(1, 1, 3), Vector3.new(1, 1, 4),
            Vector3.new(1, 1, 5), Vector3.new(1, 1, 6), Vector3.new(1, 1, 7),
            Vector3.new(1, 1, 8), Vector3.new(1, 1, 9), Vector3.new(1, 1, 10),
            Vector3.new(1, 1, 11), Vector3.new(1, 1, 12), Vector3.new(1, 1, 13),
            Vector3.new(1, 1, 14), Vector3.new(1, 1, 15), Vector3.new(1, 1, 16),
            Vector3.new(1, 1, 17),
        }

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

        print("[AutoCraft] System Loaded (Row Order 1 -> 14)")
    end
}