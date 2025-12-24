-- Shield.lua
-- Command !shield: Bot membentuk formasi perisai di sekitar VIP dengan sistem warning & whitelist

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local RunService = vars.RunService or game:GetService("RunService")
        local Players = game:GetService("Players")
        local player = vars.LocalPlayer or Players.LocalPlayer

        -- Sistem chat (disamakan dengan Say.lua)
        local TextChatService = game:GetService("TextChatService")
        local channel
        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        vars.WhitelistTargets = vars.WhitelistTargets or {}
        vars.ShieldActive = vars.ShieldActive or false

        -- Ambil argumen dari perintah !shield
        local args = {}
        for word in msg:gmatch("%S+") do table.insert(args, word) end
        local targetNameOrUsername = args[2]

        -- Cari pemain target berdasarkan DisplayName atau Username
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

        -- Putuskan koneksi lama jika ada
        if vars.ShieldConnection then
            pcall(function() vars.ShieldConnection:Disconnect() end)
            vars.ShieldConnection = nil
        end

        if not vars.ShieldActive then
            print("[Shield] Shield formation dinonaktifkan.")
            return
        end

        -- Nilai default jarak
        local shieldDistance = tonumber(vars.ShieldDistance) or 5
        local shieldSpacing  = tonumber(vars.ShieldSpacing) or 4

        -- Bot Mapping (dengan Bot5)
        local botMapping = vars.BotMapping or {
            ["10191476366"] = "Bot1",
            ["10191480511"] = "Bot2",
            ["10191462654"] = "Bot3",
            ["10190853828"] = "Bot4",
            ["10191023081"] = "Bot5",
            ["10191070611"] = "Bot6",
            ["10191489151"] = "Bot7",
            ["10191571531"] = "Bot8",
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

        -- Timestamp terakhir warning
        local lastWarningTime = 0
        local warningDelay = 22 -- detik

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

        -- Loop utama Shield
        vars.ShieldConnection = RunService.Heartbeat:Connect(function()
            if not vars.ToggleAktif or not vars.ShieldActive then return end
            if not vars.CurrentFormasiTarget or not vars.CurrentFormasiTarget.Character then return end
            if not humanoid or not myRootPart then return end

            local targetHRP = vars.CurrentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- Tentukan posisi bot berdasarkan urutan UserId
            local index = 1
            for i, id in ipairs(botIds) do
                if id == player.UserId then index = i break end
            end

            -- Posisi relatif tiap bot
            local cframe = targetHRP.CFrame
            local posMap = {
                [1] = cframe.Position + cframe.LookVector * shieldDistance,              -- depan VIP
                [2] = cframe.Position - cframe.RightVector * shieldSpacing,              -- kiri VIP
                [3] = cframe.Position + cframe.RightVector * shieldSpacing,              -- kanan VIP
                [4] = cframe.Position - cframe.LookVector * shieldDistance,              -- belakang VIP
                [5] = cframe.Position - cframe.LookVector * (shieldDistance + 2),       -- belakang tengah (Bot5)
            }

            local targetPos = posMap[index] or cframe.Position
            moveToPosition(targetPos, cframe.Position + cframe.LookVector * 50)

            -- Deteksi pemain lain terlalu dekat
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
                                    if channel then
                                        pcall(function()
                                            channel:SendAsync(plr.Name .. " harap menjauh dari area VIP!")
                                        end)
                                    else
                                        warn("Channel RBXGeneral tidak ditemukan!")
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

        print("[COMMAND] Shield activated by", client.Name, "target:", vars.CurrentFormasiTarget.Name, "distance:", shieldDistance, "spacing:", shieldSpacing)
    end
}
