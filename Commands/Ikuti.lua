-- Ikuti.lua
-- Command !ikuti: Bot mengikuti pemain VIP dengan Water-aware Pathfinding

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local Players = vars.Players
        local Workspace = vars.Workspace
        local PathfindingService = vars.PathfindingService
        local player = vars.LocalPlayer

        if not RunService then
            warn("[Ikuti] RunService tidak tersedia!")
            return
        end

        vars.FollowAllowed = true
        vars.ShieldActive = false
        vars.RowActive = false
        vars.CurrentFormasiTarget = client

        local humanoid, myRootPart, moving

        -- Update references karakter
        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end

        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        -- Cek apakah posisi berada di water
        local function isWater(pos)
            local region = Region3.new(pos - Vector3.new(2,2,2), pos + Vector3.new(2,2,2))
            local parts = Workspace:FindPartsInRegion3(region, nil, 50)
            for _, part in ipairs(parts) do
                if part.Material == Enum.Material.Water then
                    return true
                end
            end
            return false
        end

        -- Fungsi move dengan Water-aware Pathfinding
        local function moveToPosition(targetPos)
            if not humanoid or not myRootPart then return end
            if moving then return end
            if (myRootPart.Position - targetPos).Magnitude < 2 then return end

            moving = true
            local maxAttempts = 5
            local attempt = 0
            local safePath = nil

            while attempt < maxAttempts do
                local path = PathfindingService:CreatePath({
                    AgentRadius = 2,
                    AgentHeight = 5,
                    AgentCanJump = true,
                    AgentJumpHeight = 10,
                    AgentMaxSlope = 45,
                })

                path:ComputeAsync(myRootPart.Position, targetPos)
                local waypoints = path:GetWaypoints()
                local hasWater = false
                for _, wp in ipairs(waypoints) do
                    if isWater(wp.Position) then
                        hasWater = true
                        break
                    end
                end

                if not hasWater then
                    safePath = path
                    break
                else
                    -- geser target sedikit ke samping untuk cari jalur aman
                    targetPos = targetPos + Vector3.new(2,0,2)
                    attempt = attempt + 1
                end
            end

            if not safePath then
                moving = false
                return
            end

            for _, waypoint in ipairs(safePath:GetWaypoints()) do
                humanoid:MoveTo(waypoint.Position)
                local reached = humanoid.MoveToFinished:Wait()
                if not reached or not vars.FollowAllowed then break end
            end

            moving = false
        end

        -- Putus koneksi lama
        if vars.FollowConnection then vars.FollowConnection:Disconnect() end

        -- Heartbeat update
        vars.FollowConnection = RunService.Heartbeat:Connect(function()
            if not vars.FollowAllowed or not client.Character then return end
            local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            local jarakIkut = tonumber(vars.JarakIkut) or 5
            local followSpacing = tonumber(vars.FollowSpacing) or 2

            -- Urutan bot FIXED
            local orderedBots = {
                "8802945328", -- Bot1
                "8802949363", -- Bot2
                "8802939883", -- Bot3
                "8802998147", -- Bot4
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

        print("[COMMAND] Bot mengikuti client:", client.Name)
    end
}
