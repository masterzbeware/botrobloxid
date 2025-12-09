-- AutoCrop.lua
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
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

        -- =========================
        -- DEFAULT VARS
        -- =========================
        vars.AutoCrop   = vars.AutoCrop or false
        vars.CropDelay  = vars.CropDelay or 0.3
        vars.CropTarget = vars.CropTarget or "Cacao"
        _G.BotVars = vars

        -- =========================
        -- TOGGLE
        -- =========================
        Group:AddToggle("ToggleAutoCrop", {
            Text = "Auto Crop",
            Default = vars.AutoCrop,
            Callback = function(v)
                vars.AutoCrop = v
                print("[Auto Crop] Toggle:", v and "ON" or "OFF")
            end
        })

        -- =========================
        -- ALLOWED CROPS
        -- =========================
        local allowedCrops = {"Cacao","Cranberry","Wheat"}

        -- =========================
        -- DROPDOWN PILIH CROP
        -- =========================
        task.defer(function()
            if Group.AddDropdown then
                local dropdown = Group:AddDropdown("DropdownCropTarget", {
                    Text = "Pilih Crop",
                    Values = allowedCrops,
                    Default = vars.CropTarget,
                    Multi = false,
                    Callback = function(v)
                        vars.CropTarget = v
                        print("[Auto Crop] Target diubah ke:", v)
                    end
                })
                dropdown:SetValue(vars.CropTarget)
            else
                warn("[Auto Crop] AddDropdown tidak tersedia")
            end
        end)

        -- =========================
        -- SLIDER DELAY
        -- =========================
        Group:AddSlider("SliderCropDelay", {
            Text = "Delay Panen",
            Default = vars.CropDelay,
            Min = 0.3,
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
        local HarvestCrop = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks"):WaitForChild("HarvestCrop")

        -- =========================
        -- AUTO CROP LOOP
        -- =========================
        coroutine.wrap(function()
            while true do
                if vars.AutoCrop then
                    for _, block in ipairs(LoadedBlocks:GetChildren()) do
                        if block:IsA("MeshPart") and block.Name == vars.CropTarget then
                            local voxel = block:GetAttribute("VoxelPosition")
                            if voxel then
                                task.spawn(function()
                                    pcall(function()
                                        HarvestCrop:InvokeServer(vector.create(voxel.X, voxel.Y, voxel.Z))
                                    end)
                                end)
                                task.wait(0.1)
                            end
                        end
                    end
                    task.wait(vars.CropDelay)
                else
                    repeat task.wait(0.5) until vars.AutoCrop
                end
            end
        end)()

        print("[Auto Crop] Sistem aktif. Target:", vars.CropTarget)
    end
}
