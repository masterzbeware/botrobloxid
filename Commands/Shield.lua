-- Shield.lua (Shield formation + warning berlapis)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local RunService = vars.RunService or game:GetService("RunService")
        local Players = game:GetService("Players")
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")
        local player = vars.LocalPlayer or Players.LocalPlayer

        -- Ambil argumen dari perintah !shield
        local args = {}
        for word in msg:gmatch("%S+") do table.insert(args, word) end
        local targetNameOrUsername = args[2] -- !shield {name}

        -- Cari pemain target
        local targetPlayer = nil
        if targetNameOrUsername then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name:lower() == targetNameOrUsername:lower() 
                or (plr.DisplayName and plr.DisplayName:lower() == targetNameOrUsername:lower()) then
                    targetPlayer = plr
                    break
                end
            end
            if not targetPlayer then
                warn("[Shield] Pemain '" .. targetNameOrUsername .. "' tidak ditemukan.")
                return
            end
        else
            targetPlayer = client
        end

        -- Toggle shield mode
        vars.ShieldActive = not vars.ShieldActive
        vars.FollowAllowed = false
        vars.RowActive = false
        vars.CurrentFormasiTarget = targetPlayer

        -- Disconnect loops lama
        if vars.FollowConnection then pcall(function() vars.FollowConnection:Disconnect() end) vars.FollowConnection = nil end
        if vars.ShieldConnection then pcall(function() vars.ShieldConnection:Disconnect() end) vars.ShieldConnection = nil end
        if vars.RowConnection then pcall(function() vars.RowConnection:Disconnect() end) vars.RowConnection = nil end

        local notifyLib = vars.Library or loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
        if not vars.ShieldActive then
            notifyLib:Notify("Shield formation Deactivated", 3)
            return
        end

        -- Ambil nilai dari Bot.lua
        local shieldDistance = tonumber(vars.ShieldDistance) or 5
        local shieldSpacing  = tonumber(vars.ShieldSpacing) or 4

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

        -- Bot references
        local humanoid, myRootPart, moving
        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end
        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        -- Waktu & warning tracking
        local lastWarningTime = 0
        local warningDelay = 15 -- detik cooldown antar warning
        local playerWarnings = {} -- simpan jumlah warning per player

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

        -- Pesan warning per tingkat
        local warningMessages = {
            [1] = "Harap menjauh ini Area Vip!",
            [2] = "Peringatan kedua! Jangan mendekati VIP!",
            [3] = "Peringatan terakhir! Segera menjauh dari VIP!",
        }

        -- Shield loop
        vars.ShieldConnection = RunService.Heartbeat:Connect(function()
            if not vars.ToggleAktif or not vars.ShieldActive then return end
            if not vars.CurrentFormasiTarget or not vars.CurrentFormasiTarget.Character then return end
            if not humanoid or not myRootPart then return end

            local targetHRP = vars.CurrentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- Posisi shield sesuai index bot
            local index = 1
            for i, id in ipairs(botIds) do
                if id == player.UserId then index = i break end
            end

            local targetPos
            if index == 1 then
                targetPos = targetHRP.Position + targetHRP.CFrame.LookVector * shieldDistance
            elseif index == 2 then
                targetPos = targetHRP.Position - targetHRP.CFrame.RightVector * shieldSpacing
            elseif index == 3 then
                targetPos = targetHRP.Position + targetHRP.CFrame.RightVector * shieldSpacing
            elseif index == 4 then
                targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * shieldDistance
            else
                targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * shieldDistance
            end

            moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)

            -- Deteksi pemain lain mendekat
            local now = tick()
            if now - lastWarningTime >= warningDelay then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= player and plr ~= vars.CurrentFormasiTarget then
                        local userIdStr = tostring(plr.UserId)
                        if not botMapping[userIdStr] then
                            local char = plr.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                local dist = (char.HumanoidRootPart.Position - targetHRP.Position).Magnitude
                                if dist <= shieldDistance then
                                    -- Hitung warning player
                                    playerWarnings[plr.UserId] = (playerWarnings[plr.UserId] or 0) + 1
                                    local warnCount = playerWarnings[plr.UserId]

                                    -- Pilih pesan
                                    local msgToSend = warningMessages[warnCount] or warningMessages[3]

                                    local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
                                    if channel then
                                        pcall(function()
                                            channel:SendAsync(plr.Name .. " " .. msgToSend)
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

        notifyLib:Notify("Shield formation Activated for " .. vars.CurrentFormasiTarget.Name, 3)
        print("[COMMAND] Shield activated by", client.Name, "targeting:", vars.CurrentFormasiTarget.Name, "distance:", shieldDistance, "spacing:", shieldSpacing)
    end
}
