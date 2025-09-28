-- Ikuti.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        vars.FollowAllowed = true
        vars.ShieldActive = false
        vars.RowActive = false
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

        if vars.FollowConnection then vars.FollowConnection:Disconnect() end
        vars.FollowConnection = RunService.Heartbeat:Connect(function()
            if not vars.FollowAllowed or not client.Character then return end
            local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- Ambil nilai dari UI
            local jarakIkut = tonumber(vars.JarakIkut) or 5
            local followSpacing = tonumber(vars.FollowSpacing) or 2

            -- cari index bot
            local botMapping = vars.BotMapping or {
                ["8802945328"] = "Bot1 - XBODYGUARDVIP01",
                ["8802949363"] = "Bot2 - XBODYGUARDVIP02",
                ["8802939883"] = "Bot3 - XBODYGUARDVIP03",
                ["8802998147"] = "Bot4 - XBODYGUARDVIP04",
            }
            local botIds = {}
            for idStr, _ in pairs(botMapping) do
                local n = tonumber(idStr)
                if n then table.insert(botIds, n) end
            end
            table.sort(botIds)

            local index = 1
            for i, id in ipairs(botIds) do
                if id == player.UserId then index = i break end
            end

            -- posisi mengikuti VIP
            local followPos = targetHRP.Position - targetHRP.CFrame.LookVector * (jarakIkut + (index - 1) * followSpacing)
            moveToPosition(followPos)
        end)

        print("[COMMAND] Bot following client:", client.Name)
    end
}
