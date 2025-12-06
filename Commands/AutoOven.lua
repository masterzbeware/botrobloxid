return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local OvenTab = tab or Tabs.Oven

        if not OvenTab then
            warn("[Auto Oven] Tab Oven tidak ditemukan!")
            return
        end

        local Group = OvenTab:AddLeftGroupbox("Auto Oven + Crop")

        vars.AutoOven = vars.AutoOven or false
        vars.AutoCrop = vars.AutoCrop or false

        Group:AddToggle("ToggleAutoOven", {
            Text = "Auto Oven",
            Default = vars.AutoOven,
            Callback = function(v)
                vars.AutoOven = v
            end
        })

        Group:AddToggle("ToggleAutoCrop", {
            Text = "Auto Crop",
            Default = vars.AutoCrop,
            Callback = function(v)
                vars.AutoCrop = v
            end
        })

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local CraftItem = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Inventory"):WaitForChild("CraftItem")
        local HarvestCrop = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks"):WaitForChild("HarvestCrop")

        -- Buat list posisi oven & crop
        local ovenPositions = {}
        local cropPositions = {}
        for z = -5, 25 do
            for _, x in ipairs({-2, -4, -6, -8, -10, -12, -14}) do
                table.insert(ovenPositions, Vector3.new(x, 1, z))
                table.insert(cropPositions, Vector3.new(x, 1, z))
            end
        end

        -- Coroutine untuk loop auto oven & crop
        coroutine.wrap(function()
            while true do
                if vars.AutoOven then
                    -- Auto Craft Oven
                    for i, pos in ipairs(ovenPositions) do
                        pcall(function()
                            CraftItem:InvokeServer("Baker's Oven", "Chocolate Bar", pos)
                        end)
                        task.wait(0.3)
                    end
                    print("Semua oven selesai dicraft! Tunggu 3 menit 20 detik sebelum panen crop...")
                    task.wait(181)
                else
                    task.wait(1)
                end

                if vars.AutoCrop then
                    -- Auto Crop
                    for i, pos in ipairs(cropPositions) do
                        pcall(function()
                            HarvestCrop:InvokeServer(pos)
                        end)
                        task.wait(0.2)
                    end
                    print("Semua crop selesai dipanen! Ulangi dari awal...")
                else
                    task.wait(0.5)
                end
            end
        end)()

        print("Sistem Auto Oven + Crop aktif.")
    end
}
