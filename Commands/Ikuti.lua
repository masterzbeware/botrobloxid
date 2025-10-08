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
            if not target then
                print("[IKUTI] Target tidak ditemukan. Mengikuti client sebagai target.")
                target = client
            end
        end

        vars.CurrentFormasiTarget = target

        local humanoid, myRootPart

        -- 🔹 Referensi karakter bot
        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end

        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        -- ==============================================
        -- 🚀 Fungsi Gerak Cepat & Non-blocking (path ringan)
        -- ==============================================
        local lastTargetPos = nil
        local activePath = nil

        local function moveToPosition(targetPos, lookAtPos)
            if not humanoid or not myRootPart then return end

            -- Hitung ulang path hanya jika target berubah jauh
            if not lastTargetPos or (lastTargetPos - targetPos).Magnitude > 10 then
                lastTargetPos = targetPos

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
                else
                    -- Fallback: langsung ke posisi target
                    activePath = { { Position = targetPos } }
                end
            end

            -- Gerak ke waypoint terdekat
            if activePath and #activePath > 0 then
                local waypoint = activePath[1]
                humanoid:MoveTo(waypoint.Position)

                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    humanoid.Jump = true
                end

                -- Jika sudah dekat waypoint, hapus dari daftar
                if (myRootPart.Position - waypoint.Position).Magnitude < 2 then
                    table.remove(activePath, 1)
                end
            end

            -- Atur arah pandang ke target
            if lookAtPos then
                myRootPart.CFrame = CFrame.new(
                    myRootPart.Position,
                    Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z)
                )
            end
        end

        -- 🔹 Putuskan koneksi lama (kalau ada)
        if vars.FollowConnection then
            pcall(function() vars.FollowConnection:Disconnect() end)
            vars.FollowConnection = nil
        end

        -- ==============================================
        -- ♻️ Heartbeat Loop
        -- ==============================================
        vars.FollowConnection = RunService.Heartbeat:Connect(function(dt)
            vars.AbsenActive = vars.AbsenActive or {}
            local myId = tostring(player.UserId)
            if vars.AbsenActive[myId] then return end

            if not vars.FollowAllowed or not target.Character then return end
            local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            local jarakIkut = tonumber(vars.JarakIkut) or 6
            local followSpacing = tonumber(vars.FollowSpacing) or 4

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

            moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)
        end)

        print("[COMMAND] Formasi Ikuti aktif, target:", target.Name)
    end
}
