-- Box.lua
-- Command !box: Bot membentuk formasi Box di sekitar target (VIP di tengah)

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        if not vars then
            warn("[BOX] _G.BotVars tidak ditemukan!")
            return
        end

        local RunService = vars.RunService
        local player = vars.LocalPlayer

        if not RunService or not player then
            warn("[BOX] RunService atau LocalPlayer tidak tersedia!")
            return
        end

        -- 🔹 Toggle mode Box
        vars.BoxActive = not vars.BoxActive

        -- 🔹 Matikan semua formasi lain agar tidak bentrok
        vars.FollowAllowed = false
        vars.RowActive = false
        vars.WedgeActive = false
        vars.ShieldActive = false
        vars.FrontlineActive = false
        vars.CircleMoveActive = false
        vars.PushupActive = false
        vars.SyncActive = false
        vars.ReportingActive = false
        vars.RoomVIPActive = false
        vars.BarrierActive = false
        vars.SquareActive = false
        vars.CurrentFormasiTarget = nil

        -- 🔹 Hentikan koneksi lama jika masih aktif
        if vars.BoxConnection then
            pcall(function() vars.BoxConnection:Disconnect() end)
            vars.BoxConnection = nil
        end

        -- 🔹 Jika dinonaktifkan, langsung berhenti di sini
        if not vars.BoxActive then
            print("[BOX] Formasi Box dinonaktifkan.")
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
                print("[BOX] Target tidak ditemukan. Menggunakan client sebagai target.")
                target = client
            end
        else
            target = client
        end

        vars.CurrentFormasiTarget = target
        print("[BOX] Formasi Box diaktifkan. Target:", target and target.Name or "Unknown")

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

        -- 🔹 Mulai Heartbeat loop
        vars.BoxConnection = RunService.Heartbeat:Connect(function()
            if not vars.BoxActive then
                -- Jika !stop dijalankan, hentikan otomatis
                pcall(function() vars.BoxConnection:Disconnect() end)
                vars.BoxConnection = nil
                return
            end

            if not target or not target.Character then return end
            local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- Urutan formasi bot
            local orderedBots = {
                "10191476366", -- B1 depan kiri
                "10191480511", -- B2 depan kanan
                "10191462654", -- B3 belakang kiri
                "10190853828", -- B4 belakang kanan
                "10191023081", -- B5 tengah belakang (Bot5)
                "10191070611", -- B6 tambahan
                "10191489151", -- B7 tambahan
                "10191571531", -- B8 tambahan
            }

            local myUserId = tostring(player.UserId)
            local index = 1
            for i, uid in ipairs(orderedBots) do
                if uid == myUserId then
                    index = i
                    break
                end
            end

            -- Jarak formasi (dapat diatur lewat BotVars)
            local jarakDepan = tonumber(vars.JarakDepan) or 4
            local jarakBelakang = tonumber(vars.JarakBelakang) or 4
            local jarakSamping = tonumber(vars.SideSpacing) or 3

            -- Posisi relatif berdasarkan index bot
            local offsetMap = {
                [1] = Vector3.new(-jarakSamping * 1.2, 0, 0),          -- kiri VIP
                [2] = Vector3.new(-jarakSamping / 1.5, 0, jarakDepan), -- depan kiri
                [3] = Vector3.new(jarakSamping / 1.5, 0, jarakDepan),  -- depan kanan
                [4] = Vector3.new(jarakSamping * 1.2, 0, 0),           -- kanan VIP
                [5] = Vector3.new(0, 0, -jarakBelakang * 1.2),         -- belakang VIP
            }

            local offset = offsetMap[index] or Vector3.zero
            local cframe = targetHRP.CFrame
            local targetPos = (cframe.Position
                + cframe.RightVector * offset.X
                + cframe.UpVector * offset.Y
                + cframe.LookVector * offset.Z)

            moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)
        end)
    end
}
