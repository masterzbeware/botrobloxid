-- AutoDrop.lua
return {
    Execute = function(tab)

        -- =========================
        -- GLOBAL VARS
        -- =========================
        local vars = _G.BotVars or {}
        vars.AutoDrop      = vars.AutoDrop or false
        vars.DropDelay     = vars.DropDelay or 0.5
        vars.DropItem = vars.DropItem or {"Cacao"}
        vars._AutoDropRun  = vars._AutoDropRun or false
        _G.BotVars = vars

        -- =========================
        -- TAB UI
        -- =========================
        local Tabs = vars.Tabs or {}
        local InventoryTab = tab or Tabs.Inventory
        if not InventoryTab then
            warn("[AutoDrop] Tab Inventory tidak ditemukan!")
            return
        end

        local Group = InventoryTab:AddRightGroupbox("Auto Drop")

        -- =========================
        -- TOGGLE
        -- =========================
        Group:AddToggle("ToggleAutoDrop", {
            Text = "Auto Drop",
            Default = vars.AutoDrop,
            Callback = function(v)
                vars.AutoDrop = v
                print("[AutoDrop] Toggle:", v and "ON" or "OFF")
            end
        })

        -- =========================
        -- ITEM LIST
        -- =========================
        local ItemIDs = {
            ["Cacao"] = 336,
            ["Cacao Seeds"] = 242,
            ["Red Mushroom"] = 2011,
            ["Blue Mushroom"] = 2009
        }

        local dropdownValues = {}
        for name,_ in pairs(ItemIDs) do
            table.insert(dropdownValues, name)
        end

        -- =========================
        -- DROPDOWN
        -- =========================
        Group:AddDropdown("DropdownDropItem", {
            Values = dropdownValues,
            Default = vars.DropItem,
            Multi = true,
            Text = "Item",
Callback = function(v)
    vars.DropItem = v

    print("[AutoDrop] Selected:")
    for _, item in pairs(v) do
        print("-", item)
    end
end
        })

        -- =========================
        -- SLIDER DELAY
        -- =========================
        Group:AddSlider("SliderDropDelay", {
            Text = "Delay Scan (detik)",
            Min = 0.3,
            Max = 3,
            Default = vars.DropDelay,
            Rounding = 1,
            Callback = function(v)
                vars.DropDelay = v
            end
        })

        -- =========================
        -- SERVICES
        -- =========================
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local player = Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()

        local DropItem = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Server")
            :WaitForChild("DropItem")

        local invGui = player.PlayerGui:WaitForChild("Inventory")

        -- =========================
        -- SCAN & DROP FUNCTION
        -- =========================
        local function ScanAndDrop()

local function isTargetItem(id)
    if not id then return false end

    for _, itemName in pairs(vars.DropItem) do
        if tostring(ItemIDs[itemName]) == tostring(id) then
            return true
        end
    end
    return false
end

            for i = 1,36 do

                if not vars.AutoDrop then
                    return
                end

                local slot = invGui:FindFirstChild(tostring(i), true)

                if slot then
                    local foundID = nil

                    for _,v in ipairs(slot:GetDescendants()) do
                        local id = v:GetAttribute("ID")
                        if id then
                            foundID = id
                            break
                        end
                    end

                    if isTargetItem(foundID) then

                        local ok, err = pcall(function()
                            DropItem:InvokeServer(
                                i,
                                99,
                                char.PrimaryPart.CFrame.LookVector,
                                i
                            )
                        end)

                        if ok then
                            print("[AutoDrop] Dropped:", table.concat(vars.DropItem, ", "), "slot", i)
                        else
                            warn("[AutoDrop] Error:", err)
                        end

                        task.wait(0.3)
                    end
                end
            end
        end

        -- =========================
        -- AUTO LOOP
        -- =========================
        if vars._AutoDropRun then
            warn("[AutoDrop] Loop sudah berjalan")
            return
        end
        vars._AutoDropRun = true

        task.spawn(function()
            while true do

                if vars.AutoDrop then
                    ScanAndDrop()
                end

                task.wait(vars.DropDelay)
            end
        end)

        print("[AutoDrop] System Loaded")
    end
}