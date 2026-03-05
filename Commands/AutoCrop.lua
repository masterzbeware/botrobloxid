-- AutoCrop.lua (FAST VERSION)
return {
    Execute = function(tab)

        -- =========================
        -- GLOBAL VARS
        -- =========================
        local vars = _G.BotVars or {}
        vars.AutoCrop      = vars.AutoCrop or false
        vars.CropDelay     = vars.CropDelay or 0.3
        vars.CropTarget    = vars.CropTarget or "Cacao"
        vars._AutoCropRun  = vars._AutoCropRun or false
        _G.BotVars = vars

        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main
        if not MainTab then
            warn("[Auto Crop] Tab tidak ditemukan!")
            return
        end

        -- =========================
        -- UI GROUP
        -- =========================
        local Group = MainTab:AddLeftGroupbox("Auto Crop")

        -- TOGGLE
        Group:AddToggle("ToggleAutoCrop", {
            Text = "Auto Crop",
            Default = vars.AutoCrop,
            Callback = function(v)
                vars.AutoCrop = v
                print("[Auto Crop] Toggle:", v and "ON" or "OFF")
            end
        })

        -- =========================
        -- CROPS
        -- =========================
        local allowedCrops = {"Cacao","Cranberry","Wheat","Grass"}

        Group:AddDropdown("DropdownCropTarget", {
            Text = "Pilih Crop",
            Values = allowedCrops,
            Default = vars.CropTarget,
            Multi = false,
            Callback = function(v)
                vars.CropTarget = v
                print("[Auto Crop] Target diubah ke:", v)
            end
        })

        -- DELAY
        Group:AddSlider("SliderCropDelay", {
            Text = "Delay Panen",
            Default = vars.CropDelay,
            Min = 0.1,
            Max = 4,
            Rounding = 1,
            Callback = function(v)
                vars.CropDelay = v
            end
        })

        -- =========================
        -- SERVICES
        -- =========================
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local HarvestCrop = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Blocks")
            :WaitForChild("HarvestCrop")

        -- =========================
        -- FAST HARVEST
        -- =========================
        local function ScanAndHarvest()

            local crops = {}

            -- scan sekali
            for _, block in ipairs(LoadedBlocks:GetChildren()) do
                if block:IsA("MeshPart") and block.Name == vars.CropTarget then
                    local voxel = block:GetAttribute("VoxelPosition")
                    if voxel then
                        table.insert(crops, voxel)
                    end
                end
            end

            -- harvest paralel
            for _, voxel in ipairs(crops) do

                if not vars.AutoCrop then
                    return
                end

                task.spawn(function()
                    pcall(function()
                        HarvestCrop:InvokeServer(
                            vector.create(voxel.X, voxel.Y, voxel.Z)
                        )
                    end)
                end)
            end
        end

        -- =========================
        -- AUTO LOOP
        -- =========================
        if vars._AutoCropRun then
            warn("[Auto Crop] Loop sudah berjalan")
            return
        end

        vars._AutoCropRun = true

        task.spawn(function()

            while true do

                if vars.AutoCrop then
                    ScanAndHarvest()
                end

                task.wait(vars.CropDelay)

            end

        end)

        print("[Auto Crop] System Loaded (FAST)")
    end
}