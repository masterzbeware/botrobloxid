-- FrontCover.lua
-- Command !frontcover: Bot membentuk formasi Front Cover (3 depan, 2 samping VIP)

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        if not vars then
            warn("[FRONTCOVER] _G.BotVars tidak ditemukan!")
            return
        end

        local RunService = vars.RunService
        local player = vars.LocalPlayer

        if not RunService or not player then
            warn("[FRONTCOVER] RunService atau LocalPlayer tidak tersedia!")
            return
        end

        -- 🔹 Toggle mode FrontCover
        vars.FrontCoverActive = not vars.FrontCoverActive

        -- 🔹 Matikan formasi lain agar tidak bentrok
        vars.FollowAllowed = false
        vars.RowActive = false
        vars.WedgeActive = false
        vars.ShieldActive = false
        vars.FrontlineActive = false
        vars.BoxActive = false
        vars.CircleMoveActive = false
        vars.PushupActive = false
        vars.SyncActive = false
        vars.ReportingActive = false
        vars.RoomVIPActive = false
        vars.BarrierActive = false
        vars.SquareActive = false
        vars.CurrentFormasiTarget = nil

        -- 🔹 Hentikan koneksi lama jika masih aktif
        if vars.FrontCoverConnection then
            pcall(function() vars.FrontCoverConnection:Disconnect() end)
            vars.FrontCoverConnection = nil
        end

        -- 🔹 Jika dinonaktifkan, berhenti di sini
        if not vars.FrontCoverActive then
            print("[FRONTCOVER] Formasi Front Cover dinonaktifkan.")
            return
        end

        -- 🔹 Tentukan target (VIP)
        local target
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
                print("[FRONTCOVER] Target tidak ditemukan. Menggunakan client sebagai target.")
                target = client
            end
        else
            target = client
        end

        vars.CurrentFormasiTarget = target
        print("[FRONTCOVER] Formasi Front Cover diaktifkan. Target:", target.Name)

        -- 🔹 Referensi karakter bot
        local humanoid, myRootPart, moving
        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end
        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        -- 🔹 Fungsi untuk bergerak ke posisi tertentu
        local function moveToPosition(targetPos, lookAtPos)
            if not humanoid or not myRootPart then return end
            if moving then return end
            if (myRootPart.Position - targetPos).Magnitude < 1 then return end

            moving = true
            humanoid:MoveTo(targetPos)
            humanoid.MoveToFinished:Wait()
            moving = false

            if lookAtPos then
                myRootPart.CFrame = CFrame.new(
                    myRootPart.Position,
                    Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z)
                )
            end
        end

        -- 🔹 Jalankan loop Heartbeat
        vars.FrontCoverConnection = RunService.Heartbeat:Connect(function()
            -- Jika dihentikan lewat !stop, hentikan koneksi otomatis
            if not vars.FrontCoverActive then
                pcall(function()
                    if vars.FrontCoverConnection then
                        vars.FrontCoverConnection:Disconnect()
                        vars.FrontCoverConnection = nil
                    end
                end)
                print("[FRONTCOVER] Dihentikan oleh Stop.lua.")
                return
            end

            if not target or not target.Character then return end
            local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- Urutan bot (G1–G5)
            local orderedBots = {
                "8802945328", -- G1 (depan kiri)
                "8802949363", -- G2 (kiri VIP)
                "8802939883", -- G3 (depan tengah)
                "8802998147", -- G4 (kanan VIP)
                "8802991722", -- G5 (depan kanan)
            }

            local myUserId = tostring(player.UserId)
            local index = 1
            for i, uid in ipairs(orderedBots) do
                if uid == myUserId then
                    index = i
                    break
                end
            end

            -- 🔹 Jarak antar posisi
            local jarakDepan = tonumber(vars.JarakDepan) or 4
            local jarakBelakang = tonumber(vars.JarakBelakang) or 3
            local jarakSamping = tonumber(vars.SideSpacing) or 3

            -- 🔹 Offset posisi formasi Front Cover
            local offsetMap = {
                [1] = Vector3.new(-jarakSamping * 1.5, 0, jarakDepan),  -- G1 depan kiri
                [2] = Vector3.new(-jarakSamping, 0, 0),                 -- G2 kiri VIP
                [3] = Vector3.new(0, 0, jarakDepan),                    -- G3 depan tengah
                [4] = Vector3.new(jarakSamping, 0, 0),                  -- G4 kanan VIP
                [5] = Vector3.new(jarakSamping * 1.5, 0, jarakDepan),   -- G5 depan kanan
            }

            local offset = offsetMap[index] or Vector3.zero
            local cframe = targetHRP.CFrame
            local targetPos = (
                cframe.Position
                + cframe.RightVector * offset.X
                + cframe.UpVector * offset.Y
                + cframe.LookVector * offset.Z
            )

            moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)
        end)
    end
}
