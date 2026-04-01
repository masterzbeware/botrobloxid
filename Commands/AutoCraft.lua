-- AutoCraft.lua
return {
    Execute = function(tab)
        -- =========================
        -- GLOBAL VARS
        -- =========================
        local vars = _G.BotVars or {}
        vars.AutoCraft       = vars.AutoCraft or false
        vars.AutoHarvest     = vars.AutoHarvest or false
        vars.CraftDelay      = vars.CraftDelay or 1.5
        vars.HarvestDelay    = vars.HarvestDelay or 1.5
        vars.SelectedItem    = vars.SelectedItem or "Chocolate Bar"
        vars._AutoCraftRun   = vars._AutoCraftRun or false
        vars._AutoHarvestRun = vars._AutoHarvestRun or false
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

        local Group = (CraftTab.AddRightGroupbox and CraftTab:AddRightGroupbox("Auto Craft / Harvest"))
            or CraftTab:AddLeftGroupbox("Auto Craft / Harvest")

        -- =========================
        -- TOGGLE CRAFT
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
        -- TOGGLE HARVEST
        -- =========================
        Group:AddToggle("ToggleAutoHarvest", {
            Text = "Auto Harvest",
            Default = vars.AutoHarvest,
            Callback = function(v)
                vars.AutoHarvest = v
                print("[AutoHarvest] Toggle:", v and "ON" or "OFF")
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
        -- SLIDER CRAFT DELAY
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
        -- SLIDER HARVEST DELAY
        -- =========================
        Group:AddSlider("SliderHarvestDelay", {
            Text = "Delay Harvest",
            Min = 0.3,
            Max = 3,
            Default = vars.HarvestDelay,
            Rounding = 1,
            Callback = function(v)
                vars.HarvestDelay = v
            end
        })

        -- =========================
        -- SERVICES
        -- =========================
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Workspace = game:GetService("Workspace")

        local RelayRoot = ReplicatedStorage:WaitForChild("Relay", 10)
        if not RelayRoot then
            warn("[AutoCraft] Relay tidak ditemukan")
            return
        end

        local Inventory = RelayRoot:WaitForChild("Inventory", 10)
        if not Inventory then
            warn("[AutoCraft] Relay.Inventory tidak ditemukan")
            return
        end

        local Blocks = RelayRoot:WaitForChild("Blocks", 10)
        if not Blocks then
            warn("[AutoCraft] Relay.Blocks tidak ditemukan")
            return
        end

        local CraftRemote = Inventory:WaitForChild("CraftItem", 10)
        if not CraftRemote then
            warn("[AutoCraft] CraftItem tidak ditemukan")
            return
        end

        local HarvestRemote = Blocks:WaitForChild("HarvestCrop", 10)
        if not HarvestRemote then
            warn("[AutoHarvest] HarvestCrop tidak ditemukan")
            return
        end

        local LoadedBlocks = Workspace:WaitForChild("LoadedBlocks", 10)
        if not LoadedBlocks then
            warn("[AutoCraft] workspace.LoadedBlocks tidak ditemukan")
            return
        end

        -- =========================
        -- HELPERS
        -- =========================
        local function toVector3(voxel)
            if typeof(voxel) == "Vector3" then
                return Vector3.new(voxel.X, voxel.Y, voxel.Z)
            end
            return nil
        end

        local function toHarvestVector(voxel)
            if typeof(voxel) ~= "Vector3" then
                return nil
            end

            if vector and vector.create then
                return vector.create(voxel.X, voxel.Y, voxel.Z)
            end

            return Vector3.new(voxel.X, voxel.Y, voxel.Z)
        end

        local function getBakerOvens()
            local ovens = {}

            for _, block in ipairs(LoadedBlocks:GetChildren()) do
                if block.Name == "Baker's Oven" then
                    local voxel = block:GetAttribute("VoxelPosition")
                    local pos = toVector3(voxel)

                    if pos then
                        table.insert(ovens, {
                            Block = block,
                            Voxel = pos
                        })
                    end
                end
            end

            table.sort(ovens, function(a, b)
                if a.Voxel.X ~= b.Voxel.X then
                    return a.Voxel.X > b.Voxel.X
                end
                if a.Voxel.Y ~= b.Voxel.Y then
                    return a.Voxel.Y > b.Voxel.Y
                end
                return a.Voxel.Z < b.Voxel.Z
            end)

            return ovens
        end

        -- =========================
        -- CRAFT FUNCTION
        -- =========================
        local function ScanAndCraft()
            local ovens = getBakerOvens()

            if #ovens == 0 then
                warn("[AutoCraft] Tidak ada Baker's Oven ditemukan di LoadedBlocks")
                return
            end

            for i, ovenData in ipairs(ovens) do
                if not vars.AutoCraft then
                    return
                end

                local ok, err = pcall(function()
                    CraftRemote:InvokeServer(
                        "Baker's Oven",
                        vars.SelectedItem,
                        ovenData.Voxel
                    )
                end)

                if ok then
                    print("[AutoCraft] Craft", vars.SelectedItem, "| Oven", i, "|", ovenData.Voxel)
                else
                    warn("[AutoCraft] Gagal craft:", err)
                end

                task.wait(vars.CraftDelay)
            end
        end

        -- =========================
        -- HARVEST FUNCTION
        -- =========================
        local function ScanAndHarvest()
            local ovens = getBakerOvens()

            if #ovens == 0 then
                warn("[AutoHarvest] Tidak ada Baker's Oven ditemukan di LoadedBlocks")
                return
            end

            for i, ovenData in ipairs(ovens) do
                if not vars.AutoHarvest then
                    return
                end

                local harvestPos = toHarvestVector(ovenData.Voxel)
                if not harvestPos then
                    warn("[AutoHarvest] VoxelPosition invalid pada oven", i)
                    continue
                end

                local ok, err = pcall(function()
                    HarvestRemote:InvokeServer(harvestPos)
                end)

                if ok then
                    print("[AutoHarvest] Harvest | Oven", i, "|", ovenData.Voxel)
                else
                    warn("[AutoHarvest] Gagal harvest:", err)
                end

                task.wait(vars.HarvestDelay)
            end
        end

        -- =========================
        -- AUTO CRAFT LOOP
        -- =========================
        if not vars._AutoCraftRun then
            vars._AutoCraftRun = true

            task.spawn(function()
                while true do
                    if vars.AutoCraft then
                        ScanAndCraft()
                    else
                        task.wait(0.3)
                    end

                    task.wait(vars.CraftDelay)
                end
            end)
        end

        -- =========================
        -- AUTO HARVEST LOOP
        -- =========================
        if not vars._AutoHarvestRun then
            vars._AutoHarvestRun = true

            task.spawn(function()
                while true do
                    if vars.AutoHarvest then
                        ScanAndHarvest()
                    else
                        task.wait(0.3)
                    end

                    task.wait(vars.HarvestDelay)
                end
            end)
        end

        print("[AutoCraft] System Loaded (Craft + Harvest fixed for Baker's Oven)")
    end
}