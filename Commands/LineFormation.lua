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

        local lining = false
        local targetPlayer = nil
        local lineConnection = nil
        local currentLineMode = nil

        ----------------------------------------------------------------
        -- FORMATION SETTINGS
        ----------------------------------------------------------------

        -- Jarak antar bot.
        local spacing = 3

        -- Jarak baris pertama dari target dan antarbaris.
        local rowSpacing = 3

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

                    success = pcall(function()
                        channel:SendAsync(message)
                    end)

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
        -- STOP LINE
        ----------------------------------------------------------------

        local function stopLine()

            lining = false
            targetPlayer = nil
            currentLineMode = nil

            if lineConnection then
                lineConnection:Disconnect()
                lineConnection = nil
            end

            if humanoid then
                humanoid.AutoRotate = true
            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.line = stopLine

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "line"
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
        -- GET ACTIVE BOTS
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
        -- GET FORMATION SIZE
        ----------------------------------------------------------------

        local function getFormation(mode)

            if mode == 1 then

                -- Maksimal 12 bot dalam 1 baris.
                return 12

            elseif mode == 2 then

                -- Maksimal 6 bot per baris.
                return 6

            elseif mode == 3 then

                -- Maksimal 3 bot per baris.
                return 3

            end

            return nil

        end

        ----------------------------------------------------------------
        -- CALCULATE BOT POSITION
        ----------------------------------------------------------------

        local function getBotPosition(
            targetHRP,
            activeIndex,
            activeBotCount,
            mode
        )

            ------------------------------------------------------------
            -- JUMLAH BOT MAKSIMAL PER BARIS
            ------------------------------------------------------------

            local botsPerRow = getFormation(mode)

            if not botsPerRow
                or activeBotCount <= 0
                or activeIndex < 1
                or activeIndex > activeBotCount then

                return nil

            end

            ------------------------------------------------------------
            -- HITUNG BARIS
            ------------------------------------------------------------

            local row =
                math.floor(
                    (activeIndex - 1) / botsPerRow
                )

            ------------------------------------------------------------
            -- HITUNG KOLOM
            ------------------------------------------------------------

            local column =
                (activeIndex - 1) % botsPerRow

            ------------------------------------------------------------
            -- JUMLAH BOT PADA BARIS SAAT INI
            ------------------------------------------------------------

            local firstBotInRow =
                row * botsPerRow

            local botsInThisRow =
                math.min(
                    botsPerRow,
                    activeBotCount - firstBotInRow
                )

            ------------------------------------------------------------
            -- TITIK TENGAH BARIS
            ------------------------------------------------------------

            local centerColumn =
                (botsInThisRow - 1) / 2

            ------------------------------------------------------------
            -- OFFSET HORIZONTAL
            --
            -- 3 bot:
            -- -3, 0, 3
            --
            -- 5 bot:
            -- -6, -3, 0, 3, 6
            --
            -- 8 bot dalam mode 2:
            -- Baris 1: 6 bot, terpusat.
            -- Baris 2: 2 bot, terpusat.
            ------------------------------------------------------------

            local horizontalOffset =
                (column - centerColumn)
                * spacing

            ------------------------------------------------------------
            -- OFFSET DEPTH
            --
            -- Baris pertama paling dekat dengan target.
            -- Baris selanjutnya berada semakin ke belakang.
            ------------------------------------------------------------

            local depthOffset =
                (row + 1) * rowSpacing

            ------------------------------------------------------------
            -- TARGET DIRECTION
            ------------------------------------------------------------

            local right =
                targetHRP.CFrame.RightVector

            local backward =
                -targetHRP.CFrame.LookVector

            ------------------------------------------------------------
            -- FINAL POSITION
            ------------------------------------------------------------

            local targetPosition =
                targetHRP.Position
                + (right * horizontalOffset)
                + (backward * depthOffset)

            return targetPosition

        end

        ----------------------------------------------------------------
        -- START LINE
        ----------------------------------------------------------------

        local function startLine(player, mode)

            if not player then
                return
            end

            if mode ~= 1
                and mode ~= 2
                and mode ~= 3 then

                return

            end

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "line"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if lineConnection then
                lineConnection:Disconnect()
                lineConnection = nil
            end

            ------------------------------------------------------------
            -- STATE
            ------------------------------------------------------------

            lining = true
            targetPlayer = player
            currentLineMode = mode

            _G.BotVars.CommandTarget = player

            ------------------------------------------------------------
            -- CARI INDEX BOT AKTIF
            ------------------------------------------------------------

            local activeBots = getActiveBots()

            local activeIndex = table.find(
                activeBots,
                tostring(LocalPlayer.UserId)
            )

            if not activeIndex then
                stopLine()
                return
            end

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- LINE LOOP
            ------------------------------------------------------------

            lineConnection =
                RunService.Heartbeat:Connect(function()

                    ----------------------------------------------------
                    -- MODE CHECK
                    ----------------------------------------------------

                    if _G.BotVars.ActiveMode ~= "line" then
                        stopLine()
                        return
                    end

                    ----------------------------------------------------
                    -- STATE CHECK
                    ----------------------------------------------------

                    if not lining then
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
                    -- PERBARUI BOT AKTIF
                    ----------------------------------------------------

                    activeBots = getActiveBots()

                    activeIndex = table.find(
                        activeBots,
                        tostring(LocalPlayer.UserId)
                    )

                    if not activeIndex then
                        return
                    end

                    local activeBotCount =
                        #activeBots

                    ----------------------------------------------------
                    -- HITUNG POSISI DINAMIS
                    ----------------------------------------------------

                    local targetPosition =
                        getBotPosition(
                            targetHRP,
                            activeIndex,
                            activeBotCount,
                            currentLineMode
                        )

                    if not targetPosition then
                        return
                    end

                    ----------------------------------------------------
                    -- DISTANCE
                    ----------------------------------------------------

                    local distanceToTarget =
                        (
                            myHRP.Position
                            - targetPosition
                        ).Magnitude

                    ----------------------------------------------------
                    -- MOVE
                    ----------------------------------------------------

                    if distanceToTarget > 1.5 then

                        humanoid.AutoRotate = true

                        humanoid:MoveTo(
                            targetPosition
                        )

                        return

                    end

                    ----------------------------------------------------
                    -- REACHED POSITION
                    ----------------------------------------------------

                    humanoid.AutoRotate = false

                    ----------------------------------------------------
                    -- BOT MENGHADAP ARAH TARGET
                    ----------------------------------------------------

                    local lookDirection =
                        targetHRP.CFrame.LookVector

                    local lookPosition =
                        myHRP.Position + lookDirection

                    myHRP.CFrame =
                        CFrame.lookAt(
                            myHRP.Position,
                            lookPosition
                        )

                end)

        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(message, sender)

            if not message or not sender then
                return
            end

            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            local isAdmin = false

            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            ------------------------------------------------------------
            -- CLEAN MESSAGE
            ------------------------------------------------------------

            local lower =
                message:lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            ------------------------------------------------------------
            -- COMMAND TARGET
            ------------------------------------------------------------

            local commandTarget =
                _G.BotVars.CommandTarget

            ------------------------------------------------------------
            -- !STOP / !UNLINE
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unline" then

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
            -- !LINE 1 / !LINE 2 / !LINE 3
            ------------------------------------------------------------

            local mode =
                lower:match("^!line%s+([123])$")

            if mode then

                mode = tonumber(mode)

                -- Admin atau CommandTarget boleh mengganti formasi.
                if not isAdmin and sender ~= commandTarget then
                    return
                end

                -- Admin menjalankan formasi pada dirinya sendiri.
                if isAdmin then

                    _G.BotVars.CommandTarget = sender

                    startLine(sender, mode)

                    return

                end

                -- CommandTarget menjalankan formasi pada dirinya sendiri.
                if sender == commandTarget then

                    startLine(sender, mode)

                    return

                end

            end

            ------------------------------------------------------------
            -- !LINE 1 PLAYER / !LINE 2 PLAYER / !LINE 3 PLAYER
            -- HANYA ADMIN
            ------------------------------------------------------------

            local modeWithPlayer, targetName =
                lower:match(
                    "^!line%s+([123])%s+(.+)$"
                )

            if modeWithPlayer and targetName then

                if not isAdmin then
                    return
                end

                local selectedMode =
                    tonumber(modeWithPlayer)

                local target =
                    findPlayerByName(targetName)

                if not target then
                    return
                end

                _G.BotVars.CommandTarget = target

                startLine(
                    target,
                    selectedMode
                )

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

                channel.MessageReceived:Connect(function(message)

                    local userId =
                        message.TextSource
                        and message.TextSource.UserId

                    local sender =
                        userId
                        and Players:GetPlayerByUserId(userId)

                    if sender then
                        handleCommand(message.Text, sender)
                    end

                end)

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

            if _G.BotVars.ActiveMode == "line"
                and targetPlayer
                and currentLineMode then

                startLine(
                    targetPlayer,
                    currentLineMode
                )

            end

        end)

    end
}