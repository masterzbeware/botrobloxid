-- AutoPlanter (faster, throttled)
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

        vars.AutoPlanter     = vars.AutoPlanter or false
        vars.PlanterDelay    = vars.PlanterDelay or 0.2 -- main loop sleep
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
            Min = 0.05,
            Max = 2,
            Rounding = 2,
            Callback = function(v) vars.PlanterDelay = v end
        })

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LoadedBlocks = workspace:WaitForChild("LoadedBlocks")
        local UsePlanterCart = ReplicatedStorage:WaitForChild("Relay"):WaitForChild("Blocks"):WaitForChild("UsePlanterCart")

        -- CONFIG: tweak untuk kecepatan vs safety
        local MAX_CONCURRENT = 6          -- berapa invoke paralel (jangan terlalu tinggi)
        local PER_INVOKE_DELAY = 0.03     -- delay singkat setelah spawn invoke (membatasi burst)
        local BACKOFF_SECONDS = 3        -- jika gagal, tunggu beberapa detik sebelum coba lagi di voxel yang sama

        local concurrent = 0
        local lastAttempt = {} -- key = "x/y/z" -> timestamp terakhir dicoba

        local function voxelKey(v)
            return tostring(v.X) .. "/" .. tostring(v.Y) .. "/" .. tostring(v.Z)
        end

        local function tryInvoke(voxel)
            -- spawn worker; concurrent tracked
            concurrent = concurrent + 1
            task.spawn(function()
                local k = voxelKey(voxel)
                local ok, res = pcall(function()
                    return UsePlanterCart:InvokeServer(vector.create(voxel.X, voxel.Y, voxel.Z))
                end)
                if not (ok and res == true) then
                    -- fallback Y+1
                    local ok2, res2 = pcall(function()
                        return UsePlanterCart:InvokeServer(vector.create(voxel.X, voxel.Y + 1, voxel.Z))
                    end)
                    if ok2 and res2 == true then
                        print(("[AutoPlanter] planted (fallback) %s"):format(k))
                        lastAttempt[k] = nil
                    else
                        -- gagal; catat waktu untuk backoff
                        lastAttempt[k] = tick()
                        -- print ringkas agar console tidak spam
                        -- (tampilkan res/res2 kalau mau debugging)
                        -- print(("[AutoPlanter] fail %s r1=%s r2=%s"):format(k, tostring(res), tostring(res2)))
                    end
                else
                    print(("[AutoPlanter] planted %s"):format(voxelKey(voxel)))
                    lastAttempt[k] = nil
                end
                task.wait(PER_INVOKE_DELAY)
                concurrent = concurrent - 1
            end)
        end

        coroutine.wrap(function()
            while true do
                if vars.AutoPlanter then
                    local children = LoadedBlocks:GetChildren()
                    for _, block in ipairs(children) do
                        if not vars.AutoPlanter then break end
                        if block and block.Name == "Farmland" and block.Parent then
                            local voxel = nil
                            if block.GetAttribute then
                                voxel = block:GetAttribute("VoxelPosition")
                            end
                            local state = nil
                            if block.GetAttribute then
                                state = block:GetAttribute("State")
                            end
                            if voxel and state == nil then
                                local k = voxelKey(voxel)
                                -- backoff check
                                if lastAttempt[k] and tick() - lastAttempt[k] < BACKOFF_SECONDS then
                                    -- skip for sekarang
                                else
                                    -- tunggu slot concurrent
                                    while concurrent >= MAX_CONCURRENT do
                                        task.wait(0.02)
                                        if not vars.AutoPlanter then break end
                                    end
                                    if not vars.AutoPlanter then break end
                                    tryInvoke(voxel)
                                end
                            end
                        end
                    end
                    -- jeda antara loop besar (tweakable)
                    task.wait(vars.PlanterDelay)
                else
                    repeat task.wait(0.5) until vars.AutoPlanter
                end
            end
        end)()

        print("[Auto Planter] Sistem aktif (faster mode)")
    end
}