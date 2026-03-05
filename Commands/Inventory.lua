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

        -- =========================
        -- PLAYER LIST
        -- =========================
        local function GetPlayers()

            local list = {}

            for _,plr in ipairs(Players:GetPlayers()) do
                table.insert(list, plr.Name)
            end

            table.sort(list)

            return list
        end

        -- =========================
        -- INVENTORY SCAN
        -- =========================
        local function GetInventory(playerName)

            local plr = Players:FindFirstChild(playerName)
            if not plr then
                return {}
            end

            local data = SessionData[plr]
            if not data then
                return {}
            end

            local inv = data.Inventory

            local items = {}

            for i = 1,36 do

                local item = inv[i]

                if item and next(item) then

                    local id = item[1]
                    local qty = item[2] or 1

                    local name = ItemData.IDLookup[id] or ("ID "..id)

                    table.insert(items, name.." x"..qty)

                end
            end

            if #items == 0 then
                table.insert(items,"Inventory Kosong")
            end

            return items

        end

        -- =========================
        -- DROPDOWN PLAYER
        -- =========================
        local PlayerDropdown
        local ItemDropdown

        PlayerDropdown = Group:AddDropdown("InventoryPlayer", {
            Text = "Pilih Player",
            Values = GetPlayers(),
            Multi = false,
            Default = 1,

            Callback = function(playerName)

                print("[Inventory] Player dipilih:",playerName)

                local items = GetInventory(playerName)

                if ItemDropdown then
                    ItemDropdown:SetValues(items)
                end

            end
        })

        -- =========================
        -- DROPDOWN INVENTORY
        -- =========================
        ItemDropdown = Group:AddDropdown("InventoryItems", {
            Text = "Inventory Player",
            Values = {"Pilih player dulu"},
            Multi = false
        })

        -- =========================
        -- UPDATE PLAYER LIST
        -- =========================
        local function RefreshPlayers()

            local list = GetPlayers()

            PlayerDropdown:SetValues(list)

        end

        Players.PlayerAdded:Connect(RefreshPlayers)
        Players.PlayerRemoving:Connect(RefreshPlayers)

        print("[Inventory] Viewer Loaded")

    end
}