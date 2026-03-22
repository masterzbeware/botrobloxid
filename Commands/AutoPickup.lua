-- AutoPickup.lua
return {
    Execute = function(tab)

        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}

        -- gunakan tab Harvest
        local HarvestTab = tab or Tabs.Harvest

        if not HarvestTab then
            warn("[Auto Pickup] Tab Harvest tidak ditemukan!")
            return
        end

        -- UI GROUP
        local Group = HarvestTab:AddLeftGroupbox("Auto Pickup Items")

        -- DEFAULT VARS
        vars.AutoPickup = vars.AutoPickup or false
        vars.PickupAll = vars.PickupAll or false
        vars.PickupDelay = vars.PickupDelay or 0.5
        vars.PickupTarget = vars.PickupTarget or "Oak Sticks"

        _G.BotVars = vars

        -- ITEM LIST
        local pickupItems = {
            "Oak Sticks",
            "Birch Sticks",
            "Blue Mushroom Cluster",
            "Red Mushroom Cluster",
            "Cave Mushroom Cluster",
            "Purple Mushroom Cluster",
            "Wild Blueberry",
            "Wild Strawberry",
            "Yellow Flowers",
            "Conch",
            "Scallop",
            "Oyster",
            "Wild Cactus",
            "Large Yellow Flower"
            "Sand Dollar",
            "Fossil"
        }

        -- TOGGLE AUTO PICKUP SELECTED
        Group:AddToggle("ToggleAutoPickup", {
            Text = "Auto Pickup Selected",
            Default = vars.AutoPickup,
            Callback = function(v)
                vars.AutoPickup = v
            end
        })

        -- TOGGLE PICKUP ALL
        Group:AddToggle("TogglePickupAll", {
            Text = "Pickup All Items",
            Default = vars.PickupAll,
            Callback = function(v)
                vars.PickupAll = v
            end
        })

        -- DROPDOWN
        local dropdown = Group:AddDropdown("DropdownPickupTarget", {
            Text = "Select Item",
            Values = pickupItems,
            Default = vars.PickupTarget,
            Multi = false,
            Callback = function(v)
                vars.PickupTarget = v
            end
        })

        dropdown:SetValue(vars.PickupTarget)

        -- SLIDER DELAY
        Group:AddSlider("SliderPickupDelay", {
            Text = "Pickup Delay",
            Default = vars.PickupDelay,
            Min = 0.1,
            Max = 2,
            Rounding = 2,
            Callback = function(v)
                vars.PickupDelay = v
            end
        })

        -- SERVICES
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local PickupRemote = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Server"):WaitForChild("PickupItem")

        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        -- SCAN ITEM
        local function scanAndPickup()

            for _, block in ipairs(LoadedBlocks:GetChildren()) do

                local name = block.Name
                local voxel = block:GetAttribute("VoxelPosition")

                if voxel then

                    if vars.PickupAll and table.find(pickupItems, name) then

                        pcall(function()
                            PickupRemote:InvokeServer(
                                name,
                                vector.create(voxel.X, voxel.Y, voxel.Z)
                            )
                        end)

                    elseif vars.AutoPickup and name == vars.PickupTarget then

                        pcall(function()
                            PickupRemote:InvokeServer(
                                name,
                                vector.create(voxel.X, voxel.Y, voxel.Z)
                            )
                        end)

                    end

                end

            end

        end

        -- LOOP
        task.spawn(function()

            while true do

                if vars.AutoPickup or vars.PickupAll then
                    scanAndPickup()
                    task.wait(vars.PickupDelay)
                else
                    task.wait(0.5)
                end

            end

        end)

        print("[Auto Pickup] Loaded")

    end
}