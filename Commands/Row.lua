-- ✅ Row.lua (Complete with Position Handling)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local localPlayer = vars.LocalPlayer or Players.LocalPlayer
        vars.RowActive = not vars.RowActive
        vars.FollowAllowed = false
        vars.ShieldActive = false
        vars.CurrentFormasiTarget = client

        -- Notifikasi
        game.StarterGui:SetCore("SendNotification", {
            Title = "Formation Command",
            Text = (vars.BotIdentity or localPlayer.Name) .. " Row " .. (vars.RowActive and "Activated" or "Deactivated")
        })

        if not vars.RowActive then return end

        -- Pastikan reference
        local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        local myRootPart = character:WaitForChild("HumanoidRootPart")

        -- Helper move function
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
                myRootPart.CFrame = CFrame.new(myRootPart.Position, Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z))
            end
        end

        -- Jalankan loop posisi Row
        RunService.Heartbeat:Connect(function()
            if not vars.RowActive then return end
            if not vars.CurrentFormasiTarget or not vars.CurrentFormasiTarget.Character then return end

            local targetHRP = vars.CurrentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- Dapatkan urutan bot
            local botIds = {}
            for id, _ in pairs(vars.BotMapping or {}) do
                table.insert(botIds, tonumber(id))
            end
            table.sort(botIds)

            local index = 1
            for i, id in ipairs(botIds) do
                if id == localPlayer.UserId then
                    index = i
                    break
                end
            end

            -- Hitung posisi sesuai index
            local targetPos
            if index == 1 then
                targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * vars.FollowDistance
                            - targetHRP.CFrame.RightVector * vars.SideSpacing
            elseif index == 2 then
                targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * vars.FollowDistance
                            + targetHRP.CFrame.RightVector * vars.SideSpacing
            elseif index == 3 then
                targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * (vars.FollowDistance + vars.RowSpacing)
                            - targetHRP.CFrame.RightVector * vars.SideSpacing
            elseif index == 4 then
                targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * (vars.FollowDistance + vars.RowSpacing)
                            + targetHRP.CFrame.RightVector * vars.SideSpacing
            end

            if targetPos then
                moveToPosition(targetPos, targetHRP.Position) -- selalu menghadap VIP
            end
        end)
    end
}
