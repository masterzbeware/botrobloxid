-- AutoClear.lua
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}

        -- gunakan Tab Inventory
        local InventoryTab = tab or Tabs.Inventory

        if not InventoryTab then
            warn("[Auto Clear] Tab Inventory tidak ditemukan!")
            return
        end

        -- =========================
        -- UI GROUP
        -- =========================
        local Group = InventoryTab:AddLeftGroupbox("Auto Clear")

        -- =========================
        -- DEFAULT VARS
        -- =========================
        vars.AutoClear = vars.AutoClear or false
        _G.BotVars = vars

        -- =========================
        -- SERVICES
        -- =========================
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local CleanupItems = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Server")
            :WaitForChild("CleanupItems")

        -- =========================
        -- TOGGLE
        -- =========================
        Group:AddToggle("ToggleAutoClear", {
            Text = "Auto Clear Items",
            Default = vars.AutoClear,
            Callback = function(v)
                vars.AutoClear = v
                print("[Auto Clear]:", v and "ON" or "OFF")
            end
        })

        -- =========================
        -- LOOP
        -- =========================
        coroutine.wrap(function()
            while true do
                if vars.AutoClear then
                    pcall(function()
                        CleanupItems:InvokeServer()
                    end)
                    task.wait(5) -- delay biar ga spam
                else
                    repeat task.wait(0.5) until vars.AutoClear
                end
            end
        end)()

        print("[Auto Clear] Sistem aktif")
    end
}