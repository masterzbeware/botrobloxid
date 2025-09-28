-- Shield.lua (fixed)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local RunService = vars.RunService or game:GetService("RunService")
        local player = vars.LocalPlayer or game:GetService("Players").LocalPlayer

        -- Toggle shield mode
        vars.ShieldActive = not vars.ShieldActive
        vars.FollowAllowed = false
        vars.RowActive = false
        vars.CurrentFormasiTarget = client

        -- Disconnect any previous connection used by follow/shield/row
        if vars.FollowConnection then
            pcall(function() vars.FollowConnection:Disconnect() end)
            vars.FollowConnection = nil
        end
        if vars.ShieldConnection then
            pcall(function() vars.ShieldConnection:Disconnect() end)
            vars.ShieldConnection = nil
        end
        if vars.RowConnection then
            pcall(function() vars.RowConnection:Disconnect() end)
            vars.RowConnection = nil
        end

        -- If we just turned shield OFF, notify and return
        local notifyLib = vars.Library or loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
        if not vars.ShieldActive then
            notifyLib:Notify("Shield formation Deactivated", 3)
            print("[COMMAND] Shield deactivated by", client and client.Name or "Unknown")
            return
        end

        -- Now we are activating shield: prepare numeric params with safe defaults
        local shieldDistance = tonumber(vars.ShieldDistance) or 5
        local sideSpacing = tonumber(vars.SideSpacing) or 4
        local shieldSpacing = tonumber(vars.ShieldSpacing) or 4

        -- Get bot mapping (use global if available, otherwise fallback)
        local botMapping = vars.BotMapping or {
            ["8802945328"] = "Bot1 - XBODYGUARDVIP01",
            ["8802949363"] = "Bot2 - XBODYGUARDVIP02",
            ["8802939883"] = "Bot3 - XBODYGUARDVIP03",
            ["8802998147"] = "Bot4 - XBODYGUARDVIP04",
        }

        -- Build sorted numeric ID list
        local botIds = {}
        for idStr, _ in pairs(botMapping) do
            local n = tonumber(idStr)
            if n then table.insert(botIds, n) end
        end
        table.sort(botIds)

        -- Character refs
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

            if lookAtPos and myRootPart then
                myRootPart.CFrame = CFrame.new(
                    myRootPart.Position,
                    Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z)
                )
            end
        end

        -- Heartbeat loop for shield formation
        vars.ShieldConnection = RunService.Heartbeat:Connect(function()
            -- safety checks
            if not vars.ToggleAktif then return end
            if not vars.ShieldActive then return end
            if not vars.CurrentFormasiTarget or not vars.CurrentFormasiTarget.Character then return end
            if not humanoid or not myRootPart then return end

            local targetHRP = vars.CurrentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- find this bot's index in sorted botIds
            local index = 1
            for i, id in ipairs(botIds) do
                if id == player.UserId then
                    index = i
                    break
                end
            end

            -- compute targetPos safely (note: shieldDistance is guaranteed numeric)
            local targetPos
            if index == 1 then
                targetPos = targetHRP.Position + (targetHRP.CFrame.LookVector * shieldDistance)
            elseif index == 2 then
                targetPos = targetHRP.Position - (targetHRP.CFrame.RightVector * shieldDistance)
            elseif index == 3 then
                targetPos = targetHRP.Position + (targetHRP.CFrame.RightVector * shieldDistance)
            elseif index == 4 then
                targetPos = targetHRP.Position - (targetHRP.CFrame.LookVector * shieldDistance)
            else
                -- fallback: place behind VIP if index unexpected
                targetPos = targetHRP.Position - (targetHRP.CFrame.LookVector * shieldDistance)
            end

            -- move and face toward VIP
            moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)
        end)

        notifyLib:Notify("Shield formation Activated", 3)
        print("[COMMAND] Shield activated by", client and client.Name or "Unknown", "distance:", shieldDistance)
    end
}
