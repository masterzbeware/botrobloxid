-- AutoInsert.lua
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local MainTab = tab or Tabs.Main
        if not MainTab then
            warn("[Auto Insert] Tab tidak ditemukan!")
            return
        end

        -- =========================
        -- UI
        -- =========================
        local Group = MainTab:AddLeftGroupbox("Auto Insert Items")

        vars.AutoInsert = vars.AutoInsert or false
        vars.AutoTeleport = vars.AutoTeleport or false
        vars.InsertDelay = vars.InsertDelay or 1
        vars.InsertTarget = vars.InsertTarget or "Small Water Trough"
        _G.BotVars = vars

        Group:AddToggle("AutoInsertToggle", {
            Text = "Auto Insert",
            Default = vars.AutoInsert,
            Callback = function(v)
                vars.AutoInsert = v
            end
        })

        Group:AddToggle("AutoTeleportToggle", {
            Text = "Auto Teleport",
            Default = vars.AutoTeleport,
            Callback = function(v)
                vars.AutoTeleport = v
            end
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
            task.wait(0.5)
            local dropdown = Group:AddDropdown("InsertTarget", {
                Text = "Target Block",
                Values = allowedModels,
                Default = vars.InsertTarget,
                Multi = false,
                Callback = function(v)
                    vars.InsertTarget = v
                end
            })
            dropdown:SetValue(vars.InsertTarget)
        end)

        Group:AddSlider("InsertDelay", {
            Text = "Delay",
            Default = vars.InsertDelay,
            Min = 0.3,
            Max = 3,
            Rounding = 1,
            Callback = function(v)
                vars.InsertDelay = v
            end
        })

        -- =========================
        -- SERVICES
        -- =========================
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local player = Players.LocalPlayer
        local InsertItem = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Blocks")
            :WaitForChild("InsertItem")

        -- =========================
        -- HELPERS
        -- =========================
        local function HasWater(model)
            for _, v in ipairs(model:GetChildren()) do
                if v:IsA("MeshPart") and v.Name == "Water" then
                    return true
                end
            end
            return false
        end

        local function HasCanCollideFalse(model)
            for _, v in ipairs(model:GetChildren()) do
                if v.Name == "CanCollideFalse" then
                    return true
                end
            end
            return false
        end

        local function GetTeleportPosition(model)
            for _, obj in ipairs(model:GetDescendants()) do
                if obj:IsA("BasePart") then
                    return obj.Position
                end
            end
            return nil
        end

        local function TeleportToModel(model)
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local pos = GetTeleportPosition(model)
            if pos then
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
            end
        end

        -- =========================
        -- MAIN LOOP
        -- =========================
        coroutine.wrap(function()
            while true do
                if vars.AutoInsert then
                    local LoadedBlocks = workspace:FindFirstChild("LoadedBlocks")
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")

                    if LoadedBlocks and hrp then
                        local targets = {}

                        -- ambil semua block target
                        for _, block in ipairs(LoadedBlocks:GetChildren()) do
                            if block.Name == vars.InsertTarget then
                                table.insert(targets, block)
                            end
                        end

                        -- urutkan dari yang TERDEKAT
                        table.sort(targets, function(a, b)
                            local pa = GetTeleportPosition(a)
                            local pb = GetTeleportPosition(b)
                            if not pa or not pb then return false end
                            return (pa - hrp.Position).Magnitude < (pb - hrp.Position).Magnitude
                        end)

                        -- proses satu per satu
                        for _, block in ipairs(targets) do
                            if block.Name == "Small Water Trough" and HasWater(block) then
                                continue
                            end

                            if block.Name == "Butter Churn" and HasCanCollideFalse(block) then
                                continue
                            end

                            if vars.AutoTeleport then
                                TeleportToModel(block)
                                task.wait(0.35)
                            end

                            local voxel = block:GetAttribute("VoxelPosition")
                            if voxel then
                                pcall(function()
                                    InsertItem:InvokeServer(
                                        vector.create(voxel.X, voxel.Y, voxel.Z)
                                    )
                                end)
                            end

                            task.wait(vars.InsertDelay)
                        end
                    end
                end
                task.wait(0.5)
            end
        end)()

        print("[Auto Insert] FULL FIX AKTIF")
    end
}
