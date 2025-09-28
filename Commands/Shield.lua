-- Shield.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        -- Toggle Shield mode
        vars.ShieldActive = not vars.ShieldActive
        vars.FollowAllowed = false
        vars.RowActive = false
        vars.CurrentFormasiTarget = client

        -- Pastikan koneksi sebelumnya diputus
        if vars.FollowConnection then
            vars.FollowConnection:Disconnect()
            vars.FollowConnection = nil
        end

        -- Update Character references
        local humanoid, myRootPart, moving
        local function updateBotRefs()
            local character = vars.LocalPlayer.Character or vars.LocalPlayer.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end
        vars.LocalPlayer.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        -- MoveTo wrapper
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

        -- Heartbeat loop untuk Shield
        vars.FollowConnection = vars.RunService.Heartbeat:Connect(function()
            if not vars.ToggleAktif or not vars.ShieldActive then return end
            if not vars.CurrentFormasiTarget or not vars.CurrentFormasiTarget.Character then return end
            if not humanoid or not myRootPart then return end

            local targetHRP = vars.CurrentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- Tentukan urutan bot
            local botIds = {}
            for id, _ in pairs({
                ["8802945328"] = true,
                ["8802949363"] = true,
                ["8802939883"] = true,
                ["8802998147"] = true,
            }) do
                table.insert(botIds, tonumber(id))
            end
            table.sort(botIds)

            local index = 1
            for i, id in ipairs(botIds) do
                if id == vars.LocalPlayer.UserId then
                    index = i
                    break
                end
            end

            -- Hitung posisi Shield (depan, kiri, kanan, belakang VIP)
            local targetPos
            if index == 1 then
                targetPos = targetHRP.Position + targetHRP.CFrame.LookVector * vars.ShieldDistance
            elseif index == 2 then
                targetPos = targetHRP.Position - targetHRP.CFrame.RightVector * vars.ShieldDistance
            elseif index == 3 then
                targetPos = targetHRP.Position + targetHRP.CFrame.RightVector * vars.ShieldDistance
            elseif index == 4 then
                targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * vars.ShieldDistance
            end

            if targetPos then
                moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)
            end
        end)

        -- Notifikasi UI
        local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
        Library:Notify("Shield formation " .. (vars.ShieldActive and "Activated" or "Deactivated"), 3)

        print("[COMMAND] Shield formation:", vars.ShieldActive and "ON" or "OFF", "by", client and client.Name or "Unknown")
    end
}
