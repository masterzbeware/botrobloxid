-- AutoCraft.lua
return {
    Execute = function(tab)

        -- =========================
        -- GLOBAL VARS
        -- =========================
        local vars = _G.BotVars or {}
        vars.AutoCraft        = vars.AutoCraft or false
        vars.AutoHarvestBaker = vars.AutoHarvestBaker or false
        vars.CraftDelay       = vars.CraftDelay or 1.5
        vars.SelectedItem     = vars.SelectedItem or "Chocolate Bar"
        vars._AutoCraftRun    = vars._AutoCraftRun or false
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
        -- TOGGLES
        -- =========================
        Group:AddToggle("ToggleAutoCraft", {
            Text = "Auto Craft",
            Default = vars.AutoCraft,
            Callback = function(v)
                vars.AutoCraft = v
                print("[AutoCraft] Toggle:", v and "ON" or "OFF")
            end
        })

        Group:AddToggle("ToggleAutoHarvestBaker", {
            Text = "Auto Harvest Baker",
            Default = vars.AutoHarvestBaker,
            Callback = function(v)
                vars.AutoHarvestBaker = v
                print("[AutoHarvestBaker] Toggle:", v and "ON" or "OFF")
            end
        })

        -- =========================
        -- ITEM LIST
        -- =========================
        local craftableItems = {
            "Chocolate Bar"
        }

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

        local HarvestRemote = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Blocks")
            :WaitForChild("HarvestCrop")

        -- =========================
        -- GET IDLE OVENS
        -- =========================
        local function GetIdleOvens()
            local ovens = {}
            local seen = {}

            for _, obj in ipairs(LoadedBlocks:GetDescendants()) do
                if obj.Name == "Baker's Oven" then
                    
                    -- cek apakah sedang masak
                    local isBusy = obj:FindFirstChild("baked", true)

                    if not isBusy then
                        local voxel = obj:GetAttribute("VoxelPosition")

                        if not voxel and obj.Parent then
                            voxel = obj.Parent:GetAttribute("VoxelPosition")
                        end

                        if voxel then
                            local key = tostring(voxel)
                            if not seen[key] then
                                seen[key] = true
                                table.insert(ovens, voxel)
                            end
                        end
                    end
                end
            end

            return ovens
        end

        -- =========================
        -- AUTO CRAFT
        -- =========================
        local function ScanAndCraft()
            local ovens = GetIdleOvens()

            for _, pos in ipairs(ovens) do
                if not vars.AutoCraft then break end

                pcall(function()
                    CraftRemote:InvokeServer(
                        "Baker's Oven",
                        vars.SelectedItem,
                        pos
                    )
                end)

                print("[AutoCraft] Craft:", vars.SelectedItem, pos)
                task.wait(vars.CraftDelay)
            end
        end

        -- =========================
        -- AUTO HARVEST BAKER
        -- =========================
        local function HarvestBakerOvens()
            for _, obj in ipairs(LoadedBlocks:GetDescendants()) do
                if obj.Name == "Baker's Oven" then

                    local isCooking = obj:FindFirstChild("baked", true)
                    local prompt = obj:FindFirstChild("ProximityPrompt", true)

                    -- harvest hanya jika selesai masak
                    if not isCooking and prompt and prompt.Enabled then
                        
                        local voxel = obj:GetAttribute("VoxelPosition")
                        if not voxel and obj.Parent then
                            voxel = obj.Parent:GetAttribute("VoxelPosition")
                        end

                        if voxel then
                            pcall(function()
                                HarvestRemote:InvokeServer(
                                    vector.create(voxel.X, voxel.Y, voxel.Z)
                                )
                            end)

                            print("[AutoHarvestBaker] Harvest:", voxel)
                            task.wait(0.2)
                        end
                    end
                end
            end
        end

        -- =========================
        -- MAIN LOOP
        -- =========================
        if vars._AutoCraftRun then
            warn("[AutoCraft] Loop sudah berjalan")
            return
        end

        vars._AutoCraftRun = true

        task.spawn(function()
            while true do

                if vars.AutoHarvestBaker then
                    HarvestBakerOvens()
                end

                if vars.AutoCraft then
                    ScanAndCraft()
                end

                task.wait(0.2)
            end
        end)

        print("[AutoCraft] System Loaded (Craft + Harvest)")
    end
}