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
            "Purple Mushroom Cluster",
            "Wild Blueberry",
            "Wild Strawberry",
            "Yellow Flowers",
            "Conch",
            "Scallop",
            "Oyster",
            "Wild Cactus",
            "Fossil"
        }

        -- TOGGLE AUTO PICKUP SELECTED
        Group:AddToggle("ToggleAutoPickup", {
            Text = "Auto Pickup Selected",
            Default = vars.AutoPickup,
            Callback = function(v)
                vars.AutoPickup = v
                print("[Auto Pickup] Selected:", v and "ON" or "OFF")
            end
        })

        -- TOGGLE PICKUP ALL
        Group:AddToggle("TogglePickupAll", {
            Text = "Pickup All Items",
            Default = vars.PickupAll,
            Callback = function(v)
                vars.PickupAll = v
                print("[Auto Pickup] All Items:", v and "ON" or "OFF")
            end
        })

        -- DROPDOWN ITEM
        task.spawn(function()
            task.wait(0.5)

            if Group.AddDropdown then
                local dropdown = Group:AddDropdown("DropdownPickupTarget", {
                    Text = "Select Item",
                    Values = pickupItems,
                    Default = vars.PickupTarget,
                    Multi = false,
                    Callback = function(v)
                        vars.PickupTarget = v
                        print("[Auto Pickup] Target:", v)
                    end
                })

                dropdown:SetValue(vars.PickupTarget)
            else
                warn("[Auto Pickup] AddDropdown tidak tersedia!")
            end
        end)

        -- SLIDER DELAY
        Group:AddSlider("SliderPickupDelay", {
            Text = "Pickup Delay",
            Default = vars.PickupDelay,
            Min = 0.1,
            Max = 2,
            Rounding = 1,
            Callback = function(v)
                vars.PickupDelay = v
            end
        })

        -- SERVICES
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local PickupRemote = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Server"):WaitForChild("PickupItem")

        -- SCAN ITEM DI MAP
        local function scanAndPickup()
            local dropped = workspace:FindFirstChild("Dropped")
            if not dropped then return end

            for _, item in ipairs(dropped:GetChildren()) do

                local itemName = item.Name
                local pos = item:GetAttribute("VoxelPosition")

                if pos then

                    if vars.PickupAll and table.find(pickupItems, itemName) then

                        pcall(function()
                            PickupRemote:InvokeServer(itemName, vector.create(pos.X, pos.Y, pos.Z))
                        end)

                    elseif vars.AutoPickup and itemName == vars.PickupTarget then

                        pcall(function()
                            PickupRemote:InvokeServer(itemName, vector.create(pos.X, pos.Y, pos.Z))
                        end)

                    end
                end
            end
        end

        -- LOOP SYSTEM
        coroutine.wrap(function()
            while true do

                if vars.AutoPickup or vars.PickupAll then
                    pcall(scanAndPickup)
                    task.wait(vars.PickupDelay)
                else
                    task.wait(0.5)
                end

            end
        end)()

        print("[Auto Pickup] System Loaded")

    end
}