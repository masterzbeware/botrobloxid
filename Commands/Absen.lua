-- Absen.lua (bergantian maju ke depan Client dan lapor, kembali ke barisan belakang VIP)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local Players = game:GetService("Players")
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        if not RunService then
            warn("[Absen] RunService tidak tersedia!")
            return
        end

        vars.AbsenActive = true

        local orderedBots = {
            "8802945328", -- Bot1
            "8802949363", -- Bot2
            "8802939883", -- Bot3
            "8802998147", -- Bot4
        }

        local function getBotByUserId(userId)
            for _, plr in ipairs(Players:GetPlayers()) do
                if tostring(plr.UserId) == userId then
                    return plr
                end
            end
            return nil
        end

        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        local function sendChat(botIndex)
            if channel then
                pcall(function()
                    channel:SendAsync("Laporan Komandan, Barisan " .. botIndex .. " hadir")
                end)
            end
        end

        local botRefs = {}
        for i, uid in ipairs(orderedBots) do
            local botPlayer = getBotByUserId(uid)
            if botPlayer and botPlayer.Character then
                local humanoid = botPlayer.Character:FindFirstChild("Humanoid")
                local hrp = botPlayer.Character:FindFirstChild("HumanoidRootPart")
                if humanoid and hrp then
                    botRefs[i] = {
                        player = botPlayer,
                        humanoid = humanoid,
                        hrp = hrp
                    }
                end
            end
        end

        local jarakBaris = tonumber(vars.JarakIkut) or 6
        local spacing = tonumber(vars.FollowSpacing) or 4
        local targetHRP = client.Character and client.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then
            warn("[Absen] Client belum siap!")
            return
        end

        local function moveTo(bot, targetPos, lookAtPos)
            if not bot.humanoid or not bot.hrp then return end
            bot.humanoid:MoveTo(targetPos)
            bot.humanoid.MoveToFinished:Wait()
            if lookAtPos then
                bot.hrp.CFrame = CFrame.new(bot.hrp.Position, Vector3.new(lookAtPos.X, bot.hrp.Position.Y, lookAtPos.Z))
            end
        end

        -- Coroutine absen bergantian
        task.spawn(function()
            for i, bot in ipairs(botRefs) do
                -- Maju ke depan Client (+3 stud)
                local forwardPos = targetHRP.Position + targetHRP.CFrame.LookVector * 3
                moveTo(bot, forwardPos, targetHRP.Position)
                task.wait(0.5)

                -- Kirim chat hanya bot yang maju sekarang
                sendChat(i)
                task.wait(1)

                -- Kembali ke posisi barisan belakang VIP (Ikuti.lua style)
                local backOffset = jarakBaris + (i-1) * spacing
                local behindPos = targetHRP.Position - targetHRP.CFrame.LookVector * backOffset
                moveTo(bot, behindPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)
                task.wait(0.5)
            end
            vars.AbsenActive = false
        end)

        print("[COMMAND] Absen bergantian aktif untuk semua bot")
    end
}
