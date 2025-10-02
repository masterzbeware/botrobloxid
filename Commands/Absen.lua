-- Absen.lua (revisi maju ke depan Client)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local Players = game:GetService("Players")
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")
        local player = vars.LocalPlayer

        if not RunService then
            warn("[Absen] RunService tidak tersedia!")
            return
        end

        vars.AbsenActive = true

        local humanoid, myRootPart, moving
        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end
        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        local function sendChat(text)
            if channel then
                pcall(function() channel:SendAsync(text) end)
            end
        end

        -- Bot Mapping untuk urutan lapor
        local orderedBots = {
            "8802945328", "8802949363", "8802939883", "8802998147"
        }

        local myUserId = tostring(player.UserId)
        local index = 1
        for i, uid in ipairs(orderedBots) do
            if uid == myUserId then index = i break end
        end

        local targetHRP = client.Character and client.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then
            warn("[Absen] Client belum siap!")
            return
        end

        local jarakBaris = tonumber(vars.JarakIkut) or 6
        local spacing = tonumber(vars.FollowSpacing) or 4
        local defaultPos = targetHRP.Position - targetHRP.CFrame.LookVector * jarakBaris - targetHRP.CFrame.RightVector * ((index-1) * spacing)

        task.spawn(function()
            -- Pindah ke depan VIP (+LookVector 3 stud)
            local forwardPos = targetHRP.Position + targetHRP.CFrame.LookVector * 3
            moveToPosition = function(targetPos, lookAtPos)
                if not humanoid or not myRootPart then return end
                if moving then return end
                moving = true
                humanoid:MoveTo(targetPos)
                humanoid.MoveToFinished:Wait()
                moving = false
                if lookAtPos then
                    myRootPart.CFrame = CFrame.new(myRootPart.Position, Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z))
                end
            end

            moveToPosition(forwardPos, targetHRP.Position)
            task.wait(1) -- tunggu sebentar

            -- Kirim chat
            sendChat("Laporan Komandan, Barisan " .. index .. " hadir")
            task.wait(3)

            -- Kembali ke posisi default
            moveToPosition(defaultPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)

            vars.AbsenActive = false
        end)

        print("[COMMAND] Absen aktif, Bot barisan:", index)
    end
}
