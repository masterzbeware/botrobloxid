-- Shield.lua (Shield formation + warning dengan delay + whitelist + kompatibel dengan Stop.lua)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local RunService = vars.RunService or game:GetService("RunService")
        local Players = game:GetService("Players")
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")
        local player = vars.LocalPlayer or Players.LocalPlayer

        vars.WhitelistTargets = vars.WhitelistTargets or {} -- pastikan ada whitelist
        vars.ShieldActive = vars.ShieldActive or false

        -- Ambil argumen dari perintah !shield
        local args = {}
        for word in msg:gmatch("%S+") do table.insert(args, word) end
        local targetNameOrUsername = args[2] -- !shield {name}

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
                warn("[Shield] Pemain '" .. targetNameOrUsername .. "' tidak ditemukan.")
                return
            end
        else
            targetPlayer = client -- fallback ke client jika tidak ada argumen
        end

        -- Toggle shield mode
        vars.ShieldActive = not vars.ShieldActive
        vars.FollowAllowed = false
        vars.RowActive = false
        vars.CurrentFormasiTarget = targetPlayer

        -- Disconnect previous Shield loop jika ada
        if vars.ShieldConnection then
            pcall(function() vars.ShieldConnection:Disconnect() end)
            vars.ShieldConnection = nil
        end

        local notifyLib = vars.Library or loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
        if not vars.ShieldActive then
            notifyLib:Notify("Shield formation Deactivated", 3)
            return
        end

        -- Ambil nilai formasi
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

        -- Timestamp terakhir chat
        local lastWarningTime = 0
        local warningDelay = 22 -- 1 menit

        local function moveToPosition(targetPos, lookAtPos)
            if not humanoid or not myRootPart then return end
            if moving then return end
            if (myRootPart.Position - targetPos).Magnitude < 2 then return end

            moving = true
            humanoid:MoveTo(targetPos)
            humanoid.MoveToFinished:Wait()
            moving = false

            if lookAtPos then
                myRootPart.CFrame = CFrame.new(myRootPart.Position, Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z))
            end
        end

        -- Shield loop
        vars.ShieldConnection = RunService.Heartbeat:Connect(function()
            if not vars.ToggleAktif or not vars.ShieldActive then return end
            if not vars.CurrentFormasiTarget or not vars.CurrentFormasiTarget.Character then return end
            if not humanoid or not myRootPart then return end

            local targetHRP = vars.CurrentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- Tentukan posisi Shield
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

            -- 🔹 Deteksi pemain lain mendekati VIP (hanya non-bot & non-whitelist)
            local now = tick()
            if now - lastWarningTime >= warningDelay then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= player and plr ~= vars.CurrentFormasiTarget then
                        local userIdStr = tostring(plr.UserId)
                        if not botMapping[userIdStr] and not vars.WhitelistTargets[userIdStr] then
                            local char = plr.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                local dist = (char.HumanoidRootPart.Position - targetHRP.Position).Magnitude
                                if dist <= shieldDistance then
                                    -- Kirim chat global peringatan
                                    local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
                                    if channel then
                                        pcall(function()
                                            channel:SendAsync(plr.Name .. " Harap menjauh dari area VIP!")
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
