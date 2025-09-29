-- Ikuti.lua (Perbaikan kompatibilitas dengan Topdown)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        if not RunService then
            warn("[Ikuti] RunService tidak tersedia!")
            return
        end

        -- Matikan semua mode lain
        vars.TopdownActive = false
        if vars.TopdownConnection then
            vars.TopdownConnection:Disconnect()
            vars.TopdownConnection = nil
        end
        vars.ShieldActive = false
        if vars.ShieldConnection then
            vars.ShieldConnection:Disconnect()
            vars.ShieldConnection = nil
        end
        vars.RowActive = false
        if vars.RowConnection then
            vars.RowConnection:Disconnect()
            vars.RowConnection = nil
        end

        vars.FollowAllowed = true
        vars.CurrentFormasiTarget = client

        local humanoid, myRootPart, moving

        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end

        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        local function moveToPosition(targetPos)
            if not humanoid or not myRootPart then return end
            if moving then return end
            if (myRootPart.Position - targetPos).Magnitude < 2 then return end

            moving = true
            humanoid:MoveTo(targetPos)
            humanoid.MoveToFinished:Wait()
            moving = false
        end

        -- Putuskan koneksi lama dulu
        if vars.FollowConnection then vars.FollowConnection:Disconnect() end

        vars.FollowConnection = RunService.Heartbeat:Connect(function()
            if not vars.FollowAllowed or not client.Character then return end
            local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            local jarakIkut = tonumber(vars.JarakIkut) or 5
            local followSpacing = tonumber(vars.FollowSpacing) or 2

            -- Urutan bot FIXED
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

            -- Hitung posisi ikuti VIP
            local followPos = targetHRP.Position - targetHRP.CFrame.LookVector * (jarakIkut + (index - 1) * followSpacing)
            moveToPosition(followPos)
        end)

        print("[COMMAND] Bot mengikuti client:", client.Name)
    end
}
