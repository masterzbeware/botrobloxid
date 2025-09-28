-- ✅ Row.lua (Row formation + auto chat sebelum & sesudah baris, tanpa emoji)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")

        local localPlayer = vars.LocalPlayer or Players.LocalPlayer
        vars.RowActive = not vars.RowActive
        vars.FollowAllowed = false
        vars.ShieldActive = false
        vars.CurrentFormasiTarget = client

        -- Reset flag announcement
        vars.RowFormationAnnounced = false

        -- Notifikasi lokal
        game.StarterGui:SetCore("SendNotification", {
            Title = "Formation Command",
            Text = (vars.BotIdentity or localPlayer.Name) .. " Row " .. (vars.RowActive and "Activated" or "Deactivated")
        })

        if vars.RowActive then
            -- 🔹 Chat global awal (sebelum barisan terbentuk)
            local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
            if channel then
                pcall(function()
                    channel:SendAsync((vars.BotIdentity or localPlayer.Name) .. ": Siap laksanakan!")
                end)
            end
        else
            return
        end

        -- Pastikan reference
        local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local myRootPart = character:WaitForChild("HumanoidRootPart")

        -- Default values jika vars kosong
        local followDistance = vars.JarakIkut or 5
        local rowSpacing     = vars.RowSpacing or 4
        local sideSpacing    = vars.SideSpacing or 4

        -- Helper move function
        local moving = false
        local function moveToPosition(targetPos, lookAtPos)
            if not humanoid or not myRootPart then return end
            if moving then return end

            local dist = (myRootPart.Position - targetPos).Magnitude
            if dist < 2 then return true end -- sudah sampai

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
            return (myRootPart.Position - targetPos).Magnitude < 2
        end

        -- Jalankan loop posisi Row
        RunService.Heartbeat:Connect(function()
            if not vars.RowActive then return end
            if not vars.CurrentFormasiTarget or not vars.CurrentFormasiTarget.Character then return end

            local targetHRP = vars.CurrentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- 🔹 Urutan fix Bot1 → Bot4
            local orderedBots = {
                "8802945328", -- Bot1 - XBODYGUARDVIP01
                "8802949363", -- Bot2 - XBODYGUARDVIP02
                "8802939883", -- Bot3 - XBODYGUARDVIP03
                "8802998147", -- Bot4 - XBODYGUARDVIP04
            }

            local myUserId = tostring(localPlayer.UserId)
            local index = 1
            for i, uid in ipairs(orderedBots) do
                if uid == myUserId then
                    index = i
                    break
                end
            end

            -- 🔹 Tentukan baris dan posisi samping
            local rowIndex = math.floor((index - 1) / 2)
            local sideIndex = (index - 1) % 2

            local baseBack = followDistance + (rowIndex * rowSpacing)
            local offsetSide = (sideIndex == 0 and -1 or 1) * sideSpacing

            local targetPos = targetHRP.Position
                - targetHRP.CFrame.LookVector * baseBack
                + targetHRP.CFrame.RightVector * offsetSide

            local reached = moveToPosition(targetPos, targetHRP.Position)

            -- 🔹 Jika semua bot sudah sampai barisan → umumkan sekali
            if reached and not vars.RowFormationAnnounced then
                vars.RowFormationAnnounced = true
                local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
                if channel then
                    pcall(function()
                        channel:SendAsync("Semua sudah masuk barisan!")
                    end)
                end
            end
        end)
    end
}
