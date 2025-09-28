-- Ikuti.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local player = vars.LocalPlayer

        -- reset flag
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

        -- heartbeat loop follow
        if vars.FollowConnection then vars.FollowConnection:Disconnect() end
        vars.FollowConnection = RunService.Heartbeat:Connect(function()
            if not vars.FollowAllowed then return end
            if not client.Character then return end
            local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            local behindPos = targetHRP.CFrame.Position - targetHRP.CFrame.LookVector * 5
            moveToPosition(behindPos)
        end)

        print("[COMMAND] Bot following client:", client.Name)
    end
}
