return {
    Execute = function(tab)
        local vars = _G.BotVars or {}
        local Tabs = vars.Tabs or {}
        local CombatTab = tab or Tabs.Combat

        if not CombatTab then
            warn("[Auto Heal] Tab Combat tidak ditemukan!")
            return
        end

        local Group = CombatTab:AddLeftGroupbox("Auto Heal")
        local RunService = game:GetService("RunService")

        vars.AutoHeal = vars.AutoHeal or false

        -- Status variables
        local healthMonitorConnection = nil
        local characterAddedConnection = nil
        local humanoid = nil
        local lastHealTime = 0
        local HEAL_COOLDOWN = 0.5

        Group:AddToggle("ToggleAutoHeal", {
            Text = "Auto Heal",
            Default = vars.AutoHeal,
            Callback = function(v)
                vars.AutoHeal = v
                if v then
                    print("✅ Auto Heal diaktifkan - Akan heal otomatis ketika HP < 100")
                    StartRealTimeHealthMonitor()
                else
                    print("❌ Auto Heal dimatikan")
                    StopRealTimeHealthMonitor()
                end
            end
        })

        function StartRealTimeHealthMonitor()
            StopRealTimeHealthMonitor() -- Pastikan stop dulu
            
            local player = game.Players.LocalPlayer
            if not player then 
                warn("❌ Player tidak ditemukan!")
                return 
            end
            
            -- Function untuk setup character dengan delay yang tepat
            local function setupCharacter(character)
                -- Tunggu humanoid tersedia
                local attempts = 0
                local maxAttempts = 10
                
                local function waitForHumanoid()
                    humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        -- Setup health monitoring
                        healthMonitorConnection = humanoid.HealthChanged:Connect(function(health)
                            if vars.AutoHeal and health < 100 then
                                CheckAndHeal(health)
                            end
                        end)
                        
                        -- Check health saat ini
                        if vars.AutoHeal and humanoid.Health < 100 then
                            CheckAndHeal(humanoid.Health)
                        end
                        
                        print("✅ Real-time health monitoring aktif - HP: " .. math.floor(humanoid.Health))
                        return true
                    end
                    return false
                end
                
                -- Coba beberapa kali dengan delay
                while attempts < maxAttempts and not waitForHumanoid() do
                    attempts += 1
                    wait(0.5)
                end
                
                if attempts >= maxAttempts then
                    warn("❌ Gagal menemukan Humanoid setelah " .. maxAttempts .. " attempts")
                end
            end
            
            -- Setup character saat ini (jika ada)
            if player.Character then
                coroutine.wrap(function()
                    setupCharacter(player.Character)
                end)()
            end
            
            -- Listen untuk character changes
            characterAddedConnection = player.CharacterAdded:Connect(function(character)
                wait(2) -- Tunggu character fully loaded
                if vars.AutoHeal then
                    coroutine.wrap(function()
                        setupCharacter(character)
                    end)()
                end
            end)
        end

        function StopRealTimeHealthMonitor()
            if healthMonitorConnection then
                healthMonitorConnection:Disconnect()
                healthMonitorConnection = nil
            end
            if characterAddedConnection then
                characterAddedConnection:Disconnect()
                characterAddedConnection = nil
            end
            humanoid = nil
            print("❌ Health monitoring dihentikan")
        end

        function CheckAndHeal(currentHealth)
            -- Cek cooldown
            if tick() - lastHealTime < HEAL_COOLDOWN then
                return
            end
            
            -- Pastikan health masih di bawah 100
            if currentHealth >= 100 then
                return
            end
            
            -- Pastikan player masih hidup
            if humanoid and humanoid.Health <= 0 then
                return
            end
            
            print("🩺 Health rendah: " .. math.floor(currentHealth) .. " HP - Melakukan healing sequence...")
            ExecuteHealingSequence()
            lastHealTime = tick()
        end

        function ExecuteHealingSequence()
            -- Urutan: Dressing → Bandage → Dressing
            print("🔁 Memulai healing sequence: Dressing → Bandage → Dressing")
            
            -- Gunakan coroutine untuk menghindari blocking
            coroutine.wrap(function()
                UseMedicalItem("Dressing")
                wait(0.3)
                
                UseMedicalItem("Bandage") 
                wait(0.3)
                
                UseMedicalItem("Dressing")
                
                print("✅ Healing sequence selesai")
            end)()
        end

        function UseMedicalItem(itemType)
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local RemoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent") 
            
            if not RemoteEvent then
                -- Coba cari di Events folder
                local Events = ReplicatedStorage:FindFirstChild("Events")
                if Events then
                    RemoteEvent = Events:FindFirstChild("RemoteEvent")
                end
            end
            
            if not RemoteEvent then
                warn("❌ RemoteEvent tidak ditemukan!")
                return false
            end

            local playerId = GetPlayerID()
            local success = false
            
            if itemType == "Dressing" then
                success = pcall(function()
                    RemoteEvent:FireServer(
                        "StateActor",
                        playerId,
                        "Medical",
                        "Dressing",
                        true
                    )
                end)
            elseif itemType == "Bandage" then
                success = pcall(function()
                    RemoteEvent:FireServer(
                        "StateActor", 
                        playerId,
                        "Medical",
                        "Bandage",
                        true
                    )
                end)
            end
            
            if success then
                print("✅ " .. itemType .. " berhasil digunakan")
                return true
            else
                warn("❌ Gagal menggunakan " .. itemType)
                return false
            end
        end

        function GetPlayerID()
            local player = game.Players.LocalPlayer
            if player then
                return tostring(player.UserId)
            end
            return "unknown"
        end

        -- Auto restart monitoring jika game dimuat ulang
        if not getgenv().BandageHooked then
            getgenv().BandageHooked = true
            
            -- Auto restart ketika player respawn
            game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(character)
                wait(3) -- Tunggu lebih lama untuk character fully loaded
                if vars.AutoHeal then
                    print("🔄 Character respawned - restarting health monitor...")
                    StartRealTimeHealthMonitor()
                end
            end)
            
            print("✅ [Auto Heal] Real-time system aktif")
        end

        -- Jika AutoHeal sudah aktif sebelumnya, start monitoring dengan delay
        if vars.AutoHeal then
            wait(2)
            StartRealTimeHealthMonitor()
        end

        print("✅ [Auto Heal] Sistem aktif. Gunakan toggle untuk mengaktifkan/mematikan auto heal.")
    end
}