return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            return
        end

        ----------------------------------------------------------------
        -- GLOBAL MODE SYSTEM
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}

        ----------------------------------------------------------------
        -- LOAD ADMIN
        ----------------------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- LOAD DISTANCE
        ----------------------------------------------------------------

        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        local frontlining = false
        local targetPlayer = nil
        local frontlineConnection = nil

        ----------------------------------------------------------------
        -- FORMATION DISTANCE
        ----------------------------------------------------------------

        local adminFrontlineDistance = 6
        local defaultBotFrontlineDistance = 6

        -- Jarak antar bot.
        local formationSpacing = 3

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

        local botOrder = {
            "11611503633", -- Bot 1
            "11611591921", -- Bot 2
            "11611597741", -- Bot 3
            "11672413029", -- Bot 4
            "11122806815", -- Bot 5
            "11122806817", -- Bot 6
            "11122687468", -- Bot 7
            "11122854402", -- Bot 8
            "11774472805", -- Bot 9
            "11774494628", -- Bot 10
            "11775829997", -- Bot 11
            "11775843339", -- Bot 12
        }

        ----------------------------------------------------------------
        -- UPDATE CHARACTER
        ----------------------------------------------------------------

        local function updateCharacter()

            local character =
                LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

            humanoid =
                character:WaitForChild("Humanoid")

            myHRP =
                character:WaitForChild("HumanoidRootPart")

            humanoid.AutoRotate = true

        end

        updateCharacter()

        ----------------------------------------------------------------
        -- SEND CHAT
        ----------------------------------------------------------------

        local function sendChat(message)

            local success = false

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then

                    local ok = pcall(function()
                        channel:SendAsync(message)
                    end)

                    success = ok

                end
            end

            if not success then

                pcall(function()

                    local chatEvents =
                        ReplicatedStorage:FindFirstChild(
                            "DefaultChatSystemChatEvents"
                        )

                    if chatEvents then

                        local sayMessageRequest =
                            chatEvents:FindFirstChild(
                                "SayMessageRequest"
                            )

                        if sayMessageRequest then

                            sayMessageRequest:FireServer(
                                message,
                                "All"
                            )

                        end

                    end

                end)

            end

        end

        ----------------------------------------------------------------
        -- STOP FRONTLINE
        ----------------------------------------------------------------

        local function stopFrontline()

            frontlining = false
            targetPlayer = nil

            if frontlineConnection then
                frontlineConnection:Disconnect()
                frontlineConnection = nil
            end

            if humanoid then
                humanoid.AutoRotate = true
            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.frontline =
            stopFrontline

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "frontline"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

            end

        end

        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayerByName(name)

            if not name or name == "" then
                return nil
            end

            name = name:lower()

            -- Exact username atau display name.
            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            -- Username prefix.
            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower():sub(
                    1,
                    #name
                ) == name then

                    return player

                end

            end

            -- Display name prefix.
            for _, player in ipairs(Players:GetPlayers()) do

                if player.DisplayName:lower():sub(
                    1,
                    #name
                ) == name then

                    return player

                end

            end

            return nil

        end

        ----------------------------------------------------------------
        -- MENGAMBIL DAFTAR BOT AKTIF
        ----------------------------------------------------------------

        local function getActiveBots()

            local activeBots = {}

            for _, botUserId in ipairs(botOrder) do

                local botPlayer =
                    Players:GetPlayerByUserId(
                        tonumber(botUserId)
                    )

                if botPlayer then

                    table.insert(
                        activeBots,
                        botUserId
                    )

                end

            end

            return activeBots

        end

        ----------------------------------------------------------------
        -- START FRONTLINE
        ----------------------------------------------------------------

        local function startFrontline(player)

            if not player then
                return
            end

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "frontline"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if frontlineConnection then
                frontlineConnection:Disconnect()
                frontlineConnection = nil
            end

            frontlining = true
            targetPlayer = player

            _G.BotVars.CommandTarget = player

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- VALIDASI BOT
            ------------------------------------------------------------

            local activeBots = getActiveBots()

            local activeIndex = table.find(
                activeBots,
                tostring(LocalPlayer.UserId)
            )

            if not activeIndex then
                stopFrontline()
                return
            end

            ------------------------------------------------------------
            -- FRONTLINE LOOP
            ------------------------------------------------------------

            frontlineConnection =
                RunService.Heartbeat:Connect(function()

                    ----------------------------------------------------
                    -- JIKA MODE SUDAH BERGANTI
                    ----------------------------------------------------

                    if _G.BotVars.ActiveMode ~= "frontline" then
                        stopFrontline()
                        return
                    end

                    ----------------------------------------------------
                    -- VALIDASI
                    ----------------------------------------------------

                    if not frontlining then
                        return
                    end

                    if not humanoid
                        or not myHRP
                        or humanoid.Health <= 0 then

                        return
                    end

                    if not targetPlayer then
                        return
                    end

                    ----------------------------------------------------
                    -- TARGET CHARACTER
                    ----------------------------------------------------

                    local targetCharacter =
                        targetPlayer.Character

                    if not targetCharacter then
                        return
                    end

                    local targetHRP =
                        targetCharacter:FindFirstChild(
                            "HumanoidRootPart"
                        )

                    if not targetHRP then
                        return
                    end

                    ----------------------------------------------------
                    -- PERBARUI DAFTAR BOT AKTIF
                    ----------------------------------------------------

                    activeBots = getActiveBots()

                    activeIndex = table.find(
                        activeBots,
                        tostring(LocalPlayer.UserId)
                    )

                    if not activeIndex then
                        return
                    end

                    ----------------------------------------------------
                    -- DISTANCE
                    ----------------------------------------------------

                    local distance =
                        defaultBotFrontlineDistance

                    if Admin:IsAdmin(targetPlayer) then

                        distance =
                            adminFrontlineDistance

                    end

                    local specialDistance =
                        Distance:GetDistance(
                            tostring(LocalPlayer.UserId),
                            tostring(targetPlayer.UserId)
                        )

                    if specialDistance then
                        distance = specialDistance
                    end

                    ----------------------------------------------------
                    -- HITUNG TITIK TENGAH FORMASI
                    ----------------------------------------------------

                    local activeBotCount = #activeBots

                    local centerIndex =
                        (activeBotCount + 1) / 2

                    ----------------------------------------------------
                    -- HITUNG OFFSET HORIZONTAL
                    --
                    -- 3 bot:
                    -- offset = -3, 0, 3
                    --
                    -- 5 bot:
                    -- offset = -6, -3, 0, 3, 6
                    --
                    -- 8 bot:
                    -- offset = -10.5, -7.5, -4.5, -1.5,
                    --           1.5, 4.5, 7.5, 10.5
                    ----------------------------------------------------

                    local horizontalOffset =
                        (activeIndex - centerIndex)
                        * formationSpacing

                    ----------------------------------------------------
                    -- POSISI FRONTLINE
                    ----------------------------------------------------

                    local targetPosition =
                        targetHRP.Position
                        + (
                            targetHRP.CFrame.LookVector
                            * distance
                        )
                        + (
                            targetHRP.CFrame.RightVector
                            * horizontalOffset
                        )

                    ----------------------------------------------------
                    -- JARAK KE POSISI TUJUAN
                    ----------------------------------------------------

                    local distanceToTarget =
                        (
                            myHRP.Position
                            - targetPosition
                        ).Magnitude

                    ----------------------------------------------------
                    -- JALAN KE POSISI
                    ----------------------------------------------------

                    if distanceToTarget > 1.5 then

                        humanoid.AutoRotate = true

                        humanoid:MoveTo(
                            targetPosition
                        )

                        return

                    end

                    ----------------------------------------------------
                    -- SUDAH SAMPAI
                    ----------------------------------------------------

                    humanoid.AutoRotate = false

                    local targetRotation =
                        targetHRP.CFrame
                        - targetHRP.Position

                    myHRP.CFrame =
                        CFrame.new(myHRP.Position)
                        * targetRotation

                end)

        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(message, sender)

            if not message or not sender then
                return
            end

            local isAdmin = false

            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            local lower =
                message:lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            local commandTarget =
                _G.BotVars.CommandTarget

            ------------------------------------------------------------
            -- !STOP / !UNFRONTLINE
            -- HANYA ADMIN
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unfrontline" then

                if not isAdmin then
                    return
                end

                _G.BotVars.ActiveMode = nil
                _G.BotVars.CommandTarget = nil

                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction) == "function" then
                        pcall(stopFunction)
                    end

                end

                return
            end

            ------------------------------------------------------------
            -- !FRONTLINE
            -- ADMIN ATAU COMMAND TARGET
            ------------------------------------------------------------

            if lower == "!frontline" then

                if not isAdmin and sender ~= commandTarget then
                    return
                end

                _G.BotVars.CommandTarget = sender

                startFrontline(sender)

                return
            end

            ------------------------------------------------------------
            -- !FRONTLINE PLAYER
            -- HANYA ADMIN
            ------------------------------------------------------------

            local targetName =
                lower:match("^!frontline%s+(.+)$")

            if targetName then

                if not isAdmin then
                    return
                end

                local target =
                    findPlayerByName(targetName)

                if target then

                    _G.BotVars.CommandTarget = target

                    startFrontline(target)

                end

                return
            end

        end

        ----------------------------------------------------------------
        -- TEXT CHAT
        ----------------------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

            if channel then

                channel.MessageReceived:Connect(
                    function(message)

                        local userId =
                            message.TextSource
                            and message.TextSource.UserId

                        local sender =
                            userId
                            and Players:GetPlayerByUserId(userId)

                        if sender then
                            handleCommand(message.Text, sender)
                        end

                    end
                )

            end

        end

        ----------------------------------------------------------------
        -- FALLBACK CHAT
        ----------------------------------------------------------------

        for _, player in ipairs(Players:GetPlayers()) do

            player.Chatted:Connect(function(message)

                handleCommand(message, player)

            end)

        end

        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(function(player)

            player.Chatted:Connect(function(message)

                handleCommand(message, player)

            end)

        end)

        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function()

            task.wait(1)

            updateCharacter()

            if _G.BotVars.ActiveMode == "frontline"
                and targetPlayer then

                startFrontline(targetPlayer)

            end

        end)

    end
}