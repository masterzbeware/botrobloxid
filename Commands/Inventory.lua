-- Inventory.lua
return {
    Execute = function(tab)

        -- =========================
        -- GLOBAL VARS
        -- =========================
        local vars = _G.BotVars or {}
        _G.BotVars = vars

        -- =========================
        -- TAB UI
        -- =========================
        local Tabs = vars.Tabs or {}
        local InventoryTab = tab or Tabs.Inventory

        if not InventoryTab then
            warn("[Inventory] Tab Inventory tidak ditemukan!")
            return
        end

        local Group = InventoryTab:AddLeftGroupbox("Inventory Viewer")

        -- =========================
        -- SERVICES
        -- =========================
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local SessionData = require(ReplicatedStorage.Modules.SessionData)
        local ItemData = require(ReplicatedStorage.Modules.Databanks.ItemData)

        local player = Players.LocalPlayer

        -- =========================
        -- LABEL STORAGE
        -- =========================
        local InventoryLabels = {}

        -- =========================
        -- CLEAR LABELS
        -- =========================
        local function ClearLabels()

            for _,label in ipairs(InventoryLabels) do
                pcall(function()
                    label:Destroy()
                end)
            end

            table.clear(InventoryLabels)

        end

        -- =========================
        -- SCAN INVENTORY
        -- =========================
        local function ScanInventory()

            ClearLabels()

            local data = SessionData[player]

            if not data then
                table.insert(InventoryLabels,
                    Group:AddLabel("SessionData belum load"))
                return
            end

            local inv = data.Inventory
            local foundItem = false

            for i = 1,36 do

                local item = inv[i]

                if item and next(item) then

                    local id = item[1]
                    local qty = item[2] or 1

                    local name = ItemData.IDLookup[id] or ("ID "..id)

                    local label = Group:AddLabel(name.." x"..qty)

                    table.insert(InventoryLabels,label)

                    foundItem = true

                end
            end

            if not foundItem then

                local label = Group:AddLabel("Inventory kosong")

                table.insert(InventoryLabels,label)

            end

        end

        -- =========================
        -- BUTTON REFRESH
        -- =========================
        Group:AddButton({
            Text = "Refresh Inventory",
            Func = function()

                print("[Inventory] Refresh")

                ScanInventory()

            end
        })

        -- =========================
        -- AUTO LOAD
        -- =========================
        task.spawn(function()

            repeat task.wait() until SessionData[player]

            ScanInventory()

        end)

        print("[Inventory] Viewer Loaded")

    end
}