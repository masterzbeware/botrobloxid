-- AutoPickup.lua
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
        vars.PickupTarget = vars.PickupTarget or "Oak Sticks"
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
        -- ITEM YANG BISA DIPICKUP
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
        -- DROPDOWN ITEM
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
                        print("[Auto Pickup] Target diubah ke:", v)
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
        -- HELPER FUNCTION
        -- =========================
        local function getVoxelFromInstance(inst)
            -- Part / MeshPart / Union
            if inst:IsA("BasePart") then
                return inst:GetAttribute("VoxelPosition")
            end

            -- Model
            if inst:IsA("Model") then
                for _, child in ipairs(inst:GetDescendants()) do
                    if child:IsA("BasePart") then
                        local voxel = child:GetAttribute("VoxelPosition")
                        if voxel then
                            return voxel
                        end
                    end
                end
            end

            return nil
        end

        -- =========================
        -- AUTO PICKUP LOOP
        -- =========================
        coroutine.wrap(function()
            while true do
                if vars.AutoPickup then
                    for _, block in ipairs(LoadedBlocks:GetChildren()) do
                        local voxel = getVoxelFromInstance(block)
                        if voxel then
                            -- MODE ALL
                            if vars.PickupTarget == "All" then
                                for _, itemName in ipairs(allowedItems) do
                                    if itemName ~= "All" and block.Name == itemName then
                                        task.spawn(function()
                                            pcall(function()
                                                PickupItem:InvokeServer(
                                                    itemName,
                                                    Vector3.new(voxel.X, voxel.Y, voxel.Z)
                                                )
                                            end)
                                        end)
                                    end
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
                    repeat task.wait(0.5) until vars.AutoPickup
                end
            end
        end)()

        print("[Auto Pickup] Sistem aktif. Target:", vars.PickupTarget)
    end
}
