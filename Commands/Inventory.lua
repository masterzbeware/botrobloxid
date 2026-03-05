-- Inventory.lua
return {
    Execute = function(tab)

        local vars = _G.BotVars or {}
        _G.BotVars = vars

        local Tabs = vars.Tabs or {}
        local InventoryTab = tab or Tabs.Inventory

        if not InventoryTab then
            warn("[Inventory] Tab Inventory tidak ditemukan!")
            return
        end

        local Group = InventoryTab:AddLeftGroupbox("Inventory Viewer")

        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local SessionData = require(ReplicatedStorage.Modules.SessionData)
        local ItemData = require(ReplicatedStorage.Modules.Databanks.ItemData)

        local player = Players.LocalPlayer

        local InventoryLabels = {}

        -- FUNCTION
        local function ScanInventory()

            local data = SessionData[player]
            if not data then return end

            local inv = data.Inventory

            for i = 1,36 do

                local item = inv[i]

                if item and next(item) then

                    local id = item[1]
                    local qty = item[2] or 1
                    local name = ItemData.IDLookup[id] or ("ID "..id)

                    InventoryLabels[i]:SetText(name.." x"..qty)

                else
                    InventoryLabels[i]:SetText("")
                end

            end
        end

        -- BUTTON
        Group:AddButton({
            Text = "Refresh Inventory",
            Func = function()
                ScanInventory()
            end
        })

        -- LABEL
        for i = 1,36 do
            InventoryLabels[i] = Group:AddLabel("")
        end

        -- AUTO LOAD
        task.spawn(function()
            repeat task.wait() until SessionData[player]
            ScanInventory()
        end)

        print("[Inventory] Viewer Loaded")

    end
}