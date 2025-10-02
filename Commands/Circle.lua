-- Circle.lua
-- Command !circlemove: Bot mengelilingi VIP, menghadap ke depan, jalan normal

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local RunService = vars.RunService or game:GetService("RunService")
        local Players = game:GetService("Players")
        local player = vars.LocalPlayer or Players.LocalPlayer

        -- Ambil argumen !circlemove {name}
        local args = {}
        for word in msg:gmatch("%S+") do table.insert(args, word) end
        local targetNameOrUsername = args[2]

        -- Cari target
        local targetPlayer = nil
        if targetNameOrUsername then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name:lower() == targetNameOrUsername:lower() or
                   (plr.DisplayName and plr.DisplayName:lower() == targetNameOrUsername:lower()) then
                    targetPlayer = plr
                    break
                end
            end
            if not targetPlayer then
                warn("[CircleMove] Pemain '" .. targetNameOrUsername .. "' tidak ditemukan.")
                return
            end
        else
            targetPlayer = client
        end

        -- Toggle mode
        vars.CircleMoveActive = not vars.CircleMoveActive
        vars.FollowAllowed = false
        vars.RowActive = false
        vars.ShieldActive = false
        vars.FrontlineActive = false
        vars.CurrentFormasiTarget = targetPlayer

        -- Disconnect loop lama
        if vars.CircleMoveConnection then
            pcall(function() vars.CircleMoveConnection:Disconnect() end)
            vars.CircleMoveConnection = nil
        end

        if not vars.CircleMoveActive then
            print("[CircleMove] Deactivated")
            return
        end

        -- Config
        local radius = tonumber(vars.CircleRadius) or 6
        local speed  = tonumber(vars.CircleSpeed) or 1 -- rotasi per detik

        -- Bot mapping
        local botMapping = vars.BotMapping or {
            ["8802945328"] = "Bot1",
            ["8802949363"] = "Bot2",
            ["8802939883"] = "Bot3",
            ["8802998147"] = "Bot4",
        }

        local botIds = {}
        for idStr, _ in pairs(botMapping) do
            local n = tonumber(idStr)
            if n then table.insert(botIds, n) end
        end
        table.sort(botIds)

        -- Bot references
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
            if (myRootPart.Position - targetPos).Magnitude < 0.5 then return end

            moving = true
            humanoid:MoveTo(targetPos)
            humanoid.MoveToFinished:Wait()
            moving = false
        end

        -- 🔹 Circle loop
        local startTime = tick()
        vars.CircleMoveConnection = RunService.Heartbeat:Connect(function()
            if not vars.CircleMoveActive or not vars.CurrentFormasiTarget or not vars.CurrentFormasiTarget.Character then return end
            if not humanoid or not myRootPart then return end

            local targetHRP = vars.CurrentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- Index bot
            local index = 1
            for i, id in ipairs(botIds) do
                if id == player.UserId then index = i break end
            end

            -- Tentukan posisi mengelilingi VIP (tetap rapi)
            local totalBots = #botIds
            local angle = ((tick() - startTime) * speed + (index-1)/totalBots*math.pi*2) % (math.pi*2)
            local offset = Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
            local targetPos = targetHRP.Position + offset

            -- Jalan normal ke posisi target (MoveTo)
            moveToPosition(targetPos)
            -- Tidak mengubah CFrame, jadi menghadap default (depan global)
        end)

        print("[CircleMove] Activated around", vars.CurrentFormasiTarget.Name)
    end
}
