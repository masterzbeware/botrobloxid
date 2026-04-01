-- AutoInsert.lua
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}

        -- gunakan tab Craft
        local CraftTab = tab or Tabs.Craft

        if not CraftTab then
            warn("[Auto Insert] Tab Craft tidak ditemukan!")
            return
        end

        -- UI GROUP
        local Group = (CraftTab.AddRightGroupbox and CraftTab:AddRightGroupbox("Auto Insert Items"))
            or CraftTab:AddLeftGroupbox("Auto Insert Items")

        -- DEFAULT VARS
        vars.AutoInsert    = vars.AutoInsert or false
        vars.InsertDelay   = vars.InsertDelay or 1
        vars.InsertTarget  = vars.InsertTarget or "Compost Bin"
        vars._AutoInsertRun = vars._AutoInsertRun or false
        _G.BotVars = vars

        -- TOGGLE
        Group:AddToggle("ToggleAutoInsert", {
            Text = "Auto Insert",
            Default = vars.AutoInsert,
            Callback = function(v)
                vars.AutoInsert = v
                print("[Auto Insert] Toggle:", v and "ON" or "OFF")
            end
        })

        -- MODEL YANG DIIZINKAN
        local allowedModels = {
            "Handmill",
            "Preserves Barrel",
            "Small Food Trough",
            "Butter Churn",
            "Compost Bin",
            "Large Water Trough",
            "Small Water Trough"
        }

        -- DROPDOWN PILIH BLOCK
        task.spawn(function()
            task.wait(0.5)
            if Group.AddDropdown then
                local dropdown = Group:AddDropdown("DropdownInsertTarget", {
                    Text = "Pilih Block",
                    Values = allowedModels,
                    Default = vars.InsertTarget,
                    Multi = false,
                    Callback = function(v)
                        vars.InsertTarget = v
                        print("[Auto Insert] Target diubah ke:", v)
                    end
                })
                dropdown:SetValue(vars.InsertTarget)
            else
                warn("[Auto Insert] AddDropdown tidak tersedia di Group")
            end
        end)

        -- SLIDER DELAY
        Group:AddSlider("SliderInsertDelay", {
            Text = "Delay Insert",
            Default = vars.InsertDelay,
            Min = 0.3,
            Max = 3,
            Rounding = 1,
            Compact = false,
            Callback = function(v)
                vars.InsertDelay = v
            end
        })

        -- SERVICES
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Workspace = game:GetService("Workspace")

        local Relay = ReplicatedStorage:WaitForChild("Relay", 10)
        if not Relay then
            warn("[Auto Insert] Relay tidak ditemukan")
            return
        end

        local Blocks = Relay:WaitForChild("Blocks", 10)
        if not Blocks then
            warn("[Auto Insert] Relay.Blocks tidak ditemukan")
            return
        end

        local InsertItem = Blocks:WaitForChild("InsertItem", 10)
        if not InsertItem then
            warn("[Auto Insert] InsertItem tidak ditemukan")
            return
        end

        local LoadedBlocks = Workspace:WaitForChild("LoadedBlocks", 10)
        if not LoadedBlocks then
            warn("[Auto Insert] LoadedBlocks tidak ditemukan")
            return
        end

        -- =========================
        -- HELPERS
        -- =========================
        local function toVector3(voxel)
            if typeof(voxel) == "Vector3" then
                return Vector3.new(voxel.X, voxel.Y, voxel.Z)
            end
            return nil
        end

        local function toServerVector(voxel)
            if typeof(voxel) ~= "Vector3" then
                return nil
            end

            if vector and vector.create then
                return vector.create(voxel.X, voxel.Y, voxel.Z)
            end

            return Vector3.new(voxel.X, voxel.Y, voxel.Z)
        end

        local function posKey(v)
            return tostring(v.X) .. "," .. tostring(v.Y) .. "," .. tostring(v.Z)
        end

        -- =========================
        -- LIST POSITION KHUSUS BUTTER CHURN
        -- x = 4 sampai -16
        -- y = 7
        -- z = 48 sampai 63
        -- =========================
        local butterChurnPositions = {}

        for x = 4, -16, -1 do
            for z = 48, 63 do
                table.insert(butterChurnPositions, Vector3.new(x, 7, z))
            end
        end

        -- =========================
        -- BUILD MAP BLOCK BERDASARKAN VOXEL
        -- =========================
        local function getBlockMapByName(blockName)
            local map = {}

            for _, block in ipairs(LoadedBlocks:GetChildren()) do
                if block.Name == blockName then
                    local voxel = toVector3(block:GetAttribute("VoxelPosition"))
                    if voxel then
                        map[posKey(voxel)] = block
                    end
                end
            end

            return map
        end

        -- =========================
        -- INSERT KHUSUS BUTTER CHURN
        -- ikut urutan list position
        -- =========================
        local function InsertButterChurnByList()
            local churnMap = getBlockMapByName("Butter Churn")
            local foundAny = false

            for i, voxelPos in ipairs(butterChurnPositions) do
                if not vars.AutoInsert or vars.InsertTarget ~= "Butter Churn" then
                    return
                end

                local key = posKey(voxelPos)
                local block = churnMap[key]

                if block then
                    foundAny = true

                    local serverVec = toServerVector(voxelPos)
                    if serverVec then
                        local ok, err = pcall(function()
                            InsertItem:InvokeServer(serverVec)
                        end)

                        if ok then
                            print("[Auto Insert] Butter Churn insert | Index", i, "| Pos", voxelPos)
                        else
                            warn("[Auto Insert] Gagal insert Butter Churn | Pos", voxelPos, "|", err)
                        end
                    else
                        warn("[Auto Insert] Posisi Butter Churn invalid:", voxelPos)
                    end

                    task.wait(vars.InsertDelay)
                end
            end

            if not foundAny then
                warn("[Auto Insert] Tidak ada Butter Churn yang cocok dengan list position")
                task.wait(0.5)
            end
        end

        -- =========================
        -- INSERT NORMAL (selain Butter Churn)
        -- =========================
        local function InsertDefaultTarget()
            local foundAny = false

            for _, block in ipairs(LoadedBlocks:GetChildren()) do
                if not vars.AutoInsert then
                    return
                end

                if block.Name == vars.InsertTarget and table.find(allowedModels, block.Name) then
                    local voxel = toVector3(block:GetAttribute("VoxelPosition"))
                    if voxel then
                        foundAny = true

                        local serverVec = toServerVector(voxel)
                        if serverVec then
                            local ok, err = pcall(function()
                                InsertItem:InvokeServer(serverVec)
                            end)

                            if ok then
                                print("[Auto Insert] Berhasil insert ke:", block.Name, "| Pos:", voxel)
                            else
                                warn("[Auto Insert] Gagal insert ke:", block.Name, err)
                            end
                        end

                        task.wait(vars.InsertDelay)
                    end
                end
            end

            if not foundAny then
                warn("[Auto Insert] Target tidak ditemukan:", vars.InsertTarget)
                task.wait(0.5)
            end
        end

        -- =========================
        -- LOOP SYSTEM
        -- =========================
        if not vars._AutoInsertRun then
            vars._AutoInsertRun = true

            task.spawn(function()
                while true do
                    if vars.AutoInsert then
                        if vars.InsertTarget == "Butter Churn" then
                            InsertButterChurnByList()
                        else
                            InsertDefaultTarget()
                        end

                        task.wait(0.1)
                    else
                        task.wait(0.5)
                    end
                end
            end)
        end

        print("[Auto Insert] Sistem aktif. Target:", vars.InsertTarget)
    end
}