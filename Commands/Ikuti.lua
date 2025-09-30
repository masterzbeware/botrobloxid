-- Ikuti.lua
-- Command !ikuti: Bot mengikuti pemain VIP, menghindari halangan & mencari jalan jika ada water

return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local RunService = vars.RunService
        local Players = game:GetService("Players")
        local PathfindingService = game:GetService("PathfindingService")
        local Workspace = game:GetService("Workspace")
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

        local function updateBotRefs()
            local character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myRootPart = character:WaitForChild("HumanoidRootPart")
        end

        player.CharacterAdded:Connect(updateBotRefs)
        updateBotRefs()

        -- Fungsi cek water di posisi
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

        local function moveToPosition(targetPos)
            if not humanoid or not myRootPart then return end
            if moving then return end
            if (myRootPart.Position - targetPos).Magnitude < 2 then return end

            moving = true

            local safeTarget = targetPos
            if isWater(safeTarget) then
                -- Geser target sementara jika air
                safeTarget = safeTarget + Vector3.new(0,0,3)
            end

            -- Pathfinding
            local path = PathfindingService:CreatePath({
                AgentRadius = 2,
                AgentHeight = 5,
                AgentCanJump = true,
                AgentJumpHeight = 10,
                AgentMaxSlope = 45,
            })

            path:ComputeAsync(myRootPart.Position, safeTarget)

            local waypoints = path:GetWaypoints()

            -- Jika ada waypoint di air, coba recompute dengan offset kecil
            for i, waypoint in ipairs(waypoints) do
                local wpPos = waypoint.Position
                if isWater(wpPos) then
                    -- Geser waypoint sedikit ke sisi kanan/kiri
                    wpPos = wpPos + Vector3.new(3,0,0)
                    path:ComputeAsync(myRootPart.Position, wpPos)
                    waypoints = path:GetWaypoints()
                    break
                end
            end

            -- Jalankan waypoint
            for _, waypoint in ipairs(waypoints) do
                if not vars.FollowAllowed then break end
                humanoid:MoveTo(waypoint.Position)
                local reached = humanoid.MoveToFinished:Wait()
                if not reached then break end
            end

            moving = false
        end

        -- Putuskan koneksi lama dulu
        if vars.FollowConnection then vars.FollowConnection:Disconnect() end

        -- 🔹 Heartbeat update
        if RunService.Heartbeat then
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

                -- Hitung posisi ikuti VIP
                local followPos = targetHRP.Position - targetHRP.CFrame.LookVector * (jarakIkut + (index - 1) * followSpacing)
                moveToPosition(followPos)
            end)
        else
            warn("[Ikuti] RunService.Heartbeat tidak tersedia!")
        end

        print("[COMMAND] Bot mengikuti client:", client.Name)
    end
}
