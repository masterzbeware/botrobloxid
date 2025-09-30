-- Frontline.lua (Frontline formation simple, compatible with Stop.lua)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local RunService = vars.RunService or game:GetService("RunService")
        local Players = game:GetService("Players")
        local player = vars.LocalPlayer or Players.LocalPlayer

        -- Ambil argumen !frontline {name}
        local args = {}
        for word in msg:gmatch("%S+") do table.insert(args, word) end
        local targetNameOrUsername = args[2]

        -- Cari target
        local targetPlayer = nil
        if targetNameOrUsername then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name:lower() == targetNameOrUsername:lower() or
                   (plr.DisplayName and plr.DisplayName:lower() == targetNameOrUsername:lower()) then
                    targetPlayer = plr
                    break
                end
            end
            if not targetPlayer then
                warn("[Frontline] Pemain '" .. targetNameOrUsername .. "' tidak ditemukan.")
                return
            end
        else
            targetPlayer = client
        end

        -- Toggle mode
        vars.ShieldActive = not vars.ShieldActive
        vars.FollowAllowed = false
        vars.RowActive = false
        vars.CurrentFormasiTarget = targetPlayer

        -- Disconnect loop lama jika ada
        if vars.FollowConnection then pcall(function() vars.FollowConnection:Disconnect() end) vars.FollowConnection = nil end
        if vars.ShieldConnection then pcall(function() vars.ShieldConnection:Disconnect() end) vars.ShieldConnection = nil end
        if vars.RowConnection then pcall(function() vars.RowConnection:Disconnect() end) vars.RowConnection = nil end

        if not vars.ShieldActive then
            print("[Frontline] Deactivated")
            return
        end

        -- Config
        local shieldDistance = tonumber(vars.ShieldDistance) or 5
        local shieldSpacing  = tonumber(vars.ShieldSpacing) or 4

        -- Bot mapping
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

        -- References
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
            pcall(function()
                humanoid:MoveTo(targetPos)
                humanoid.MoveToFinished:Wait()
                if lookAtPos then
                    myRootPart.CFrame = CFrame.new(
                        myRootPart.Position,
                        Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z)
                    )
                end
            end)
            moving = false
        end

        -- 🔹 Frontline loop
        vars.ShieldConnection = RunService.Heartbeat:Connect(function()
            if not vars.ShieldActive then return end
            if not vars.CurrentFormasiTarget or not vars.CurrentFormasiTarget.Character then return end
            if not humanoid or not myRootPart then return end

            local targetHRP = vars.CurrentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- Cari index bot
            local index = 1
            for i, id in ipairs(botIds) do
                if id == player.UserId then index = i break end
            end

            -- Line formation di depan VIP
            local offset = (index - ((#botIds + 1) / 2)) * shieldSpacing
            local forward = targetHRP.CFrame.LookVector
            local right   = targetHRP.CFrame.RightVector
            local targetPos = targetHRP.Position + forward * shieldDistance + right * offset

            moveToPosition(targetPos, targetHRP.Position + forward * 50)
        end)

        print("[Frontline] Activated for", vars.CurrentFormasiTarget.Name)
    end
}
