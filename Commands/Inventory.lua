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

        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        local Group = InventoryTab:AddLeftGroupbox("Inventory Viewer")

        local InventoryLabels = {}

        -- =========================
        -- SCAN INVENTORY (UI BASED)
        -- =========================
        local function ScanInventory()

            local gui = player:FindFirstChild("PlayerGui")
            if not gui then return end

            local invGui = gui:FindFirstChild("Inventory")
            if not invGui then return end

            local backpack = invGui:FindFirstChild("Backpack")
            if not backpack then return end

            local slots = backpack:FindFirstChild("Slots")
            if not slots then return end

            local line = 1

            -- clear label
            for i = 1,36 do
                if InventoryLabels[i] then
                    InventoryLabels[i]:SetText("")
                end
            end

            -- scan slot
            for i = 1,36 do

                local slot = slots:FindFirstChild(tostring(i))

                if slot then
                    local qty = slot:FindFirstChild("Quantity")

                    if qty and qty:IsA("TextLabel") then
                        local amount = tonumber(qty.Text)

                        if amount and amount > 0 then
                            InventoryLabels[line]:SetText("Slot "..i.." x"..amount)
                            line += 1
                        end
                    end
                end

            end

        end

        -- =========================
        -- BUTTON
        -- =========================
        Group:AddButton({
            Text = "Refresh Inventory",
            Func = ScanInventory
        })

        -- =========================
        -- LABELS
        -- =========================
        for i = 1,36 do
            InventoryLabels[i] = Group:AddLabel("")
        end

        -- =========================
        -- AUTO LOAD
        -- =========================
        task.spawn(function()

            repeat task.wait()
            until player:FindFirstChild("PlayerGui")

            ScanInventory()

        end)

        print("[Inventory] Viewer Loaded")

    end
}