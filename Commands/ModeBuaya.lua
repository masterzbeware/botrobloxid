return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        if not RunService then
            warn("[ModeBuaya] RunService tidak tersedia!")
            return
        end

        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if not channel then
            warn("[ModeBuaya] Channel RBXGeneral tidak ditemukan!")
        end

        local targetName = msg:match("!modebuaya%s+(.+)")
        if not targetName then
            warn("[ModeBuaya] Gunakan format: !modebuaya {DisplayName/Username}")
            return
        end

        local targetPlayer
        for _, p in ipairs(game.Players:GetPlayers()) do
            if p.DisplayName:lower() == targetName:lower() or p.Name:lower() == targetName:lower() then
                targetPlayer = p
                break
            end
        end

        if not targetPlayer then
            warn("[ModeBuaya] Player '" .. targetName .. "' tidak ditemukan!")
            return
        end

        local chatList = {
            "Aku janji, {name}, aku akan setia.",
            "Kiw Kiw {name}",
            "Sayang sini {name}",
            "Ih kamu {name} gemes banget",
            "Lucu banget kamu {name}",
            "Jangan pergi ya {name}",
            "Aku rindu sama kamu {name}"
        }

        local unusedChatList = {}
        for _, v in ipairs(chatList) do
            table.insert(unusedChatList, v)
        end

        vars.FollowAllowed = true
        vars.ShieldActive = false
        vars.RowActive = false
        vars.FrontlineActive = false
        vars.CurrentFormasiTarget = targetPlayer

        local humanoid
        local myRootPart
        local moving

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

        if vars.FollowConnection then pcall(function() vars.FollowConnection:Disconnect() end) vars.FollowConnection = nil end
        if vars.ModeBuayaChatConnection then pcall(function() vars.ModeBuayaChatConnection:Disconnect() end) vars.ModeBuayaChatConnection = nil end

        vars.FollowConnection = RunService.Heartbeat:Connect(function()
            if not vars.FollowAllowed then return end
            vars.AbsenActive = vars.AbsenActive or {}
            local myId = tostring(player.UserId)
            if vars.AbsenActive[myId] then return end

            if not targetPlayer or not targetPlayer.Character then return end
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            local jarakIkut = tonumber(vars.JarakIkut) or 6
            local followSpacing = tonumber(vars.FollowSpacing) or 4

            local orderedBots = {
                "8802945328",
                "8802949363",
                "8802939883",
                "8802998147",
                "8802991722"
            }

            local myUserId = tostring(player.UserId)
            local index = 1
            for i, uid in ipairs(orderedBots) do
                if uid == myUserId then
                    index = i
                    break
                end
            end

            local backOffset = jarakIkut + (index - 1) * followSpacing
            local targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * backOffset

            moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)
        end)

        task.spawn(function()
            while vars.FollowAllowed and targetPlayer and targetPlayer.Parent and channel do
                local name = targetPlayer.DisplayName or targetPlayer.Name

                if #unusedChatList == 0 then
                    for _, v in ipairs(chatList) do
                        table.insert(unusedChatList, v)
                    end
                end

                local idx = math.random(1, #unusedChatList)
                local message = unusedChatList[idx]:gsub("{name}", name)
                table.remove(unusedChatList, idx)

                pcall(function() channel:SendAsync(message) end)

                task.wait(4)
                task.wait(20)
            end
        end)
    end
}
