-- IkutiPlus.lua
-- Bot mengikuti pemain VIP dengan kecerdasan adaptif, prediksi gerakan, dan formasi dinamis

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        if not RunService then
            warn("[Ikuti+] RunService tidak tersedia!")
            return
        end

        vars.FollowAllowed = true
        vars.ShieldActive = false
        vars.RowActive = false
        vars.FrontlineActive = false
        vars.CurrentFormasiTarget = client

        local humanoid, myRootPart
        local moving = false
        local lastTargetPos = nil
        local lastCheck = tick()

        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end

        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        local function moveSmooth(targetPos, lookAtPos)
            if not humanoid or not myRootPart then return end
            if moving then return end

            moving = true
            humanoid:MoveTo(targetPos)
            local finished = humanoid.MoveToFinished:Wait()
            moving = false

            if finished and lookAtPos then
                myRootPart.CFrame = CFrame.new(
                    myRootPart.Position,
                    Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z)
                )
            end
        end

        -- Lepas koneksi lama
        if vars.FollowConnection then
            pcall(function() vars.FollowConnection:Disconnect() end)
            vars.FollowConnection = nil
        end

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

        local function getAdaptiveOffset(distance)
            if distance < 4 then
                return distance + 2 -- mundur sedikit
            elseif distance > 15 then
                return distance - 3 -- kejar VIP
            end
            return distance
        end

        -- 🔹 Loop utama mengikuti
        vars.FollowConnection = RunService.Heartbeat:Connect(function(dt)
            if not vars.FollowAllowed or not client.Character then return end
            local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP or not myRootPart then return end

            -- Prediksi posisi VIP
            local targetVelocity = targetHRP.Velocity
            local predictTime = 0.4 -- waktu prediksi
            local predictedPos = targetHRP.Position + targetVelocity * predictTime

            local jarakIkut = tonumber(vars.JarakIkut) or 6
            local followSpacing = tonumber(vars.FollowSpacing) or 4
            local baseOffset = jarakIkut + (index - 1) * followSpacing

            local distance = (myRootPart.Position - targetHRP.Position).Magnitude
            local adaptiveOffset = getAdaptiveOffset(baseOffset)

            -- Cegah tabrakan antar bot
            local offsetSide = 0
            if index % 2 == 0 then offsetSide = 2 elseif index % 3 == 0 then offsetSide = -2 end

            local targetPos = predictedPos
                - targetHRP.CFrame.LookVector * adaptiveOffset
                + targetHRP.CFrame.RightVector * offsetSide

            -- Hanya update posisi jika perubahan signifikan
            if not lastTargetPos or (lastTargetPos - targetPos).Magnitude > 1 then
                moveSmooth(targetPos, predictedPos + targetHRP.CFrame.LookVector * 50)
                lastTargetPos = targetPos
            end

            -- Auto-reconnect bila lag
            if tick() - lastCheck > 10 then
                if not vars.FollowConnection.Connected then
                    warn("[Ikuti+] Reconnecting follow loop...")
                    vars.FollowConnection:Disconnect()
                    vars.FollowConnection = nil
                end
                lastCheck = tick()
            end
        end)

        print("[IKUTI+] Formasi adaptif aktif, target:", client.Name)
    end
}
