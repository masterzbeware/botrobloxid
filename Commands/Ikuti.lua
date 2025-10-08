-- Ikuti.lua
-- Command !ikuti: Bot mengikuti pemain VIP secara rapi berbaris ke belakang
-- Kompatibel dengan Barrier.lua dan formasi lain
-- Bisa menarget pemain tertentu dengan !ikuti {displayname/username}
-- Jika tidak ada argumen, default ke client

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer
        local PathfindingService = vars.PathfindingService or game:GetService("PathfindingService")

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
                if plr.DisplayName:lower():find(searchName:lower()) or plr.Name:lower():find(searchName:lower()) then
                    target = plr
                    break
                end
            end
        end

        vars.CurrentFormasiTarget = target

        local humanoid, myRootPart
        local moving = false
        local currentWaypointIndex = 1
        local activePath = nil
        local lastCompute = 0

        -- 🔹 Referensi karakter bot
        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end
        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        -- 🔹 Buat path baru jika perlu
        local function computePathTo(targetPos)
            if tick() - lastCompute < 1.5 then return end -- hitung ulang tiap 1.5 detik saja
            lastCompute = tick()

            local path = PathfindingService:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true,
                AgentJumpHeight = 5,
                AgentMaxSlope = 45,
            })

            path:ComputeAsync(myRootPart.Position, targetPos)
            if path.Status == Enum.PathStatus.Success then
                activePath = path:GetWaypoints()
                currentWaypointIndex = 1
            else
                activePath = { { Position = targetPos } } -- fallback
            end
        end

        -- 🔹 Gerakkan ke waypoint berikutnya
        local function followPath()
            if not activePath or moving then return end
            if currentWaypointIndex > #activePath then return end

            local wp = activePath[currentWaypointIndex]
            moving = true
            humanoid:MoveTo(wp.Position)
            if wp.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end

            humanoid.MoveToFinished:Once(function(reached)
                moving = false
                if reached then
                    currentWaypointIndex += 1
                else
                    -- Kalau gagal sampai, coba ulang path
                    lastCompute = 0
                end
            end)
        end

        -- 🔹 Hapus koneksi lama
        if vars.FollowConnection then
            pcall(function() vars.FollowConnection:Disconnect() end)
        end

        -- 🔹 Heartbeat loop utama
        vars.FollowConnection = RunService.Heartbeat:Connect(function(dt)
            if not vars.FollowAllowed or not target.Character then return end
            local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP or not humanoid or not myRootPart then return end

            local jarakIkut = tonumber(vars.JarakIkut) or 6
            local followSpacing = tonumber(vars.FollowSpacing) or 4

            local orderedBots = {
                "8802945328", "8802949363", "8802939883", "8802998147", "8802991722"
            }

            local myUserId = tostring(player.UserId)
            local index = 1
            for i, uid in ipairs(orderedBots) do
                if uid == myUserId then
                    index = i
                    break
                end
            end

            -- Posisi ideal di belakang target
            local backOffset = jarakIkut + (index - 1) * followSpacing
            local desiredPos = targetHRP.Position - targetHRP.CFrame.LookVector * backOffset

            -- Jika target jauh dari posisi saat ini, hitung ulang path
            if not activePath or (myRootPart.Position - desiredPos).Magnitude > 6 then
                computePathTo(desiredPos)
            end

            -- Jalankan langkah berikutnya
            followPath()

            -- Hadap ke arah target
            myRootPart.CFrame = CFrame.new(
                myRootPart.Position,
                Vector3.new(targetHRP.Position.X, myRootPart.Position.Y, targetHRP.Position.Z)
            )
        end)

        print("[COMMAND] Formasi Ikuti aktif, target:", target.Name)
    end
}
