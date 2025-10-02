-- Ikuti.lua
-- Command !ikuti: Bot mengikuti pemain VIP secara rapih berbaris ke belakang

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        if not RunService then
            warn("[Ikuti] RunService tidak tersedia!")
            return
        end

        -- 🔹 Atur mode Ikuti
        vars.FollowAllowed = true
        vars.ShieldActive = false
        vars.RowActive = false
        vars.FrontlineActive = false
        vars.CurrentFormasiTarget = client

        local humanoid, myRootPart, moving

        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end

        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        local function moveToPosition(targetPos, lookAtPos)
            if not humanoid or not myRootPart then return end
            if moving then return end
            if (myRootPart.Position - targetPos).Magnitude < 2 then return end

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

        -- Putuskan koneksi lama dulu
        if vars.FollowConnection then pcall(function() vars.FollowConnection:Disconnect() end) vars.FollowConnection = nil end

        -- 🔹 Heartbeat loop Ikuti
        if RunService.Heartbeat then
            vars.FollowConnection = RunService.Heartbeat:Connect(function()
                -- ⚠️ Jika bot sedang absen, skip Ikuti agar tidak tabrakan
                vars.AbsenActive = vars.AbsenActive or {}
                local myId = tostring(player.UserId)
                if vars.AbsenActive[myId] then return end

                if not vars.FollowAllowed or not client.Character then return end
                local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
                if not targetHRP then return end

                local jarakIkut = tonumber(vars.JarakIkut) or 6   -- jarak minimum belakang VIP
                local followSpacing = tonumber(vars.FollowSpacing) or 4 -- jarak antar bot

                -- Bot Mapping agar urutan rapi
                local orderedBots = {
                    "8802945328", -- Bot1
                    "8802949363", -- Bot2
                    "8802939883", -- Bot3
                    "8802998147", -- Bot4
                }

                local myUserId = tostring(player.UserId)
                local index = 1
                for i, uid in ipairs(orderedBots) do
                    if uid == myUserId then
                        index = i
                        break
                    end
                end

                -- 🔹 Posisi barisan di belakang target (VIP)
                local backOffset = jarakIkut + (index - 1) * followSpacing
                local targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * backOffset

                moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)
            end)
        else
            warn("[Ikuti] RunService.Heartbeat tidak tersedia!")
        end

        print("[COMMAND] Formasi Ikuti aktif, target:", client.Name)
    end
}
