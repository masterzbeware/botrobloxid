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
        local CastRemote = ReplicatedStorage:WaitForChild("Relay")
            :WaitForChild("Server")
            :WaitForChild("CastBobber")

        -- Helper: ambil fish
        local function getFish()
            return workspace:FindFirstChild("Fish")
        end

        -- Fishing Loop
        task.spawn(function()
            while true do

                if vars.AutoFishing then

                    local fish = getFish()

                    if fish then
                        -- CAST (pakai args dari remotespy)
                        pcall(function()
                            CastRemote:InvokeServer(false, nil, true, fish)
                        end)

                        task.wait(2)

                        -- REEL / CATCH
                        pcall(function()
                            CastRemote:InvokeServer(true)
                        end)
                    else
                        warn("[Auto Fishing] Fish tidak ditemukan")
                    end

                    task.wait(vars.FishingDelay)

                else
                    task.wait(0.5)
                end

            end
        end)

        print("[Auto Fishing] Loaded")
    end
}