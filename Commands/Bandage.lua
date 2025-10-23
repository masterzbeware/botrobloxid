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
        local humanoid = nil
        local lastHealTime = 0
        local HEAL_COOLDOWN = 0.5 -- Cooldown lebih pendek untuk sequence cepat

        Group:AddToggle("ToggleAutoHeal", {
            Text = "Auto Heal (<100 HP)",
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
            
            -- Cari humanoid player
            local player = game.Players.LocalPlayer
            if not player then return end
            
            -- Function untuk setup character
            local function setupCharacter(character)
                humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    -- Direct health change event
                    healthMonitorConnection = humanoid.HealthChanged:Connect(function(health)
                        if vars.AutoHeal and health < 100 then
                            CheckAndHeal(health)
                        end
                    end)
                    
                    -- Juga check health saat ini
                    if vars.AutoHeal and humanoid.Health < 100 then
                        CheckAndHeal(humanoid.Health)
                    end
                    
                    print("✅ Real-time health monitoring aktif")
                end
            end
            
            -- Setup character saat ini
            if player.Character then
                setupCharacter(player.Character)
            end
            
            -- Juga listen untuk character changes (respawn, dll)
            player.CharacterAdded:Connect(function(character)
                wait(1) -- Tunggu character fully loaded
                if vars.AutoHeal then
                    setupCharacter(character)
                end
            end)
        end

        function StopRealTimeHealthMonitor()
            if healthMonitorConnection then
                healthMonitorConnection:Disconnect()
                healthMonitorConnection = nil
            end
            humanoid = nil
            print("❌ Health monitoring dihentikan")
        end

        function CheckAndHeal(currentHealth)
            -- Cek cooldown
            if tick() - lastHealTime < HEAL_COOLDOWN then
                return
            end
            
            -- Pastikan health masih di bawah 100 (double check)
            if currentHealth >= 100 then
                return
            end
            
            print("🩺 Health rendah: " .. math.floor(currentHealth) .. " HP - Melakukan healing sequence...")
            ExecuteHealingSequence()
            lastHealTime = tick()
        end

        function ExecuteHealingSequence()
            -- Urutan: Dressing → Bandage → Dressing
            print("🔁 Memulai healing sequence: Dressing → Bandage → Dressing")
            
            -- Dressing pertama
            UseMedicalItem("Dressing")
            wait(0.2) -- Tunggu sebentar antara item
            
            -- Bandage
            UseMedicalItem("Bandage") 
            wait(0.2)
            
            -- Dressing kedua
            UseMedicalItem("Dressing")
            
            print("✅ Healing sequence selesai")
        end

        function UseMedicalItem(itemType)
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local RemoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent") or ReplicatedStorage:FindFirstChild("Events")
            
            if not RemoteEvent then
                warn("❌ RemoteEvent tidak ditemukan!")
                return false
            end

            -- Dapatkan Player ID yang benar
            local playerId = GetPlayerID()
            local success = false
            
            if itemType == "Dressing" then
                -- Gunakan struktur yang benar untuk Dressing
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
                -- Gunakan struktur yang benar untuk Bandage
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
                -- Gunakan UserId sebagai string (format yang umum)
                return tostring(player.UserId)
            end
            return "unknown"
        end

        function GetCurrentHealth()
            if humanoid and humanoid.Health then
                return humanoid.Health
            end
            
            local player = game.Players.LocalPlayer
            if player and player.Character then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    return hum.Health
                end
            end
            return nil
        end

        -- Auto restart monitoring jika game dimuat ulang
        if not getgenv().BandageHooked then
            getgenv().BandageHooked = true
            
            -- Auto restart ketika player respawn
            game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
                if vars.AutoHeal then
                    wait(2) -- Tunggu character fully loaded
                    StartRealTimeHealthMonitor()
                end
            end)
            
            print("✅ [Auto Heal] Real-time system aktif")
        end

        -- Jika AutoHeal sudah aktif sebelumnya, start monitoring
        if vars.AutoHeal then
            wait(1) -- Tunggu sedikit sebelum start
            StartRealTimeHealthMonitor()
        end

        print("✅ [Auto Heal] Sistem aktif. Gunakan toggle untuk mengaktifkan/mematikan auto heal.")
    end
}