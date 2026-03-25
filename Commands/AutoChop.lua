-- AutoChop.lua
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}

        -- gunakan tab yang dikirim, atau fallback ke tab Harvest
        local ChopTab = tab or Tabs.Harvest

        if not ChopTab then
            warn("[Auto Chop] Tab tidak ditemukan!")
            return
        end

        -- UI GROUP
        local Group
        if ChopTab.AddRightGroupbox then
            Group = ChopTab:AddRightGroupbox("Auto Chop")
        else
            warn("[Auto Chop] AddRightGroupbox tidak tersedia, menggunakan AddLeftGroupbox")
            Group = ChopTab:AddLeftGroupbox("Auto Chop")
        end

        -- DEFAULT VARS
        vars.AutoChop = vars.AutoChop or false
        vars.ChopTarget = vars.ChopTarget or "Fir Tree"
        _G.BotVars = vars

        -- TOGGLE ON/OFF
        Group:AddToggle("ToggleAutoChop", {
            Text = "Auto Chop",
            Default = vars.AutoChop,
            Callback = function(v)
                vars.AutoChop = v
                print("[Auto Chop] Toggle:", v and "ON" or "OFF")
            end
        })

        -- DROPDOWN (cuma 1 pilihan)
        task.spawn(function()
            task.wait(0.3)
            if Group.AddDropdown then
                local dropdown = Group:AddDropdown("DropdownChopTarget", {
                    Text = "Select Tree",
                    Values = { "Fir Tree" },
                    Default = vars.ChopTarget,
                    Multi = false,
                    Callback = function(v)
                        vars.ChopTarget = v
                        print("[Auto Chop] Target diubah ke:", v)
                    end
                })
                dropdown:SetValue(vars.ChopTarget)
            else
                warn("[Auto Chop] AddDropdown tidak tersedia di Group")
            end
        end)

        -- SERVICES
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Blocks = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks")
        local ChopTree = Blocks:WaitForChild("ChopTree")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")

        -- LOOP AUTO CHOP
        coroutine.wrap(function()
            while true do
                if vars.AutoChop then
                    for _, block in ipairs(LoadedBlocks:GetChildren()) do
                        if block.Name == vars.ChopTarget then
                            local voxel = block:GetAttribute("VoxelPosition")
                            if voxel then
                                local success, err = pcall(function()
                                    ChopTree:InvokeServer(vector.create(voxel.X, voxel.Y, voxel.Z))
                                end)

                                if not success then
                                    warn("[Auto Chop] Gagal chop", block.Name, err)
                                else
                                    print("[Auto Chop] Chop:", block.Name, voxel.X, voxel.Y, voxel.Z)
                                end

                                task.wait(0.1)
                            end
                        end
                    end
                    task.wait(0.5)
                else
                    repeat task.wait(0.5) until vars.AutoChop
                end
            end
        end)()

        print("[Auto Chop] Sistem aktif. Target:", vars.ChopTarget)
    end
}