-- AutoPickup.lua (FINAL)
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main

        if not MainTab then
            warn("[Auto Pickup] Tab tidak ditemukan!")
            return
        end

        -- =========================
        -- UI GROUP
        -- =========================
        local Group = MainTab:AddLeftGroupbox("Auto Pickup")

        -- =========================
        -- DEFAULT VARS
        -- =========================
        vars.AutoPickup   = vars.AutoPickup or false
        vars.PickupDelay  = vars.PickupDelay or 0.3
        vars.PickupTarget = vars.PickupTarget or "All"
        _G.BotVars = vars

        -- =========================
        -- TOGGLE
        -- =========================
        Group:AddToggle("ToggleAutoPickup", {
            Text = "Auto Pickup",
            Default = vars.AutoPickup,
            Callback = function(v)
                vars.AutoPickup = v
                print("[Auto Pickup] Toggle:", v and "ON" or "OFF")
            end
        })

        -- =========================
        -- ITEM LIST
        -- =========================
        local allowedItems = {
            "All",

            -- Sticks
            "Oak Sticks",
            "Birch Sticks",
            "Pink Cherry Sticks",
            "Cedar Sticks",

            -- Fruits & Plants
            "Wild Blueberry",
            "Wild Strawberry",
            "Wild Cactus",

            -- Flowers
            "Yellow Flowers",
            "Orange Flowers",
            "Large Orange Flower",

            -- Mushrooms
            "Red Mushroom Cluster",
            "Blue Mushroom Cluster",

            -- Sea Items
            "Scallop",
            "Oyster",
            "Conch",

            -- Rare
            "Fossil"
        }

        -- =========================
        -- DROPDOWN
        -- =========================
        task.defer(function()
            if Group.AddDropdown then
                local dropdown = Group:AddDropdown("DropdownPickupTarget", {
                    Text = "Pilih Item",
                    Values = allowedItems,
                    Default = vars.PickupTarget,
                    Multi = false,
                    Callback = function(v)
                        vars.PickupTarget = v
                        print("[Auto Pickup] Target:", v)
                    end
                })
                dropdown:SetValue(vars.PickupTarget)
            end
        end)

        -- =========================
        -- SLIDER DELAY
        -- =========================
        Group:AddSlider("SliderPickupDelay", {
            Text = "Delay Pickup",
            Default = vars.PickupDelay,
            Min = 0.2,
            Max = 3,
            Rounding = 1,
            Callback = function(v)
                vars.PickupDelay = v
            end
        })

        -- =========================
        -- SERVICES
        -- =========================
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
        local PickupItem = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Server")
            :WaitForChild("PickupItem")

        -- =========================
        -- HELPER: GET VOXEL
        -- =========================
        local function getVoxel(inst)
            if inst:IsA("BasePart") then
                return inst:GetAttribute("VoxelPosition")
            end

            if inst:IsA("Model") then
                for _, d in ipairs(inst:GetDescendants()) do
                    if d:IsA("BasePart") then
                        local v = d:GetAttribute("VoxelPosition")
                        if v then
                            return v
                        end
                    end
                end
            end

            return nil
        end

        -- =========================
        -- HELPER: ITEM ALLOWED
        -- =========================
        local function isAllowedItem(name)
            return table.find(allowedItems, name) ~= nil and name ~= "All"
        end

        -- =========================
        -- AUTO PICKUP LOOP
        -- =========================
        coroutine.wrap(function()
            while true do
                if vars.AutoPickup then
                    for _, block in ipairs(LoadedBlocks:GetChildren()) do
                        local voxel = getVoxel(block)
                        if voxel then
                            -- MODE ALL
                            if vars.PickupTarget == "All" then
                                if isAllowedItem(block.Name) then
                                    task.spawn(function()
                                        pcall(function()
                                            PickupItem:InvokeServer(
                                                block.Name,
                                                Vector3.new(voxel.X, voxel.Y, voxel.Z)
                                            )
                                        end)
                                    end)
                                end

                            -- MODE SINGLE
                            elseif block.Name == vars.PickupTarget then
                                task.spawn(function()
                                    pcall(function()
                                        PickupItem:InvokeServer(
                                            vars.PickupTarget,
                                            Vector3.new(voxel.X, voxel.Y, voxel.Z)
                                        )
                                    end)
                                end)
                            end

                            task.wait(0.1)
                        end
                    end

                    task.wait(vars.PickupDelay)
                else
                    task.wait(0.5)
                end
            end
        end)()

        print("[Auto Pickup] Sistem aktif | Target:", vars.PickupTarget)
    end
}
