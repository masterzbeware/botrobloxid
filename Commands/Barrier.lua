-- Barrier.lua
-- Command !barrier: Bot membentuk formasi penghalang di sekitar VIP
-- Kompatibel dengan Stop.lua & Ikuti.lua
-- Bisa menarget pemain tertentu dengan !barrier {displayname/username}
-- Jika tidak ada argumen, default ke client

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        if not RunService then
            warn("[Barrier] RunService tidak tersedia!")
            return
        end

        -- 🔹 Toggle Barrier
        vars.BarrierActive = not vars.BarrierActive

        -- 🔹 Nonaktifkan mode formasi lain tapi jangan matikan FollowAllowed agar Ikuti tetap jalan
        vars.RowActive = false
        vars.SquareActive = false
        vars.WedgeActive = false
        vars.ShieldActive = false
        vars.FrontlineActive = false
        vars.CircleMoveActive = false
        vars.PushupActive = false
        vars.SyncActive = false
        vars.ReportingActive = false
        vars.RoomVIPActive = false

        -- 🔹 Tentukan target
        local target = client
        local args = {}
        for word in msg:gmatch("%S+") do
            table.insert(args, word)
        end

        if #args > 1 then
            local searchName = table.concat(args, " ", 2)
            for _, plr in ipairs(game.Players:GetPlayers()) do
                if plr.DisplayName:lower():find(searchName:lower()) or plr.Name:lower():find(searchName:lower()) then
                    target = plr
                    break
                end
            end
            if not target then
                print("[BARRIER] Target tidak ditemukan. Menggunakan client sebagai target.")
                target = client
            end
        end

        vars.CurrentFormasiTarget = target

        -- 🔹 Jika dinonaktifkan, hentikan koneksi & keluar
        if not vars.BarrierActive then
            print("[BARRIER] Dinonaktifkan")
            if vars.BarrierConnection then
                pcall(function() vars.BarrierConnection:Disconnect() end)
                vars.BarrierConnection = nil
            end
            return
        end

        print("[BARRIER] Formasi Barrier diaktifkan. Target:", target.Name)

        -- 🔹 Referensi karakter bot
        local humanoid, myRootPart, moving
        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end
        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        local function moveToPosition(targetPos, lookVector)
            if not humanoid or not myRootPart then return end
            if moving then return end
            if (myRootPart.Position - targetPos).Magnitude < 1 then return end

            moving = true
            humanoid:MoveTo(targetPos)
            humanoid.MoveToFinished:Wait()
            moving = false

            if lookVector then
                -- 🔹 Menghadap arah yang sama seperti VIP
                myRootPart.CFrame = CFrame.new(targetPos, targetPos + lookVector)
            end
        end

        -- 🔹 Putuskan koneksi lama
        if vars.BarrierConnection then
            pcall(function() vars.BarrierConnection:Disconnect() end)
            vars.BarrierConnection = nil
        end

        -- 🔹 Heartbeat loop
        if RunService.Heartbeat then
            vars.BarrierConnection = RunService.Heartbeat:Connect(function()
                if not vars.BarrierActive or not target.Character then return end
                local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
                if not targetHRP then return end

                -- 🔹 Mapping bot
                local orderedBots = {
                    "8802945328", -- B1 kiri VIP
                    "8802939883", -- B2 kiri VIP
                    "8802949363", -- B3 kanan VIP
                    "8802998147", -- B4 kanan VIP
                }

                local myUserId = tostring(player.UserId)
                local index = 1
                for i, uid in ipairs(orderedBots) do
                    if uid == myUserId then
                        index = i
                        break
                    end
                end

                -- 🔹 Konfigurasi jarak
                local jarakSamping = tonumber(vars.SideSpacing) or 3
                local jarakDepanBelakang = tonumber(vars.FrontBackSpacing) or 0

                -- 🔹 Offset posisi per bot
                local offsetMap = {
                    [1] = Vector3.new(-2*jarakSamping, 0, jarakDepanBelakang),
                    [2] = Vector3.new(-jarakSamping, 0, jarakDepanBelakang),
                    [3] = Vector3.new(jarakSamping, 0, jarakDepanBelakang),
                    [4] = Vector3.new(2*jarakSamping, 0, jarakDepanBelakang),
                }

                local offset = offsetMap[index] or Vector3.zero
                local cframe = targetHRP.CFrame
                local targetPos = (cframe.Position
                    + cframe.RightVector * offset.X
                    + cframe.UpVector * offset.Y
                    + cframe.LookVector * offset.Z)

                -- 🔹 Tetap menghadap sama seperti VIP
                moveToPosition(targetPos, targetHRP.CFrame.LookVector)
            end)
        else
            warn("[Barrier] RunService.Heartbeat tidak tersedia!")
        end
    end
}
