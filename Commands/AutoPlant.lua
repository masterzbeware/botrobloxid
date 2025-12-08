-- AutoPlant.lua
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main

        if not MainTab then
            warn("[Auto Plant] Tab tidak ditemukan!")
            return
        end

        -- =========================
        -- UI GROUP
        -- =========================
        local Group
        if MainTab.AddRightGroupbox then
            Group = MainTab:AddRightGroupbox("Auto Plant")
        else
            Group = MainTab:AddLeftGroupbox("Auto Plant")
            warn("[Auto Plant] AddRightGroupbox tidak tersedia, menggunakan AddLeftGroupbox")
        end

        -- =========================
        -- DEFAULT VARS
        -- =========================
        vars.AutoPlant = vars.AutoPlant or false
        vars.PlantDelay = vars.PlantDelay or 5
        vars.PlantTarget = vars.PlantTarget or "Cacao"
        _G.BotVars = vars

        -- =========================
        -- TOGGLE
        -- =========================
        Group:AddToggle("ToggleAutoPlant", {
            Text = "Auto Plant",
            Default = vars.AutoPlant,
            Callback = function(v)
                vars.AutoPlant = v
                print("[Auto Plant] Toggle:", v and "ON" or "OFF")
            end
        })

        -- =========================
        -- ALLOWED CROPS
        -- =========================
        local allowedCrops = {"Cacao", "Coffee", "Wheat", "Sugarcane"}

        -- =========================
        -- DROPDOWN PILIH CROP
        -- =========================
        task.spawn(function()
            task.wait(0.5)
            if Group.AddDropdown then
                local dropdown = Group:AddDropdown("DropdownPlantTarget", {
                    Text = "Pilih Crop",
                    Values = allowedCrops,
                    Default = vars.PlantTarget,
                    Multi = false,
                    Callback = function(v)
                        vars.PlantTarget = v
                        print("[Auto Plant] Target diubah ke:", v)
                    end
                })
                dropdown:SetValue(vars.PlantTarget)
            else
                warn("[Auto Plant] AddDropdown tidak tersedia di Group")
            end
        end)

        -- =========================
        -- SLIDER DELAY
        -- =========================
        Group:AddSlider("SliderPlantDelay", {
            Text = "Delay Plant",
            Default = vars.PlantDelay,
            Min = 5,
            Max = 10,
            Rounding = 1,
            Compact = false,
            Callback = function(v)
                vars.PlantDelay = v
            end
        })

        -- =========================
        -- SERVICES
        -- =========================
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
        local HarvestCrop = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks"):WaitForChild("HarvestCrop")

        -- =========================
        -- LOOP PLANT (toggle OFF menghentikan proses)
        -- =========================
        coroutine.wrap(function()
            while true do
                if vars.AutoPlant then
                    for i, block in ipairs(LoadedBlocks:GetChildren()) do
                        if block:IsA("MeshPart") and block.Name == vars.PlantTarget then
                            local voxel = block:GetAttribute("VoxelPosition")
                            if voxel then
                                -- spawn per block biar tidak lag
                                task.spawn(function()
                                    local success, err = pcall(function()
                                        HarvestCrop:InvokeServer(vector.create(voxel.X, voxel.Y, voxel.Z))
                                    end)
                                    if not success then
                                        warn("Gagal harvest", block.Name, err)
                                    end
                                end)
                                task.wait(0.1) -- delay mini antar block
                            end
                        end
                    end
                    task.wait(vars.PlantDelay)
                else
                    -- toggle OFF → tunggu sampai toggle ON, tidak looping sia-sia
                    repeat task.wait(2) until vars.AutoPlant
                end
            end
        end)()

        print("[Auto Plant] Sistem aktif. Target:", vars.PlantTarget)
    end
}
