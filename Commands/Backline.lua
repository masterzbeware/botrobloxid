return {
    Execute = function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        local humanoid
        local myHRP
        local backlining = false
        local targetPlayer = nil
        local backlineConnection = nil

        local adminBacklineDistance = 6
        local defaultBotBacklineDistance = 6
        local formationSpacing = 3

        local botOrder = {
            "11611503633", "11611534165", "11611567975",
            "11611562042", "11611591921", "11122806815",
            "11122806817", "11122687468", "11122854402",
            "11641280895", "11641342530",
        }

        local function updateCharacter()
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myHRP = character:WaitForChild("HumanoidRootPart")
            humanoid.AutoRotate = true
        end

        updateCharacter()

        local function getMyIndex()
            local id = tostring(LocalPlayer.UserId)
            for index, userId in ipairs(botOrder) do
                if userId == id then return index end
            end
        end

        local function stopBackline()
            backlining = false
            targetPlayer = nil

            if backlineConnection then
                backlineConnection:Disconnect()
                backlineConnection = nil
            end

            if humanoid then
                humanoid.AutoRotate = true
            end
        end

        _G.BotVars.ModeControllers.backline = stopBackline

        local function stopOtherModes()
            for modeName, controller in pairs(_G.BotVars.ModeControllers) do
                if modeName ~= "backline" and type(controller) == "function" then
                    pcall(controller)
                end
            end
        end

        local function findPlayerByName(name)
            if not name then return nil end
            name = name:lower()

            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower() == name or player.DisplayName:lower() == name then
                    return player
                end
            end

            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower():sub(1, #name) == name
                    or player.DisplayName:lower():sub(1, #name) == name then
                    return player
                end
            end
        end

        local function startBackline(target)
            stopBackline()
            targetPlayer = target
            if not targetPlayer then return end

            updateCharacter()

            local myIndex = getMyIndex()
            if not myIndex then return end

            backlining = true
            _G.BotVars.ActiveMode = "backline"
            stopOtherModes()

            backlineConnection = RunService.Heartbeat:Connect(function()
                if not backlining then return end

                local targetCharacter = targetPlayer and targetPlayer.Character
                local targetHRP = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
                if not targetHRP then return end

                local character = LocalPlayer.Character
                myHRP = character and character:FindFirstChild("HumanoidRootPart")
                humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if not myHRP or not humanoid then return end

                local distance = targetPlayer == LocalPlayer
                    and adminBacklineDistance
                    or defaultBotBacklineDistance

                local specialDistance = Distance:GetDistance(
                    tostring(LocalPlayer.UserId),
                    tostring(targetPlayer.UserId)
                )

                if specialDistance then
                    distance = specialDistance
                end

                -- Berbalik dari Frontline:
                -- bot berada di belakang Player/Admin.
                local targetPosition =
                    targetHRP.Position
                    - targetHRP.CFrame.LookVector
                    * (distance + ((myIndex - 1) * formationSpacing))

                if (myHRP.Position - targetPosition).Magnitude > 1.5 then
                    humanoid.AutoRotate = true
                    humanoid:MoveTo(targetPosition)
                    return
                end

                humanoid.AutoRotate = false

                -- Bot menghadap arah yang sama dengan Player/Admin.
                local rotation = targetHRP.CFrame - targetHRP.Position
                myHRP.CFrame = CFrame.new(myHRP.Position) * rotation
            end)
        end

        local function handleCommand(message, sender)
            if not message or not sender then return end

            local isAdmin = false
            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)
            if not isAdmin then return end

            local lower = message:lower():gsub("^%s+", ""):gsub("%s+$", "")

            if lower == "!backline" then
                startBackline(sender)
                return
            end

            local targetName = lower:match("^!backline%s+(.+)$")
            if targetName then
                local target = findPlayerByName(targetName)
                if target then startBackline(target) end
                return
            end

            if lower == "!stop" or lower == "!unbackline" then
                _G.BotVars.ActiveMode = nil
                stopBackline()
            end
        end

        local channel = TextChatService.TextChannels
            and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

        if channel then
            channel.OnIncomingMessage = function(message)
                local userId = message.TextSource and message.TextSource.UserId
                local sender = userId and Players:GetPlayerByUserId(userId)
                if sender then handleCommand(message.Text, sender) end
            end
        end

        local connectedPlayers = {}

        local function connectPlayerChat(player)
            if connectedPlayers[player] then return end
            connectedPlayers[player] = true

            player.Chatted:Connect(function(message)
                handleCommand(message, player)
            end)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayerChat(player)
        end

        Players.PlayerAdded:Connect(connectPlayerChat)

        Players.PlayerRemoving:Connect(function(player)
            connectedPlayers[player] = nil
        end)

        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            updateCharacter()

            if _G.BotVars.ActiveMode == "backline" and targetPlayer then
                local savedTarget = targetPlayer
                task.wait(0.2)
                if _G.BotVars.ActiveMode == "backline" then
                    startBackline(savedTarget)
                end
            end
        end)

        return {
            Execute = function()
                return true
            end
        }
    end
}
