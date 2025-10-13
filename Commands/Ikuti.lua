-- Ikuti.lua
-- Command !ikuti:
--   Bot mengikuti pemain VIP secara rapi berbaris ke belakang
--   Bisa menarget pemain tertentu dengan !ikuti {displayname/username/UserId}
--   Jika tidak ada argumen, default ke client (_G.BotVars.ClientRef)

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        if not RunService then
            warn("[Ikuti] RunService tidak tersedia!")
            return
        end

        -- 🔹 Nonaktifkan formasi lain agar tidak bentrok
        vars.BarrierActive = false
        if vars.BarrierConnection then
            pcall(function() vars.BarrierConnection:Disconnect() end)
            vars.BarrierConnection = nil
        end

        vars.ShieldActive = false
        vars.RowActive = false
        vars.FrontlineActive = false
        vars.CircleMoveActive = false
        vars.PushupActive = false
        vars.SyncActive = false
        vars.ReportingActive = false
        vars.RoomVIPActive = false

        -- 🔹 Aktifkan mode Ikuti
        vars.FollowAllowed = true

        -- 🔹 Tentukan target
        local target = client or vars.ClientRef
        local args = {}

        for word in msg:gmatch("%S+") do
            table.insert(args, word)
        end

        if #args > 1 then
            local searchNameOrId = table.concat(args, " ", 2)
            local id = tonumber(searchNameOrId)
            if id then
                local plr = game.Players:GetPlayerByUserId(id)
                if plr then target = plr end
            else
                for _, plr in ipairs(game.Players:GetPlayers()) do
                    if plr.Name:lower():find(searchNameOrId:lower())
                    or plr.DisplayName:lower():find(searchNameOrId:lower()) then
                        target = plr
                        break
                    end
                end
            end

            if not target then
                print("[Ikuti] Target tidak ditemukan. Mengikuti client default.")
                target = vars.ClientRef
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
                if not vars.FollowAllowed or not target or not target.Character then return end
                local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
                if not targetHRP then return end

                local jarakIkut = tonumber(vars.JarakIkut) or 3
                local followSpacing = tonumber(vars.FollowSpacing) or 3

                -- 🔹 Urutan bot agar rapi
                local orderedBots = {
                    "8802945328", -- Bot1
                    "8802949363", -- Bot2
                    "8802939883", -- Bot3
                    "8802998147", -- Bot4
                    "8802991722", -- Bot5
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
