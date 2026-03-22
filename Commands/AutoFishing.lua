-- AutoFishing.lua
return {
    Execute = function(tab)

        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}

        local FishingTab = tab or Tabs.Inventory
        if not FishingTab then
            warn("[Auto Fishing] Tab tidak ditemukan!")
            return
        end

        local Group = FishingTab:AddLeftGroupbox("Auto Fishing")

        vars.AutoFishing = vars.AutoFishing or false
        vars.FishingDelay = vars.FishingDelay or 3

        _G.BotVars = vars

        -- Toggle
        Group:AddToggle("ToggleAutoFishing", {
            Text = "Enable Auto Fishing",
            Default = vars.AutoFishing,
            Callback = function(v)
                vars.AutoFishing = v
            end
        })

        -- Delay Slider
        Group:AddSlider("SliderFishingDelay", {
            Text = "Fishing Delay",
            Default = vars.FishingDelay,
            Min = 1,
            Max = 10,
            Rounding = 1,
            Callback = function(v)
                vars.FishingDelay = v
            end
        })

        -- Services
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")

        local CastRemote = ReplicatedStorage:WaitForChild("Relay")
            :WaitForChild("Server")
            :WaitForChild("CastBobber")

        local LocalPlayer = Players.LocalPlayer

        -- Helper: cari fish (lebih aman)
        local function getFish()
            for _, v in pairs(workspace:GetChildren()) do
                if v.Name == "Fish" then
                    return v
                end
            end
        end

        -- Helper: cek character ready
        local function isReady()
            local char = LocalPlayer.Character
            return char and char:FindFirstChild("HumanoidRootPart")
        end

        -- Fishing Loop
        task.spawn(function()
            while true do
                task.wait(0.1)

                if not vars.AutoFishing then
                    task.wait(0.5)
                    continue
                end

                if not isReady() then
                    task.wait(1)
                    continue
                end

                local fish = getFish()

                if fish then
                    -- 🎯 CAST
                    pcall(function()
                        CastRemote:InvokeServer(false, nil, true, fish)
                    end)

                    task.wait(1.5)

                    -- 🎣 REEL SPAM (biar ga miss)
                    for i = 1, 5 do
                        pcall(function()
                            CastRemote:InvokeServer(true)
                        end)
                        task.wait(0.3)
                    end

                    task.wait(vars.FishingDelay)
                else
                    -- jangan spam warn
                    task.wait(0.5)
                end
            end
        end)

        print("[Auto Fishing] Loaded (Improved)")
    end
}