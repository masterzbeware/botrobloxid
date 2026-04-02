-- AutoPlanter (no distance check — will attempt for any Farmland in LoadedBlocks)
return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}

        local PlantTab = tab or Tabs.Plant
        if not PlantTab then
            warn("[Auto Planter] Tab Plant tidak ditemukan!")
            return
        end

        local Group = PlantTab:AddLeftGroupbox("Auto Planter")

        vars.AutoPlanter  = vars.AutoPlanter or false
        vars.PlanterDelay = vars.PlanterDelay or 0.2
        _G.BotVars = vars

        Group:AddToggle("ToggleAutoPlanter", {
            Text = "Auto Planter",
            Default = vars.AutoPlanter,
            Callback = function(v)
                vars.AutoPlanter = v
                print("[Auto Planter]", v and "ON" or "OFF")
            end
        })

        Group:AddSlider("SliderPlanterDelay", {
            Text = "Delay Tanam",
            Default = vars.PlanterDelay,
            Min = 0.02,
            Max = 2,
            Rounding = 2,
            Callback = function(v) vars.PlanterDelay = v end
        })

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
        local UsePlanterCart = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks"):WaitForChild("UsePlanterCart")

        -- Config (ubah sesuai kebutuhan)
        local MAX_CONCURRENT = 6       -- berapa Invoke paralel (naikkan jika server aman)
        local PER_INVOKE_DELAY = 0.03  -- jeda kecil setelah tiap invoke selesai
        local BACKOFF_SECONDS = 3      -- jika gagal, tunggu beberapa detik sebelum coba lagi

        local concurrent = 0
        local lastAttempt = {}        -- key -> timestamp (backoff)
        local farmlands = {}          -- tabel: part -> voxel

        local function keyFromVoxel(v)
            return tostring(v.X).."/"..tostring(v.Y).."/"..tostring(v.Z)
        end

        -- maintain list agar tidak harus iterasi GetChildren tiap kali
        local function addFarmland(part)
            if not part or not part.GetAttribute then return end
            if part.Name ~= "Farmland" then return end
            local v = nil
            pcall(function() v = part:GetAttribute("VoxelPosition") end)
            if v then
                farmlands[part] = v
            end
        end
        local function removeFarmland(part)
            farmlands[part] = nil
        end

        for _, c in ipairs(LoadedBlocks:GetChildren()) do addFarmland(c) end
        LoadedBlocks.ChildAdded:Connect(addFarmland)
        LoadedBlocks.ChildRemoved:Connect(removeFarmland)

        local function safeInvokeTry(voxel)
            concurrent = concurrent + 1
            task.spawn(function()
                local k = keyFromVoxel(voxel)
                local ok, res = pcall(function()
                    return UsePlanterCart:InvokeServer(vector.create(voxel.X, voxel.Y, voxel.Z))
                end)
                if ok and res == true then
                    print("[AutoPlanter] planted "..k)
                    lastAttempt[k] = nil
                    concurrent = concurrent - 1
                    return
                end

                -- fallback Y+1 (beberapa server mengharapkan Y+1)
                local ok2, res2 = pcall(function()
                    return UsePlanterCart:InvokeServer(vector.create(voxel.X, voxel.Y + 1, voxel.Z))
                end)
                if ok2 and res2 == true then
                    print("[AutoPlanter] planted (fallback) "..k)
                    lastAttempt[k] = nil
                else
                    lastAttempt[k] = tick() -- catat waktu gagal untuk backoff
                end

                task.wait(PER_INVOKE_DELAY)
                concurrent = concurrent - 1
            end)
        end

        coroutine.wrap(function()
            while true do
                if vars.AutoPlanter then
                    -- iterate ALL farmlands (tidak ada filter jarak)
                    for part, voxel in pairs(farmlands) do
                        if not vars.AutoPlanter then break end
                        if not part or not part.Parent then
                            farmlands[part] = nil
                        else
                            local k = keyFromVoxel(voxel)
                            if not lastAttempt[k] or tick() - lastAttempt[k] >= BACKOFF_SECONDS then
                                -- throttle concurrent invokes
                                while concurrent >= MAX_CONCURRENT do
                                    task.wait(0.02)
                                    if not vars.AutoPlanter then break end
                                end
                                if not vars.AutoPlanter then break end
                                safeInvokeTry(voxel)
                            end
                        end
                    end

                    task.wait(vars.PlanterDelay)
                else
                    repeat task.wait(0.5) until vars.AutoPlanter
                end
            end
        end)()

        print("[Auto Planter] Sistem aktif (no distance check)")
    end
}