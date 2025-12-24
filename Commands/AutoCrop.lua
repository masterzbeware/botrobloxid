-- AutoCrop.lua (ALL CROPS - ANTI LAG)
return {
    Execute = function(tab)
        -- =========================
        -- GLOBAL VARS
        -- =========================
        local vars = _G.BotVars or {}
        vars.AutoCrop      = vars.AutoCrop or false
        vars.CropDelay     = vars.CropDelay or 10     -- jeda per cycle
        vars._AutoCropRun  = vars._AutoCropRun or false
        _G.BotVars = vars

        -- =========================
        -- TAB & UI
        -- =========================
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main
        if not MainTab then return end

        local Group = MainTab:AddLeftGroupbox("Auto Crop")

        -- TOGGLE
        Group:AddToggle("ToggleAutoCrop", {
            Text = "Auto Crop (All)",
            Default = vars.AutoCrop,
            Callback = function(v)
                vars.AutoCrop = v
                print("[AutoCrop] Toggle:", v and "ON" or "OFF")
            end
        })

        -- SLIDER JEDA CYCLE
        Group:AddSlider("SliderCropDelay", {
            Text = "Delay Scan (detik)",
            Min = 3,
            Max = 5,
            Default = vars.CropDelay,
            Rounding = 0,
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
        -- CROP WHITELIST
        -- =========================
        local CropList = {
            Cacao = true,
            Cranberry = true,
            Wheat = true
        }

        -- =========================
        -- SCAN FUNCTION
        -- =========================
        local function ScanCrops()
            local crops = {}

            for _, block in ipairs(LoadedBlocks:GetChildren()) do
                if block:IsA("MeshPart") and CropList[block.Name] then
                    local voxel = block:GetAttribute("VoxelPosition")
                    if voxel then
                        table.insert(crops, voxel)
                    end
                end
            end

            return crops
        end

        -- =========================
        -- AUTO CROP LOOP
        -- =========================
        if vars._AutoCropRun then
            warn("[AutoCrop] Loop sudah berjalan")
            return
        end
        vars._AutoCropRun = true

        task.spawn(function()
            while true do
                if vars.AutoCrop then
                    local crops = ScanCrops()

                    if #crops > 0 then
                        print("[AutoCrop] Ditemukan", #crops, "crop")
                    end

                    for i, voxel in ipairs(crops) do
                        if not vars.AutoCrop then break end

                        local pos = vector.create(voxel.X, voxel.Y, voxel.Z)

                        local ok, err = pcall(function()
                            HarvestCrop:InvokeServer(pos)
                        end)

                        if not ok then
                            warn("[AutoCrop] Harvest gagal:", err)
                        end

                        task.wait(0.15) -- jeda kecil (ANTI LAG)
                    end
                end

                task.wait(vars.CropDelay)
            end
        end)

        print("[AutoCrop] System Loaded (ALL CROPS)")
    end
}
