return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local OvenTab = tab or Tabs.Main

        if not OvenTab then
            warn("[Auto Oven] Tab Oven tidak ditemukan!")
            return
        end

        local Group = OvenTab:AddLeftGroupbox("Auto Oven")

        vars.AutoOven = vars.AutoOven or false

        Group:AddToggle("ToggleAutoOven", {
            Text = "Auto Oven",
            Default = vars.AutoOven,
            Callback = function(v)
                vars.AutoOven = v
            end
        })

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
        local CraftItem = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Inventory"):WaitForChild("CraftItem")

        -- Coroutine untuk loop auto oven
        coroutine.wrap(function()
            while true do
                if vars.AutoOven then
                    for i, block in ipairs(LoadedBlocks:GetChildren()) do
                        if block.Name == "Baker's Oven" then
                            local voxel = block:GetAttribute("VoxelPosition")
                            if voxel then
                                local success, err = pcall(function()
                                    CraftItem:InvokeServer("Baker's Oven", "Chocolate Bar", voxel)
                                end)
                                if success then
                                    print("Craft oven ke", i, "selesai")
                                else
                                    warn("Gagal craft oven ke", i, err)
                                end
                                task.wait(0.3) -- delay antar oven
                            end
                        end
                    end

                    print("Selesai loop craft semua oven. Menunggu 3 menit 20 detik sebelum loop berikutnya...")
                    task.wait(181) -- tunggu 3 menit 20 detik
                else
                    task.wait(1) -- jika toggle mati, cek lagi tiap detik
                end
            end
        end)()

        print("Sistem Auto Oven aktif.")
    end
}
