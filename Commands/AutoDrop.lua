-- AutoDrop.lua
return {
    Execute = function(tab)

        -- =========================
        -- GLOBAL VARS
        -- =========================
        local vars = _G.BotVars or {}
        vars.AutoDrop      = vars.AutoDrop or false
        vars.DropDelay     = vars.DropDelay or 0.5
        vars.DropItem      = vars.DropItem or "Cacao"
        vars._AutoDropRun  = vars._AutoDropRun or false
        _G.BotVars = vars

        -- =========================
        -- TAB UI
        -- =========================
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main
        if not MainTab then return end

        local Group = MainTab:AddRightGroupbox("Auto Drop")

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
            ["Cacao Seeds"] = 242
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
            Default = 1,
            Multi = false,
            Text = "Item",
            Callback = function(v)
                vars.DropItem = v
                print("[AutoDrop] Selected:", v)
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

            local targetID = ItemIDs[vars.DropItem]
            if not targetID then return end

            for i = 1,36 do

                -- STOP LANGSUNG JIKA TOGGLE OFF
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

                    if foundID == targetID then

                        local ok, err = pcall(function()
                            DropItem:InvokeServer(
                                i,
                                99,
                                char.PrimaryPart.CFrame.LookVector,
                                i
                            )
                        end)

                        if ok then
                            print("[AutoDrop] Dropped", vars.DropItem, "slot", i)
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

        print("[AutoDrop] System Loaded (Fixed)")
    end
}