-- AutoCraft.lua
return {
    Execute = function(tab)

        -- =========================
        -- GLOBAL VARS
        -- =========================
        local vars = _G.BotVars or {}
        vars.AutoCraft        = vars.AutoCraft or false
        vars.AutoHarvestBaker = vars.AutoHarvestBaker or false
        vars.CraftDelay       = vars.CraftDelay or 1.5
        vars.SelectedItem     = vars.SelectedItem or "Chocolate Bar"
        vars._AutoCraftRun    = vars._AutoCraftRun or false
        _G.BotVars = vars

        -- =========================
        -- SERVICES
        -- =========================
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        local LocalPlayer = Players.LocalPlayer

        local CraftRemote = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Inventory")
            :WaitForChild("CraftItem")

        local HarvestRemote = ReplicatedStorage
            :WaitForChild("Relay")
            :WaitForChild("Blocks")
            :WaitForChild("HarvestCrop")

        -- =========================
        -- TAB & UI
        -- =========================
        local Tabs = vars.Tabs or {}
        local CraftTab = tab or Tabs.Craft

        if not CraftTab then
            warn("[AutoCraft] Tab Craft tidak ditemukan")
            return
        end

        local Group = (CraftTab.AddRightGroupbox and CraftTab:AddRightGroupbox("Auto Craft"))
            or CraftTab:AddLeftGroupbox("Auto Craft")

        -- =========================
        -- TOGGLES
        -- =========================
        Group:AddToggle("ToggleAutoCraft", {
            Text = "Auto Craft (Sequential)",
            Default = vars.AutoCraft,
            Callback = function(v)
                vars.AutoCraft = v
                print("[AutoCraft] Toggle:", v and "ON" or "OFF")
            end
        })

        Group:AddToggle("ToggleAutoHarvestBaker", {
            Text = "Auto Harvest Baker",
            Default = vars.AutoHarvestBaker,
            Callback = function(v)
                vars.AutoHarvestBaker = v
            end
        })

        -- =========================
        -- DROPDOWN ITEM
        -- =========================
        Group:AddDropdown("DropdownCraftItem", {
            Text = "Pilih Item Craft",
            Values = {"Chocolate Bar"},
            Default = vars.SelectedItem,
            Multi = false,
            Callback = function(v)
                vars.SelectedItem = v
            end
        })

        -- =========================
        -- SLIDER DELAY
        -- =========================
        Group:AddSlider("SliderCraftDelay", {
            Text = "Delay Craft",
            Min = 0.3,
            Max = 3,
            Default = vars.CraftDelay,
            Rounding = 1,
            Callback = function(v)
                vars.CraftDelay = v
            end
        })

        -- =========================
        -- TELEPORT FUNCTION
        -- =========================
        local function TeleportToOven(oven)
            local char = LocalPlayer.Character
            if not char then return end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            local root = oven:FindFirstChild("Root")

            if hrp and root then
                hrp.CFrame = root.CFrame + Vector3.new(0, 3, 0)
            end
        end

        -- =========================
        -- HIGHLIGHT SYSTEM
        -- =========================
        local currentHighlight

        local function HighlightOven(oven)
            if currentHighlight then
                currentHighlight:Destroy()
                currentHighlight = nil
            end

            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255, 170, 0)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.Parent = oven

            currentHighlight = hl
        end

        local function RemoveHighlight()
            if currentHighlight then
                currentHighlight:Destroy()
                currentHighlight = nil
            end
        end

        -- =========================
        -- SEQUENTIAL CRAFT SYSTEM
        -- =========================
        local function SequentialCraft()
            for _, oven in ipairs(LoadedBlocks:GetDescendants()) do
                if not vars.AutoCraft then break end
                if oven.Name == "Baker's Oven" then

                    local voxel = oven:GetAttribute("VoxelPosition")
                    if not voxel and oven.Parent then
                        voxel = oven.Parent:GetAttribute("VoxelPosition")
                    end

                    if voxel then

                        -- TELEPORT
                        TeleportToOven(oven)
                        task.wait(0.5)

                        -- HIGHLIGHT
                        HighlightOven(oven)

                        -- CRAFT
                        pcall(function()
                            CraftRemote:InvokeServer(
                                "Baker's Oven",
                                vars.SelectedItem,
                                voxel
                            )
                        end)

                        print("[Sequential] Craft:", voxel)

                        -- TUNGGU SAMPAI SELESAI
                        repeat
                            task.wait(1)
                        until not oven:FindFirstChild("baked", true) or not vars.AutoCraft

                        -- HARVEST
                        if vars.AutoHarvestBaker and vars.AutoCraft then
                            pcall(function()
                                HarvestRemote:InvokeServer(
                                    vector.create(voxel.X, voxel.Y, voxel.Z)
                                )
                            end)
                            print("[Sequential] Harvest:", voxel)
                        end

                        task.wait(vars.CraftDelay)

                        -- HAPUS HIGHLIGHT SEBELUM PINDAH
                        RemoveHighlight()
                    end
                end
            end
        end

        -- =========================
        -- MAIN LOOP
        -- =========================
        if vars._AutoCraftRun then
            return
        end

        vars._AutoCraftRun = true

        task.spawn(function()
            while true do
                if vars.AutoCraft then
                    SequentialCraft()
                else
                    RemoveHighlight()
                    task.wait(0.5)
                end
                task.wait(0.2)
            end
        end)

        print("[AutoCraft] Sequential System Loaded")
    end
}