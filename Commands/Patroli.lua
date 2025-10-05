-- Patroli.lua
-- Command !patroli: Bot berpatroli di sekitar Komandan secara teratur

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        if not RunService then
            warn("[Patroli] RunService tidak tersedia!")
            return
        end

        -- 🔹 Atur mode Patroli
        vars.PatroliActive = true
        vars.FollowAllowed = false
        vars.ShieldActive = false
        vars.RowActive = false
        vars.FrontlineActive = false
        vars.CurrentFormasiTarget = client

        print("[COMMAND] Mode Patroli aktif, target:", client.Name)

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

        -- Putuskan koneksi lama
        if vars.PatroliConnection then
            pcall(function() vars.PatroliConnection:Disconnect() end)
            vars.PatroliConnection = nil
        end

        -- 🔹 Konfigurasi pola patroli
        local radius = tonumber(vars.PatroliRadius) or 15
        local speed = tonumber(vars.PatroliSpeed) or 0.5 -- semakin kecil = lebih cepat
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

        local angleOffset = (index - 1) * (math.pi / 2) -- 90° per bot
        local patrolTime = 0

        -- 🔹 Loop utama patroli
        vars.PatroliConnection = RunService.Heartbeat:Connect(function(dt)
            if not vars.PatroliActive or not client.Character then return end
            local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            patrolTime += dt * speed
            local angle = patrolTime + angleOffset

            -- 🔹 Bot bergerak mengelilingi Komandan (melingkar)
            local offsetX = math.cos(angle) * radius
            local offsetZ = math.sin(angle) * radius
            local targetPos = targetHRP.Position + Vector3.new(offsetX, 0, offsetZ)

            moveToPosition(targetPos, targetHRP.Position)
        end)
    end
}
