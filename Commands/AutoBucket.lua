-- AutoBucket.lua (ANTI LAG VERSION)
return {
    Execute = function(tab)
        -- =========================
        -- GLOBAL VARS
        -- =========================
        local vars = _G.BotVars or {}
        vars.AutoBucket     = vars.AutoBucket or false
        vars.BucketDelay    = vars.BucketDelay or 0.3     -- delay per cycle
        vars._AutoBucketRun = vars._AutoBucketRun or false
        _G.BotVars = vars

        -- =========================
        -- TAB & UI
        -- =========================
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main
        if not MainTab then return end

        local Group = MainTab:AddRightGroupbox("Auto Bucket")

        -- TOGGLE
        Group:AddToggle("ToggleAutoBucket", {
            Text = "Auto Bucket",
            Default = vars.AutoBucket,
            Callback = function(v)
                vars.AutoBucket = v
                print("[AutoBucket] Toggle:", v and "ON" or "OFF")
            end
        })

        -- SLIDER DELAY
        Group:AddSlider("SliderBucketDelay", {
            Text = "Delay Scan (detik)",
            Min = 0.3,
            Max = 3,
            Default = vars.BucketDelay,
            Rounding = 0,
            Callback = function(v)
                vars.BucketDelay = v
            end
        })

        -- =========================
        -- SERVICES
        -- =========================
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local FillBucket = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Inventory")
            :WaitForChild("FillBucket")

        -- =========================
        -- WELL WHITELIST
        -- =========================
        local WellList = {
            ["Brick Well"] = true,
            ["Stone Well"] = true
        }

        -- =========================
        -- SCAN FUNCTION
        -- =========================
        local function ScanWells()
            local wells = {}

            for _, block in ipairs(LoadedBlocks:GetChildren()) do
                if block:IsA("Model") and WellList[block.Name] then
                    local voxel = block:GetAttribute("VoxelPosition")
                    if voxel then
                        table.insert(wells, {
                            name = block.Name,
                            voxel = voxel
                        })
                    end
                end
            end

            return wells
        end

        -- =========================
        -- AUTO BUCKET LOOP
        -- =========================
        if vars._AutoBucketRun then
            warn("[AutoBucket] Loop sudah berjalan")
            return
        end
        vars._AutoBucketRun = true

        task.spawn(function()
            while true do
                if vars.AutoBucket then
                    local wells = ScanWells()

                    if #wells > 0 then
                        print("[AutoBucket] Ditemukan", #wells, "well")
                    end

                    for i, data in ipairs(wells) do
                        if not vars.AutoBucket then break end

                        local pos = vector.create(
                            data.voxel.X,
                            data.voxel.Y,
                            data.voxel.Z
                        )

                        local ok, err = pcall(function()
                            FillBucket:InvokeServer(pos)
                        end)

                        if ok then
                            print("[AutoBucket] Fill", data.name, "#"..i)
                        else
                            warn("[AutoBucket] Gagal fill:", err)
                        end

                        task.wait(0.2) -- jeda kecil antar well (ANTI LAG)
                    end
                end

                task.wait(vars.BucketDelay)
            end
        end)

        print("[AutoBucket] System Loaded (ANTI LAG)")
    end
}
