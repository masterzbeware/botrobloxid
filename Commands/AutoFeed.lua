-- AutoFeed.lua (AUTO HAY FEED - FIXED REAL COUNT SYSTEM)

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
            Min = 0.2,
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
            if not hrp then return end

            hrp.CFrame = GetModelCFrame(model) + Vector3.new(0, 5, 0)
        end

        -- Hitung HayStack REAL (recount setiap kali)
        local function CountHayStack(model)
            local count = 0

            for _, obj in ipairs(model:GetDescendants()) do
                if obj:IsA("MeshPart") and obj.Name == "HayStack" then
                    -- hanya hitung yang benar-benar aktif
                    if obj.Parent and obj.Transparency < 1 then
                        count += 1
                    end
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

                    -- urutkan berdasarkan jarak terdekat
                    table.sort(targets, function(a, b)
                        local pa = GetModelCFrame(a).Position
                        local pb = GetModelCFrame(b).Position
                        return (pa - hrp.Position).Magnitude <
                               (pb - hrp.Position).Magnitude
                    end)

                    -- proses satu per satu trough
                    for _, trough in ipairs(targets) do

                        if not vars.AutoFeed then break end

                        local voxel = trough:GetAttribute("VoxelPosition")
                        if not voxel then continue end

                        -- hitung kondisi real sebelum isi
                        local hayCount = CountHayStack(trough)

                        -- jika sudah 9, skip ke trough berikutnya
                        if hayCount >= 9 then
                            continue
                        end

                        -- teleport jika aktif
                        TeleportToModel(trough)
                        task.wait(0.3)

                        -- isi sampai benar-benar 9 (real count)
                        while vars.AutoFeed do

                            hayCount = CountHayStack(trough)

                            if hayCount >= 9 then
                                break
                            end

                            pcall(function()
                                InsertItem:InvokeServer(
                                    vector.create(
                                        voxel.X,
                                        voxel.Y,
                                        voxel.Z
                                    )
                                )
                            end)

                            task.wait(vars.FeedDelay)
                        end
                    end
                end

                task.wait(0.5)
            end
        end)

        print("[AutoFeed] Loaded - Real Count System Active")
    end
}