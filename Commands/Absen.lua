-- Absen.lua
-- Bergantian maju ke depan Client dan lapor, kembali ke barisan belakang VIP

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local Players = game:GetService("Players")
        local RunService = vars.RunService or game:GetService("RunService")
        local player = vars.LocalPlayer

        local TextChatService = game:GetService("TextChatService")
        local channel

        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        if not RunService then
            warn("[Absen] RunService tidak tersedia!")
            return
        end

        -- Inisialisasi flag per bot
        vars.AbsenActive = vars.AbsenActive or {}
        local myId = tostring(player.UserId)
        if vars.AbsenActive[myId] then return end -- Skip jika bot ini sudah menjalankan absen
        vars.AbsenActive[myId] = true

        -- Bot Mapping (urutan absen)
        local orderedBots = {
            "8802945328", -- Bot1
            "8802949363", -- Bot2
            "8802939883", -- Bot3
            "8802998147", -- Bot4
            "8802991722", -- Bot5
        }

        local function getBotByUserId(userId)
            for _, plr in ipairs(Players:GetPlayers()) do
                if tostring(plr.UserId) == userId then
                    return plr
                end
            end
            return nil
        end

        -- Fungsi kirim chat
        local function sendChat(text)
            if channel then
                pcall(function()
                    channel:SendAsync(text)
                end)
            else
                warn("Channel RBXGeneral tidak ditemukan!")
            end
        end

        -- Ambil semua bot references
        local botRefs = {}
        for i, uid in ipairs(orderedBots) do
            local botPlayer = getBotByUserId(uid)
            if botPlayer and botPlayer.Character then
                local humanoid = botPlayer.Character:FindFirstChild("Humanoid")
                local hrp = botPlayer.Character:FindFirstChild("HumanoidRootPart")
                if humanoid and hrp then
                    botRefs[i] = {
                        index = i,
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
            vars.AbsenActive[myId] = nil
            return
        end

        -- Posisi default di belakang VIP (barisan)
        local defaultPositions = {}
        for i, bot in ipairs(botRefs) do
            defaultPositions[i] = targetHRP.Position
                - targetHRP.CFrame.LookVector * jarakBaris
                - targetHRP.CFrame.RightVector * ((i - 3) * spacing) -- Bot3 di tengah
        end

        -- Fungsi gerak bot ke posisi dan menghadap target
        local function moveTo(bot, targetPos, lookAtPos)
            if not bot.humanoid or not bot.hrp then return end
            bot.humanoid:MoveTo(targetPos)
            bot.humanoid.MoveToFinished:Wait()
            if lookAtPos then
                bot.hrp.CFrame = CFrame.new(bot.hrp.Position, Vector3.new(lookAtPos.X, bot.hrp.Position.Y, lookAtPos.Z))
            end
        end

        -- Coroutine absen bergantian maju → lapor → kembali ke barisan belakang VIP
        task.spawn(function()
            for _, bot in ipairs(botRefs) do
                if bot.player.UserId == player.UserId then
                    task.spawn(function()
                        -- Delay sesuai urutan (bergantian rapi)
                        task.wait((bot.index - 1) * 4)

                        -- Maju ke depan Client (+3 stud)
                        local forwardPos = targetHRP.Position + targetHRP.CFrame.LookVector * 3
                        moveTo(bot, forwardPos, targetHRP.Position)
                        task.wait(2)

                        -- Chat laporan
                        sendChat("Laporan Komandan, Barisan " .. bot.index .. " hadir")
                        task.wait(3)

                        -- Kembali ke posisi default belakang VIP
                        moveTo(bot, defaultPositions[bot.index], targetHRP.Position + targetHRP.CFrame.LookVector * 50)
                    end)
                else
                    -- Bot lain tetap di posisi default
                    moveTo(bot, defaultPositions[bot.index], targetHRP.Position + targetHRP.CFrame.LookVector * 50)
                end
            end
            vars.AbsenActive[myId] = nil
        end)

        print("[COMMAND] Absen bergantian aktif untuk bot", player.Name)
    end
}
