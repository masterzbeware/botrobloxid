-- AutoInsert.lua (REFILL PER TROUGH - NO ERROR)
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main
        if not MainTab then return end

        -- =========================
        -- UI
        -- =========================
        local Group = MainTab:AddLeftGroupbox("Auto Insert Items")

        vars.AutoInsert   = vars.AutoInsert or false
        vars.AutoTeleport = vars.AutoTeleport or false
        vars.InsertDelay  = vars.InsertDelay or 0.3
        vars.InsertTarget = vars.InsertTarget or "Small Water Trough"
        _G.BotVars = vars

        Group:AddToggle("AutoInsertToggle", {
            Text = "Auto Insert",
            Default = vars.AutoInsert,
            Callback = function(v) vars.AutoInsert = v end
        })

        Group:AddToggle("AutoTeleportToggle", {
            Text = "Auto Teleport",
            Default = vars.AutoTeleport,
            Callback = function(v) vars.AutoTeleport = v end
        })

        local allowedModels = {
            "Handmill",
            "Preserves Barrel",
            "Small Food Trough",
            "Butter Churn",
            "Compost Bin",
            "Large Water Trough",
            "Small Water Trough"
        }

        task.spawn(function()
            task.wait(0.4)
            local dd = Group:AddDropdown("InsertTarget", {
                Text = "Target Block",
                Values = allowedModels,
                Default = vars.InsertTarget,
                Multi = false,
                Callback = function(v)
                    vars.InsertTarget = v
                end
            })
            dd:SetValue(vars.InsertTarget)
        end)

        Group:AddSlider("InsertDelay", {
            Text = "Delay",
            Min = 0.3,
            Max = 3,
            Default = vars.InsertDelay,
            Callback = function(v) vars.InsertDelay = v end
        })

        -- =========================
        -- SERVICES
        -- =========================
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local player = Players.LocalPlayer
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local InsertItem = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Blocks")
            :WaitForChild("InsertItem")

        local FillBucket = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Inventory")
            :WaitForChild("FillBucket")

        -- =========================
        -- HELPERS
        -- =========================
        local WellList = {
            ["Brick Well"] = true,
            ["Stone Well"] = true
        }

        local function HasWater(model)
            for _, v in ipairs(model:GetChildren()) do
                if v:IsA("MeshPart") and v.Name == "Water" then
                    return true
                end
            end
            return false
        end

        local function GetPartPos(model)
            for _, obj in ipairs(model:GetDescendants()) do
                if obj:IsA("BasePart") then
                    return obj.Position
                end
            end
        end

        local function Teleport(pos)
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and pos then
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
            end
        end

        local function GetNearestWell()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return nil end

            local nearest, dist
            for _, block in ipairs(LoadedBlocks:GetChildren()) do
                if WellList[block.Name] then
                    local pos = GetPartPos(block)
                    if pos then
                        local d = (pos - hrp.Position).Magnitude
                        if not dist or d < dist then
                            dist = d
                            nearest = block
                        end
                    end
                end
            end
            return nearest
        end

        -- =========================
        -- MAIN LOOP
        -- =========================
        task.spawn(function()
            while true do
                if vars.AutoInsert then
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then
                        task.wait(0.5)
                        continue
                    end

                    -- ambil target
                    local targets = {}
                    for _, block in ipairs(LoadedBlocks:GetChildren()) do
                        if block.Name == vars.InsertTarget then
                            table.insert(targets, block)
                        end
                    end

                    table.sort(targets, function(a, b)
                        local pa = GetPartPos(a)
                        local pb = GetPartPos(b)
                        if not pa or not pb then return false end
                        return (pa - hrp.Position).Magnitude <
                               (pb - hrp.Position).Magnitude
                    end)

                    for _, block in ipairs(targets) do
                        if block.Name == "Small Water Trough" and HasWater(block) then
                            continue
                        end

                        -- 🔹 REFILL PER TROUGH
                        if vars.InsertTarget == "Small Water Trough" then
                            local well = GetNearestWell()
                            if well then
                                Teleport(GetPartPos(well))
                                task.wait(0.35)

                                local voxelWell = well:GetAttribute("VoxelPosition")
                                if voxelWell then
                                    pcall(function()
                                        FillBucket:InvokeServer(
                                            vector.create(
                                                voxelWell.X,
                                                voxelWell.Y,
                                                voxelWell.Z
                                            )
                                        )
                                    end)
                                    task.wait(0.25)
                                end
                            end
                        end

                        -- teleport ke trough
                        if vars.AutoTeleport then
                            Teleport(GetPartPos(block))
                            task.wait(0.35)
                        end

                        -- insert
                        local voxel = block:GetAttribute("VoxelPosition")
                        if voxel then
                            pcall(function()
                                InsertItem:InvokeServer(
                                    vector.create(
                                        voxel.X,
                                        voxel.Y,
                                        voxel.Z
                                    )
                                )
                            end)
                        end

                        task.wait(vars.InsertDelay)
                    end
                end
                task.wait(0.5)
            end
        end)

        print("[AutoInsert] REFILL PER TROUGH - NO ERROR")
    end
}
