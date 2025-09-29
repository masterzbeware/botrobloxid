-- Ikuti.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        -- 🔹 Blok jika RockPaperMode aktif
        if vars.RockPaperModeActive then
            local channel = vars.TextChatService.TextChannels and vars.TextChatService.TextChannels.RBXGeneral
            if channel then
                pcall(function()
                    channel:SendAsync("Tidak bisa mengeksekusi Ikuti saat RockPaper Mode aktif!")
                end)
            end
            return
        end

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

        -- Putuskan koneksi lama
        if vars.FollowConnection then vars.FollowConnection:Disconnect() end

        vars.FollowConnection = RunService.Heartbeat:Connect(function()
            if not vars.FollowAllowed or not client.Character then return end
            local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            local jarakIkut = tonumber(vars.JarakIkut) or 5
            local followSpacing = tonumber(vars.FollowSpacing) or 2

            local orderedBots = {
                "8802945328",
                "8802949363",
                "8802939883",
                "8802998147",
            }

            local myUserId = tostring(player.UserId)
            local index = 1
            for i, uid in ipairs(orderedBots) do
                if uid == myUserId then
                    index = i
                    break
                end
            end

            local followPos = targetHRP.Position - targetHRP.CFrame.LookVector * (jarakIkut + (index - 1) * followSpacing)
            moveToPosition(followPos)
        end)

        print("[COMMAND] Bot following client:", client.Name)
    end
}
