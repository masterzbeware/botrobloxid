-- Ikuti.lua
-- Command !ikuti:
--   Bot mengikuti pemain VIP secara rapi berbaris ke belakang
--   Kompatibel dengan Barrier.lua dan formasi lain
--   Bisa menarget pemain tertentu dengan !ikuti {displayname/username}
--   Jika tidak ada argumen, default ke client

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        if not RunService then
            warn("[Ikuti] RunService tidak tersedia!")
            return
        end

        -- 🔹 Aktifkan mode Ikuti
        vars.FollowAllowed = true
        vars.ShieldActive = false
        vars.RowActive = false
        vars.FrontlineActive = false

        -- 🔹 Tentukan target
        local target = client
        local args = {}

        for word in msg:gmatch("%S+") do
            table.insert(args, word)
        end

        if #args > 1 then
            local searchName = table.concat(args, " ", 2)
            for _, plr in ipairs(game.Players:GetPlayers()) do
                if plr.DisplayName:lower():find(searchName:lower())
                    or plr.Name:lower():find(searchName:lower()) then
                    target = plr
                    break
                end
            end

            if not target then
                print("[IKUTI] Target tidak ditemukan. Mengikuti client sebagai target.")
                target = client
            end
        end

        vars.CurrentFormasiTarget = target

        -- 🔹 Referensi karakter bot
        local humanoid, myRootPart, moving

        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end

        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        -- 🔹 Fungsi gerak bot dengan timeout (anti-nabrak)
        local function moveToPosition(targetPos, lookAtPos)
            if not humanoid or not myRootPart or moving then return end
            if (myRootPart.Position - targetPos).Magnitude < 2 then return end

            moving = true
            humanoid:MoveTo(targetPos)

            local reached = false
            local startTime = tick()
            local timeout = 2.5 -- detik batas waktu sebelum move dibatalkan

            local connection
            connection = humanoid.MoveToFinished:Connect(function(success)
                reached = success
            end)

            -- Tunggu sampai berhasil atau timeout
            while not reached and tick() - startTime < timeout do
                if (myRootPart.Position - targetPos).Magnitude < 2 then
                    reached = true
                    break
                end
                task.wait(0.1)
            end

            if connection then connection:Disconnect() end
            moving = false

            -- Atur arah pandang
            if lookAtPos then
                myRootPart.CFrame = CFrame.new(
                    myRootPart.Position,
                    Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z)
                )
            end
        end

        -- 🔹 Putuskan koneksi lama jika ada
        if vars.FollowConnection then
            pcall(function()
                vars.FollowConnection:Disconnect()
            end)
            vars.FollowConnection = nil
        end

        -- 🔹 Heartbeat loop untuk mengikuti VIP
        if RunService.Heartbeat then
            vars.FollowConnection = RunService.Heartbeat:Connect(function()
                -- ⚠️ Abaikan bot yang sedang absen
                vars.AbsenActive = vars.AbsenActive or {}
                local myId = tostring(player.UserId)
                if vars.AbsenActive[myId] then return end

                if not vars.FollowAllowed or not target.Character then return end

                local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
                if not targetHRP then return end

                local jarakIkut = tonumber(vars.JarakIkut) or 3   -- jarak minimum belakang VIP
                local followSpacing = tonumber(vars.FollowSpacing) or 3 -- jarak antar bot

                -- 🔹 Urutan bot agar rapi
                local orderedBots = {
                    "8802945328", -- Bot1
                    "8802949363", -- Bot2
                    "8802939883", -- Bot3
                    "8802998147", -- Bot4 ✅ Tambahan
                    "8802991722", -- Bot5 ✅ Tambahan
                }

                local myUserId = tostring(player.UserId)
                local index = 1
                for i, uid in ipairs(orderedBots) do
                    if uid == myUserId then
                        index = i
                        break
                    end
                end

                -- 🔹 Posisi bot di belakang VIP
                local backOffset = jarakIkut + (index - 1) * followSpacing
                local targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * backOffset
                local lookPos = targetHRP.Position + targetHRP.CFrame.LookVector * 50

                moveToPosition(targetPos, lookPos)
            end)
        else
            warn("[Ikuti] RunService.Heartbeat tidak tersedia!")
        end

        print("[COMMAND] Formasi Ikuti aktif, target:", target.Name)
    end
}
