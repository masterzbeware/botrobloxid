-- AutoFeed.lua (AUTO HAY FEED - 9 HAYSTACK PER TROUGH)

return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}

        -- gunakan tab Animals
        local AnimalsTab = tab or Tabs.Animals
        if not AnimalsTab then
            warn("[AutoFeed] Tab Animals tidak ditemukan!")
            return
        end

        -- =========================
        -- UI
        -- =========================
        local Group = AnimalsTab:AddLeftGroupbox("Auto Feed")

        vars.AutoFeed     = vars.AutoFeed or false
        vars.AutoTeleport = vars.AutoTeleport or false
        vars.FeedDelay    = vars.FeedDelay or 0.4
        _G.BotVars = vars

        Group:AddToggle("AutoFeedToggle", {
            Text = "Auto Feed",
            Default = vars.AutoFeed,
            Callback = function(v)
                vars.AutoFeed = v
                print("[AutoFeed]", v and "ON" or "OFF")
            end
        })

        Group:AddToggle("AutoTeleportToggleFeed", {
            Text = "Auto Teleport",
            Default = vars.AutoTeleport,
            Callback = function(v)
                vars.AutoTeleport = v
            end
        })

        Group:AddSlider("FeedDelay", {
            Text = "Delay",
            Min = 0.3,
            Max = 3,
            Default = vars.FeedDelay,
            Callback = function(v)
                vars.FeedDelay = v
            end
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

        -- =========================
        -- HELPERS
        -- =========================
        local function GetModelCFrame(model)
            if model.PrimaryPart then
                return model.PrimaryPart.CFrame
            end
            return model:GetPivot()
        end

        local function TeleportToModel(model)
            if not vars.AutoTeleport then return end
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp or not model then return end

            hrp.CFrame = GetModelCFrame(model) + Vector3.new(0, 5, 0)
        end

        local function CountHayStack(model)
            local count = 0
            for _, obj in ipairs(model:GetDescendants()) do
                if obj:IsA("MeshPart") and obj.Name == "HayStack" then
                    count += 1
                end
            end
            return count
        end

        -- =========================
        -- MAIN LOOP
        -- =========================
        task.spawn(function()
            while true do
                if vars.AutoFeed then
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then
                        task.wait(0.5)
                        continue
                    end

                    local targets = {}

                    -- ambil semua Small Food Trough
                    for _, block in ipairs(LoadedBlocks:GetChildren()) do
                        if block.Name == "Small Food Trough" then
                            table.insert(targets, block)
                        end
                    end

                    -- urutkan berdasarkan jarak
                    table.sort(targets, function(a, b)
                        local pa = GetModelCFrame(a).Position
                        local pb = GetModelCFrame(b).Position
                        return (pa - hrp.Position).Magnitude <
                               (pb - hrp.Position).Magnitude
                    end)

                    for _, trough in ipairs(targets) do
                        local hayCount = CountHayStack(trough)

                        -- jika sudah 9 haystack, skip
                        if hayCount >= 9 then
                            continue
                        end

                        -- teleport ke trough
                        TeleportToModel(trough)
                        task.wait(0.4)

                        local voxel = trough:GetAttribute("VoxelPosition")
                        if voxel then
                            -- isi sampai 9
                            while hayCount < 9 and vars.AutoFeed do
                                pcall(function()
                                    InsertItem:InvokeServer(
                                        vector.create(
                                            voxel.X,
                                            voxel.Y,
                                            voxel.Z
                                        )
                                    )
                                end)

                                hayCount += 1
                                task.wait(vars.FeedDelay)
                            end
                        end
                    end
                end

                task.wait(0.5)
            end
        end)

        print("[AutoFeed] Loaded - 9 HayStack System Active")
    end
}