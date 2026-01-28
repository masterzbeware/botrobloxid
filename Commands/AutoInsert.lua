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
        -- UI GROUP
        -- =========================
        local Group = MainTab:AddLeftGroupbox("Auto Insert Items")

        -- =========================
        -- DEFAULT VARS
        -- =========================
        vars.AutoInsert = vars.AutoInsert or false
        vars.InsertDelay = vars.InsertDelay or 1
        vars.InsertTarget = vars.InsertTarget or "Compost Bin"
        vars.AutoTeleport = vars.AutoTeleport or false
        _G.BotVars = vars

        -- =========================
        -- TOGGLE AUTO INSERT
        -- =========================
        Group:AddToggle("ToggleAutoInsert", {
            Text = "Auto Insert",
            Default = vars.AutoInsert,
            Callback = function(v)
                vars.AutoInsert = v
            end
        })

        -- =========================
        -- TOGGLE AUTO TELEPORT
        -- =========================
        Group:AddToggle("ToggleAutoTeleport", {
            Text = "Auto Teleport",
            Default = vars.AutoTeleport,
            Callback = function(v)
                vars.AutoTeleport = v
            end
        })

        -- =========================
        -- MODEL YANG DIIZINKAN
        -- =========================
        local allowedModels = {
            "Butter Churn",
            "Compost Bin",
            "Large Water Trough",
            "Small Water Trough"
        }

        -- =========================
        -- DROPDOWN
        -- =========================
        task.spawn(function()
            task.wait(0.5)
            local dropdown = Group:AddDropdown("DropdownInsertTarget", {
                Text = "Pilih Block",
                Values = allowedModels,
                Default = vars.InsertTarget,
                Multi = false,
                Callback = function(v)
                    vars.InsertTarget = v
                end
            })
            dropdown:SetValue(vars.InsertTarget)
        end)

        -- =========================
        -- SLIDER DELAY
        -- =========================
        Group:AddSlider("SliderInsertDelay", {
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
        local Blocks = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks")
        local InsertItem = Blocks:WaitForChild("InsertItem")

        -- =========================
        -- HELPER
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

        local function TeleportTo(position)
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(position + Vector3.new(0, 4, 0))
            end
        end

        -- =========================
        -- LOOP SYSTEM
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
                                local voxel = block:GetAttribute("VoxelPosition")
                                if voxel then
                                    table.insert(targets, {
                                        block = block,
                                        pos = Vector3.new(voxel.X, voxel.Y, voxel.Z)
                                    })
                                end
                            end
                        end

                        -- urutkan dari yang TERDEKAT
                        table.sort(targets, function(a, b)
                            return (a.pos - hrp.Position).Magnitude < (b.pos - hrp.Position).Magnitude
                        end)

                        -- proses satu per satu
                        for _, data in ipairs(targets) do
                            local block = data.block

                            if block.Name == "Small Water Trough" and HasWater(block) then
                                continue
                            end

                            if block.Name == "Butter Churn" and HasCanCollideFalse(block) then
                                continue
                            end

                            if vars.AutoTeleport then
                                TeleportTo(data.pos)
                                task.wait(0.25)
                            end

                            pcall(function()
                                InsertItem:InvokeServer(data.pos)
                            end)

                            task.wait(vars.InsertDelay)
                        end
                    end
                end
                task.wait(0.5)
            end
        end)()

        print("[Auto Insert] + Auto Teleport Aktif")
    end
}
