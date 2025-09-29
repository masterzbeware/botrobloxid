-- Topdown.lua (3-bodyguard Top-Down formation + warning)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local RunService = vars.RunService or game:GetService("RunService")
        local Players = game:GetService("Players")
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")
        local player = vars.LocalPlayer or Players.LocalPlayer

        -- Ambil argumen dari perintah !topdown
        local args = {}
        for word in msg:gmatch("%S+") do table.insert(args, word) end
        local targetNameOrUsername = args[2] -- !topdown {name}

        -- Cari pemain target berdasarkan DisplayName atau Username
        local targetPlayer = nil
        if targetNameOrUsername then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name:lower() == targetNameOrUsername:lower() or (plr.DisplayName and plr.DisplayName:lower() == targetNameOrUsername:lower()) then
                    targetPlayer = plr
                    break
                end
            end
            if not targetPlayer then
                warn("[Topdown] Pemain '" .. targetNameOrUsername .. "' tidak ditemukan.")
                return
            end
        else
            targetPlayer = client -- fallback ke client jika tidak ada argumen
        end

        -- Toggle mode Topdown
        vars.TopdownActive = not vars.TopdownActive
        vars.CurrentFormasiTarget = targetPlayer

        -- Disconnect previous loops
        if vars.TopdownConnection then pcall(function() vars.TopdownConnection:Disconnect() end) vars.TopdownConnection = nil end

        local notifyLib = vars.Library or loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
        if not vars.TopdownActive then
            notifyLib:Notify("Topdown formation Deactivated", 3)
            return
        end

        local shieldDistance = tonumber(vars.ShieldDistance) or 5
        local shieldSpacing  = tonumber(vars.ShieldSpacing) or 4

        local botMapping = vars.BotMapping or {
            ["8802945328"] = "Bot1 - XBODYGUARDVIP01",
            ["8802949363"] = "Bot2 - XBODYGUARDVIP02",
            ["8802939883"] = "Bot3 - XBODYGUARDVIP03",
        }

        local botIds = {}
        for idStr, _ in pairs(botMapping) do
            local n = tonumber(idStr)
            if n then table.insert(botIds, n) end
        end
        table.sort(botIds)

        -- Bot references
        local humanoid, myRootPart, moving
        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end
        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        -- Timestamp terakhir chat
        local lastWarningTime = 0
        local warningDelay = 18 -- detik

        local function moveToPosition(targetPos, lookAtPos)
            if not humanoid or not myRootPart then return end
            if moving then return end
            if (myRootPart.Position - targetPos).Magnitude < 1 then return end

            moving = true
            humanoid:MoveTo(targetPos)
            humanoid.MoveToFinished:Wait()
            moving = false

            if lookAtPos then
                myRootPart.CFrame = CFrame.new(myRootPart.Position, Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z))
            end
        end

        -- Topdown loop
        vars.TopdownConnection = RunService.Heartbeat:Connect(function()
            if not vars.ToggleAktif or not vars.TopdownActive then return end
            if not vars.CurrentFormasiTarget or not vars.CurrentFormasiTarget.Character then return end
            if not humanoid or not myRootPart then return end

            local targetHRP = vars.CurrentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- Tentukan posisi Topdown
            local index = 1
            for i, id in ipairs(botIds) do
                if id == player.UserId then index = i break end
            end

            local targetPos, lookAtPos
            if index == 1 then
                -- Bot1 depan VIP, membelakangi VIP tapi menghadap ke depan
                targetPos = targetHRP.Position + targetHRP.CFrame.LookVector * shieldDistance
                lookAtPos = targetPos + targetHRP.CFrame.LookVector * 50
            elseif index == 2 then
                -- Bot2 kanan belakang VIP
                targetPos = targetHRP.Position - targetHRP.CFrame.RightVector * shieldSpacing - targetHRP.CFrame.LookVector * (shieldDistance / 2)
                lookAtPos = targetPos + targetHRP.CFrame.LookVector * 50
            elseif index == 3 then
                -- Bot3 kiri belakang VIP
                targetPos = targetHRP.Position + targetHRP.CFrame.RightVector * shieldSpacing - targetHRP.CFrame.LookVector * (shieldDistance / 2)
                lookAtPos = targetPos + targetHRP.CFrame.LookVector * 50
            else
                -- fallback
                targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * shieldDistance
                lookAtPos = targetPos + targetHRP.CFrame.LookVector * 50
            end

            moveToPosition(targetPos, lookAtPos)

            -- 🔹 Deteksi pemain lain mendekati VIP (hanya non-bot)
            local now = tick()
            if now - lastWarningTime >= warningDelay then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= player and plr ~= vars.CurrentFormasiTarget then
                        local userIdStr = tostring(plr.UserId)
                        if not botMapping[userIdStr] then  -- hanya pemain non-bot
                            local char = plr.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                local dist = (char.HumanoidRootPart.Position - targetHRP.Position).Magnitude
                                if dist <= shieldDistance then
                                    local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
                                    if channel then
                                        pcall(function()
                                            channel:SendAsync(plr.Name .. " Harap menjauh ini Area VIP!")
                                        end)
                                    end
                                    lastWarningTime = now
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end)

        notifyLib:Notify("Topdown formation Activated for " .. vars.CurrentFormasiTarget.Name, 3)
        print("[COMMAND] Topdown activated by", client.Name, "targeting:", vars.CurrentFormasiTarget.Name)
    end
}
