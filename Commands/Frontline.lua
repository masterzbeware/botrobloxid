-- Frontline.lua (Frontline formation mirip Shield.lua tapi baris depan)
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local RunService = vars.RunService or game:GetService("RunService")
        local Players = game:GetService("Players")
        local player = vars.LocalPlayer or Players.LocalPlayer

        -- Ambil argumen dari perintah !frontline
        local args = {}
        for word in msg:gmatch("%S+") do table.insert(args, word) end
        local targetNameOrUsername = args[2] -- !frontline {name}

        -- Cari pemain target berdasarkan DisplayName atau Username
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
                warn("[Frontline] Pemain '" .. targetNameOrUsername .. "' tidak ditemukan.")
                return
            end
        else
            targetPlayer = client -- fallback ke client
        end

        -- Toggle frontline mode
        vars.FrontlineActive = not vars.FrontlineActive
        vars.ShieldActive = false
        vars.FollowAllowed = false
        vars.RowActive = false
        vars.CurrentFormasiTarget = targetPlayer

        -- Disconnect previous loops
        if vars.FollowConnection then pcall(function() vars.FollowConnection:Disconnect() end) vars.FollowConnection = nil end
        if vars.ShieldConnection then pcall(function() vars.ShieldConnection:Disconnect() end) vars.ShieldConnection = nil end
        if vars.RowConnection then pcall(function() vars.RowConnection:Disconnect() end) vars.RowConnection = nil end
        if vars.FrontlineConnection then pcall(function() vars.FrontlineConnection:Disconnect() end) vars.FrontlineConnection = nil end

        local notifyLib = vars.Library or loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
        if not vars.FrontlineActive then
            notifyLib:Notify("Frontline formation Deactivated", 3)
            return
        end

        -- Ambil nilai dari Bot.lua
        local shieldDistance = tonumber(vars.ShieldDistance) or 5
        local shieldSpacing  = tonumber(vars.ShieldSpacing) or 4

        -- 🔹 Bot list diperbarui (5 bot total)
        local botMapping = vars.BotMapping or {
            ["10191476366"] = "Bot1",
            ["10191480511"] = "Bot2",
            ["10191462654"] = "Bot3",
            ["10190853828"] = "Bot4",
            ["10191023081"] = "Bot5",
            ["10191070611"] = "Bot6",
            ["10191489151"] = "Bot7",
            ["10191571531"] = "Bot8",
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

        -- 🔹 Frontline loop (barisan lurus di depan target)
        vars.FrontlineConnection = RunService.Heartbeat:Connect(function()
            if not vars.ToggleAktif or not vars.FrontlineActive then return end
            if not vars.CurrentFormasiTarget or not vars.CurrentFormasiTarget.Character then return end
            if not humanoid or not myRootPart then return end

            local targetHRP = vars.CurrentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end

            -- 🔹 Tentukan posisi frontline (garis lurus di depan VIP)
            local index = 1
            for i, id in ipairs(botIds) do
                if id == player.UserId then
                    index = i
                    break
                end
            end

            -- 🔹 Bot diposisikan sejajar (kiri kanan) di depan VIP
            local offset = (index - ((#botIds + 1) / 2)) * shieldSpacing
            local forward = targetHRP.CFrame.LookVector
            local right   = targetHRP.CFrame.RightVector
            local targetPos = targetHRP.Position + forward * shieldDistance + right * offset

            moveToPosition(targetPos, targetHRP.Position + forward * 50)
        end)

        notifyLib:Notify("Frontline formation Activated for " .. vars.CurrentFormasiTarget.Name, 3)
        print("[COMMAND] Frontline activated by", client.Name, "targeting:", vars.CurrentFormasiTarget.Name, 
              "distance:", shieldDistance, "spacing:", shieldSpacing)
    end
}
