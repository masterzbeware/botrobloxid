return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local CombatTab = tab or Tabs.Combat

        if not CombatTab then
            warn("[Auto Job] Tab Combat tidak ditemukan!")
            return
        end

        local Group = CombatTab:AddRightGroupbox("Auto Job")

        vars.AutoJob = vars.AutoJob or false
        vars.SelectedJob = vars.SelectedJob or "BloxBurgersEmployee"

        -- Load JobData module untuk mendapatkan data job yang benar
        local success, JobData = pcall(function()
            return require(game:GetService("ReplicatedStorage").Modules._Data.JobData)
        end)

        if not success or not JobData then
            warn("❌ Gagal memuat module JobData")
            return
        end

        -- Daftar job yang tersedia dengan info dari JobData module
        local jobData = {}
        local jobList = {}

        for jobName, jobInfo in pairs(JobData.Data) do
            jobData[jobName] = {
                Name = jobName,
                Title = jobInfo.Title,
                Location = jobInfo.Location,
                ID = jobInfo.ID,
                IsLegacy = jobInfo.IsLegacy or false,
                TeleportCFrame = GetJobTeleportLocation(jobInfo.Location)
            }
            table.insert(jobList, jobName)
        end

        -- Tambahkan TotalJob jika ada
        if JobData.TotalJobData then
            jobData["TotalJob"] = {
                Name = "TotalJob",
                Title = JobData.TotalJobData.Title,
                Location = "All Jobs",
                ID = 0,
                IsLegacy = false,
                TeleportCFrame = CFrame.new(0, 10, 0)
            }
            table.insert(jobList, "TotalJob")
        end

        -- Fungsi untuk mendapatkan lokasi teleport berdasarkan location name
        function GetJobTeleportLocation(locationName)
            -- Koordinat default untuk setiap lokasi (sesuaikan dengan game sebenarnya)
            local locationCoordinates = {
                ["Blox Burgers"] = CFrame.new(-100, 5, -50),
                ["Stylez Hair Studio"] = CFrame.new(-150, 5, 30),
                ["Mike's Motors"] = CFrame.new(80, 5, -120),
                ["Pizza Planet"] = CFrame.new(200, 5, 80),
                ["The Fishing Hut"] = CFrame.new(-80, 5, 150),
                ["Ben's Ice Cream"] = CFrame.new(120, 5, -80),
                ["Bloxburg Fresh Food"] = CFrame.new(-60, 5, -30),
                ["Lovely Lumber"] = CFrame.new(150, 5, -150),
                ["HighSchool"] = CFrame.new(0, 5, 100),
                ["High School"] = CFrame.new(10, 5, 110),
                ["The Bloxburg Cave"] = CFrame.new(-200, 5, -200)
            }
            
            return locationCoordinates[locationName] or CFrame.new(0, 10, 0)
        end

        -- Dropdown untuk memilih job
        Group:AddDropdown("JobSelector", {
            Text = "Pilih Job",
            Default = vars.SelectedJob,
            Values = jobList,
            Callback = function(value)
                vars.SelectedJob = value
                local jobInfo = jobData[value]
                if jobInfo then
                    print("✅ Job dipilih: " .. jobInfo.Title .. " di " .. jobInfo.Location)
                    
                    -- Jika auto job sedang aktif, restart dengan job baru
                    if vars.AutoJob then
                        vars.AutoJob = false
                        wait(1)
                        vars.AutoJob = true
                        StartAutoJob(value)
                    end
                end
            end
        })

        -- Toggle untuk auto job
        Group:AddToggle("ToggleAutoJob", {
            Text = "Auto Job",
            Default = vars.AutoJob,
            Callback = function(v)
                vars.AutoJob = v
                if v then
                    -- Aktifkan auto job
                    coroutine.wrap(function()
                        StartAutoJob(vars.SelectedJob)
                    end)()
                else
                    -- Matikan auto job
                    print("❌ Auto Job dimatikan")
                    if getgenv().AutoJobConnection then
                        getgenv().AutoJobConnection:Disconnect()
                        getgenv().AutoJobConnection = nil
                    end
                end
            end
        })

        -- Button untuk teleport manual
        Group:AddButton("Teleport ke Job", function()
            TeleportToJob(vars.SelectedJob)
        end)

        -- Fungsi untuk teleportasi ke lokasi job
        function TeleportToJob(jobName)
            local job = jobData[jobName]
            if not job then 
                print("❌ Job tidak ditemukan: " .. jobName)
                return false 
            end
            
            local player = game.Players.LocalPlayer
            local character = player.Character
            if not character then
                character = player.CharacterAdded:Wait()
            end
            
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            
            -- Teleport player ke lokasi job
            humanoidRootPart.CFrame = job.TeleportCFrame
            print("🚀 Teleportasi ke " .. job.Location .. " sebagai " .. job.Title)
            
            return true
        end

        -- Fungsi untuk memulai kerja
        function StartWorking(jobName)
            local job = jobData[jobName]
            if not job then return false end
            
            print("🔄 Memulai kerja sebagai " .. job.Title)
            
            -- Cari workstation/interaksi job di area
            local workstation = FindWorkstation(jobName, job.Location)
            if workstation then
                -- Interaksi dengan workstation
                InteractWithWorkstation(workstation, jobName)
                return true
            else
                print("❌ Workstation tidak ditemukan untuk " .. job.Title)
                return false
            end
        end

        -- Fungsi untuk mencari workstation
        function FindWorkstation(jobName, location)
            local workspace = game:GetService("Workspace")
            
            -- Cari berdasarkan lokasi job
            local locationParts = {}
            
            -- Cari bagian yang berhubungan dengan lokasi
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Part") or obj:IsA("Model") then
                    if string.find(obj.Name:lower(), location:lower()) or 
                       string.find(obj.Name:lower(), jobName:lower()) then
                        table.insert(locationParts, obj)
                    end
                end
            end
            
            -- Cari interactive parts (proximity prompts, click detectors, dll)
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
                    table.insert(locationParts, obj.Parent)
                end
            end
            
            return locationParts[1] -- Return workstation pertama yang ditemukan
        end

        -- Fungsi untuk interaksi dengan workstation
        function InteractWithWorkstation(workstation, jobName)
            local player = game.Players.LocalPlayer
            local character = player.Character
            if not character then return end
            
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then return end
            
            -- Pindah ke dekat workstation
            if workstation:IsA("Part") then
                humanoidRootPart.CFrame = workstation.CFrame + Vector3.new(0, 0, 3)
            elseif workstation:IsA("Model") and workstation.PrimaryPart then
                humanoidRootPart.CFrame = workstation.PrimaryPart.CFrame + Vector3.new(0, 0, 3)
            end
            
            -- Cari dan trigger proximity prompt atau click detector
            local proximityPrompt = workstation:FindFirstChildOfClass("ProximityPrompt")
            if proximityPrompt then
                -- Trigger proximity prompt
                fireproximityprompt(proximityPrompt)
                print("🔘 Triggered ProximityPrompt: " .. jobName)
            end
            
            local clickDetector = workstation:FindFirstChildOfClass("ClickDetector")
            if clickDetector then
                -- Trigger click detector
                clickDetector:FireServer()
                print("🔘 Triggered ClickDetector: " .. jobName)
            end
            
            -- Coba remote events
            TriggerJobRemoteEvents(jobName)
            
            wait(2) -- Tunggu proses interaksi
        end

        -- Fungsi untuk trigger remote events berdasarkan job
        function TriggerJobRemoteEvents(jobName)
            local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
            if not remotes then return end
            
            local jobEvents = {
                BloxBurgersEmployee = {"StartCooking", "CookFood", "ServeFood"},
                PizzaPlanetBaker = {"MakePizza", "BakePizza", "PrepareDough"},
                PizzaPlanetDelivery = {"StartDelivery", "CompleteDelivery"},
                LumberWoodcutter = {"ChopTree", "CollectWood"},
                CaveMiner = {"MineRock", "CollectOre"},
                SupermarketStocker = {"StockItem", "RestockShelf"},
                SupermarketCashier = {"ScanItem", "ProcessPayment"},
                HighSchoolTeacher = {"StartClass", "TeachLesson"},
                SchoolJanitor = {"CleanArea", "SweepFloor"},
                HutFisherman = {"StartFishing", "CatchFish"},
                BensIceCreamSeller = {"ServeIceCream", "MakeCone"},
                MikeMechanic = {"RepairCar", "FixEngine"},
                StylezHairdresser = {"CutHair", "StyleHair"}
            }
            
            local events = jobEvents[jobName] or {"StartWork", "WorkAction"}
            
            for _, eventName in pairs(events) do
                local remoteEvent = remotes:FindFirstChild(eventName)
                if remoteEvent then
                    pcall(function()
                        remoteEvent:FireServer()
                        print("📡 Fired remote: " .. eventName)
                    end)
                end
            end
        end

        -- Fungsi utama untuk memulai auto job
        function StartAutoJob(jobName)
            if not vars.AutoJob then return end
            
            local jobInfo = jobData[jobName]
            if not jobInfo then
                print("❌ Job tidak valid: " .. jobName)
                return
            end
            
            print("🚀 Memulai Auto Job: " .. jobInfo.Title)
            
            -- Step 1: Teleportasi ke lokasi job
            local teleportSuccess = TeleportToJob(jobName)
            if not teleportSuccess then
                print("❌ Gagal teleportasi ke lokasi job")
                return
            end
            
            wait(3) -- Tunggu sampai teleportasi selesai
            
            -- Step 2: Mulai kerja
            local workSuccess = StartWorking(jobName)
            if not workSuccess then
                print("❌ Gagal memulai kerja")
                return
            end
            
            -- Step 3: Setup loop kerja otomatis
            if getgenv().AutoJobConnection then
                getgenv().AutoJobConnection:Disconnect()
            end
            
            getgenv().AutoJobConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if not vars.AutoJob then
                    getgenv().AutoJobConnection:Disconnect()
                    return
                end
                
                -- Terus bekerja setiap 8 detik
                if tick() % 8 < 0.1 then
                    StartWorking(jobName)
                end
            end)
        end

        -- Hook untuk memastikan auto job tetap berjalan
        if not getgenv().AutoJobHooked then
            getgenv().AutoJobHooked = true
            
            -- Periodic check untuk memastikan auto job tetap aktif
            coroutine.wrap(function()
                while wait(20) do
                    if vars.AutoJob then
                        -- Cek apakah player masih di lokasi job
                        local player = game.Players.LocalPlayer
                        local character = player.Character
                        if character then
                            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                            if humanoidRootPart then
                                local currentJob = jobData[vars.SelectedJob]
                                if currentJob then
                                    local distance = (humanoidRootPart.Position - currentJob.TeleportCFrame.Position).Magnitude
                                    
                                    if distance > 50 then -- Jika terlalu jauh dari job
                                        print("🔄 Player terlalu jauh, teleportasi ulang...")
                                        TeleportToJob(vars.SelectedJob)
                                    end
                                end
                            end
                        end
                    end
                end
            end)()
            
            print("✅ [Auto Job] Sistem periodic check aktif.")
        end

        -- Display job info
        print("\n📊 JOBS YANG TERSEDIA:")
        for _, jobName in pairs(jobList) do
            local job = jobData[jobName]
            if job then
                print("  • " .. job.Title .. " (" .. jobName .. ") - " .. job.Location)
            end
        end

        print("\n✅ [Auto Job] Sistem aktif. Pilih job dan aktifkan toggle untuk mulai bekerja otomatis.")
        
        -- Info penting untuk user
        print("\n📝 INSTRUKSI:")
        print("1. Pilih job dari dropdown")
        print("2. Aktifkan toggle Auto Job") 
        print("3. Sistem akan otomatis teleport dan mulai bekerja")
        print("4. Gunakan button 'Teleport ke Job' untuk teleport manual")
    end
}