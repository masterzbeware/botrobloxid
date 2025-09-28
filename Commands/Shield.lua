-- ✅ Shield.lua (Shield formation + warning ke pemain lain)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")

        local player = vars.LocalPlayer or Players.LocalPlayer
        vars.ShieldActive = not vars.ShieldActive
        vars.FollowAllowed = false
        vars.RowActive = false
        vars.CurrentFormasiTarget = client

        -- Flag untuk delay warning
        vars.LastShieldWarning = 0

        -- Notifikasi lokal
        game.StarterGui:SetCore("SendNotification", {
            Title = "Formation Command",
            Text = "Shield " .. (vars.ShieldActive and "Activated" or "Deactivated")
        })

        if not vars.ShieldActive then return end

        -- Pastikan reference
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local myRootPart = character:WaitForChild("HumanoidRootPart")

        -- Ambil jarak & spacing dari vars
        local shieldDistance = tonumber(vars.ShieldDistance) or 5
        local shieldSpacing  = tonumber(vars.ShieldSpacing) or 4

        -- Helper move
        local moving = false
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

        -- Jalankan loop Shield
        RunService.Heartbeat:Connect(function()
            if not vars.ShieldActive then return end
            if not vars.CurrentFormasiTarget or not vars.CurrentFormasiTarget.Character then return end

            local targetHRP = vars.CurrentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- 🔹 Urutan fix Bot1 → Bot4
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

            -- 🔹 Hitung posisi shield
            local targetPos
            if index == 1 then
                targetPos = targetHRP.Position + targetHRP.CFrame.LookVector * shieldDistance
            elseif index == 2 then
                targetPos = targetHRP.Position - targetHRP.CFrame.RightVector * shieldSpacing
            elseif index == 3 then
                targetPos = targetHRP.Position + targetHRP.CFrame.RightVector * shieldSpacing
            elseif index == 4 then
                targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * shieldDistance
            end

            if targetPos then
                moveToPosition(targetPos, targetHRP.Position)
            end

            -- 🔹 Deteksi pemain lain yang terlalu dekat VIP
            local now = tick()
            if now - (vars.LastShieldWarning or 0) > 5 then -- kasih delay 5 detik
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= player and plr ~= vars.CurrentFormasiTarget and plr.Character then
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and (hrp.Position - targetHRP.Position).Magnitude < 8 then
                            local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
                            if channel then
                                pcall(function()
                                    channel:SendAsync("Harap menjauh ini Area Vip!")
                                end)
                            end
                            vars.LastShieldWarning = now
                            break
                        end
                    end
                end
            end
        end)
    end
}
