-- Shield.lua (Shield formation + peringatan area VIP)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local RunService = vars.RunService or game:GetService("RunService")
        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local player = vars.LocalPlayer or Players.LocalPlayer

        -- Toggle shield mode
        vars.ShieldActive = not vars.ShieldActive
        vars.FollowAllowed = false
        vars.RowActive = false
        vars.CurrentFormasiTarget = client

        -- Disconnect previous loops
        if vars.FollowConnection then pcall(function() vars.FollowConnection:Disconnect() end) vars.FollowConnection = nil end
        if vars.ShieldConnection then pcall(function() vars.ShieldConnection:Disconnect() end) vars.ShieldConnection = nil end
        if vars.RowConnection then pcall(function() vars.RowConnection:Disconnect() end) vars.RowConnection = nil end

        local notifyLib = vars.Library or loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
        if not vars.ShieldActive then
            notifyLib:Notify("Shield formation Deactivated", 3)
            return
        end

        local shieldDistance = tonumber(vars.ShieldDistance) or 5
        local shieldSpacing  = tonumber(vars.ShieldSpacing) or 4

        local botMapping = vars.BotMapping or {
            ["8802945328"] = true,
            ["8802949363"] = true,
            ["8802939883"] = true,
            ["8802998147"] = true,
        }

        -- bot refs
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

            -- Tentukan posisi bot sesuai index
            local botIds = {}
            for idStr, _ in pairs(botMapping) do
                table.insert(botIds, tonumber(idStr))
            end
            table.sort(botIds)

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

            -- 🔹 Deteksi pemain lain di area VIP
            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= player and other ~= vars.CurrentFormasiTarget and not botMapping[tostring(other.UserId)] then
                    local char = other.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        local dist = (char.HumanoidRootPart.Position - targetHRP.Position).Magnitude
                        if dist <= shieldDistance + 1 then -- +1 buffer
                            -- chat peringatan global
                            local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
                            if channel then
                                pcall(function()
                                    channel:SendAsync("Harap menjauh ini Area VIP!")
                                end)
                            end
                        end
                    end
                end
            end
        end)

        notifyLib:Notify("Shield formation Activated", 3)
        print("[COMMAND] Shield activated by", client.Name, "distance:", shieldDistance, "spacing:", shieldSpacing)
    end
}
