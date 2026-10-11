
-- Follow.lua
-- MasterZ HUB
-- Stable Straight-Line Follow Formation
-- Admin + Additional Admin + CommandTarget
-- Commands:
-- !follow
-- !follow username
-- !stop
-- !unfollow

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

        local following = false
        local targetPlayer = nil
        local followConnection = nil

        -- Mencegah banyak koneksi CharacterAdded.
        local characterConnection

        -- Cache gerakan agar MoveTo tidak dipanggil setiap frame.
        local lastMoveTarget = nil
        local lastMoveTime = 0

        ----------------------------------------------------------------
        -- FOLLOW SETTINGS
        ----------------------------------------------------------------

        -- Jarak bot pertama dari target.
        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2

        -- Jarak konsisten antarbot.
        local botSpacing = 2

        -- Toleransi saat bot mencapai tujuan.
        local arrivalThreshold = 1.5

        -- Interval pembaruan perintah gerak.
        local moveUpdateInterval = 0.25

        -- Seberapa jauh titik tujuan harus berubah
        -- sebelum MoveTo dipanggil lagi.
        local moveTargetChangeThreshold = 0.5

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

        -- Urutan menentukan posisi setiap bot.
        -- Bot yang tidak aktif tidak mengubah urutan
        -- posisi bot lain.

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

            lastMoveTarget = nil
            lastMoveTime = 0

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

                    if not chatEvents then
                        return
                    end

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

                end)

            end

        end

        ----------------------------------------------------------------
        -- STOP FOLLOW
        ----------------------------------------------------------------

        local function stopFollow()

            following = false
            targetPlayer = nil

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            lastMoveTarget = nil
            lastMoveTime = 0

            if humanoid then
                humanoid.AutoRotate = true
            end

            -- CommandTarget sengaja tidak dihapus di sini.
            -- CommandTarget hanya dihapus oleh !stop / !unfollow
            -- yang dikirim oleh admin.

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.follow =
            stopFollow

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "follow"
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

            ------------------------------------------------------------
            -- EXACT USERNAME / DISPLAY NAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            ------------------------------------------------------------
            -- USERNAME PREFIX
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower():sub(
                    1,
                    #name
                ) == name then

                    return player

                end

            end

            ------------------------------------------------------------
            -- DISPLAY NAME PREFIX
            ------------------------------------------------------------

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
        -- GET BOT INDEX
        ----------------------------------------------------------------

        local function getBotIndex()

            return table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            )

        end

        ----------------------------------------------------------------
        -- GET FIRST BOT DISTANCE
        ----------------------------------------------------------------

        local function getFirstBotDistance(player)

            -- Target adalah admin.
            if Admin:IsAdmin(player) then
                return adminFollowDistance
            end

            -- Target bukan admin.
            return defaultBotFollowDistance

        end

        ----------------------------------------------------------------
        -- START FOLLOW
        ----------------------------------------------------------------

        local function startFollow(player)

            if not player then
                return
            end

            ------------------------------------------------------------
            -- VALIDASI BOT
            ------------------------------------------------------------

            local myIndex = getBotIndex()

            if not myIndex then

                warn(
                    "[Follow] UserId bot tidak ditemukan di botOrder:",
                    LocalPlayer.UserId
                )

                stopFollow()
                return

            end

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "follow"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            ------------------------------------------------------------
            -- SET FOLLOW STATE
            ------------------------------------------------------------

            following = true
            targetPlayer = player

            _G.BotVars.CommandTarget = player

            lastMoveTarget = nil
            lastMoveTime = 0

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- FOLLOW LOOP
            ------------------------------------------------------------

            followConnection =
                RunService.Heartbeat:Connect(function()

                    ----------------------------------------------------
                    -- VALIDASI MODE
                    ----------------------------------------------------

                    if _G.BotVars.ActiveMode ~= "follow" then

                        stopFollow()
                        return

                    end

                    if not following then
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
                    -- FIRST BOT DISTANCE
                    ----------------------------------------------------

                    local firstDistance =
                        getFirstBotDistance(targetPlayer)

                    ----------------------------------------------------
                    -- STRAIGHT-LINE FORMATION
                    ----------------------------------------------------

                    -- Semua bot menggunakan satu sumbu yang sama.
                    -- Tidak menggunakan jarak pasangan Distance.lua
                    -- sebagai jarak target, karena itu menyebabkan
                    -- jarak posisi bot tidak konsisten.

                    local distanceFromTarget =
                        firstDistance
                        + ((myIndex - 1) * botSpacing)

                    ----------------------------------------------------
                    -- CALCULATE TARGET POSITION
                    ----------------------------------------------------

                    local targetLookVector =
                        targetHRP.CFrame.LookVector

                    local targetPosition =
                        targetHRP.Position
                        - (
                            targetLookVector
                            * distanceFromTarget
                        )

                    ----------------------------------------------------
                    -- DISTANCE TO DESTINATION
                    ----------------------------------------------------

                    local distanceToTarget =
                        (
                            myHRP.Position
                            - targetPosition
                        ).Magnitude

                    ----------------------------------------------------
                    -- MOVE TO POSITION
                    ----------------------------------------------------

                    if distanceToTarget > arrivalThreshold then

                        humanoid.AutoRotate = true

                        local now = os.clock()

                        local targetChanged = false

                        if not lastMoveTarget then

                            targetChanged = true

                        elseif (
                            targetPosition - lastMoveTarget
                        ).Magnitude >= moveTargetChangeThreshold then

                            targetChanged = true

                        end

                        local intervalElapsed =
                            now - lastMoveTime
                            >= moveUpdateInterval

                        if targetChanged or intervalElapsed then

                            humanoid:MoveTo(targetPosition)

                            lastMoveTarget = targetPosition
                            lastMoveTime = now

                        end

                        return

                    end

                    ----------------------------------------------------
                    -- ARRIVED: STOP MOVEMENT UPDATES
                    ----------------------------------------------------

                    lastMoveTarget = nil
                    lastMoveTime = 0

                    ----------------------------------------------------
                    -- FACE SAME DIRECTION AS TARGET
                    ----------------------------------------------------

                    humanoid.AutoRotate = false

                    local targetRotation =
                        targetHRP.CFrame.Rotation

                    myHRP.CFrame =
                        CFrame.new(myHRP.Position)
                        * targetRotation

                end)

        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(message, sender)

            if not sender or not message then
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
            -- COMMAND TARGET CHECK
            ------------------------------------------------------------

            local isCommandTarget =
                _G.BotVars.CommandTarget == sender

            ------------------------------------------------------------
            -- CLEAN MESSAGE
            ------------------------------------------------------------

            local lower =
                message:lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            ------------------------------------------------------------
            -- !STOP / !UNFOLLOW
            -- HANYA ADMIN
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unfollow" then

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
            -- !FOLLOW
            -- ADMIN ATAU COMMAND TARGET
            ------------------------------------------------------------

            if lower == "!follow" then

                if not isAdmin and not isCommandTarget then
                    return
                end

                _G.BotVars.CommandTarget = sender

                startFollow(sender)

                return

            end

            ------------------------------------------------------------
            -- !FOLLOW USERNAME
            -- HANYA ADMIN
            ------------------------------------------------------------

            local targetName =
                lower:match("^!follow%s+(.+)$")

            if targetName then

                if not isAdmin then
                    return
                end

                local target =
                    findPlayerByName(targetName)

                if not target then

                    warn(
                        "[Follow] Player tidak ditemukan:",
                        targetName
                    )

                    return

                end

                _G.BotVars.CommandTarget = target

                startFollow(target)

                return

            end

        end

        ----------------------------------------------------------------
        -- CONNECT TEXT CHAT
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

                        handleCommand(
                            message.Text,
                            sender
                        )

                    end

                end)

            end

        end

        ----------------------------------------------------------------
        -- FALLBACK CHAT
        ----------------------------------------------------------------

        local connectedPlayers = {}

        local function connectPlayerChat(player)

            if connectedPlayers[player] then
                return
            end

            connectedPlayers[player] = true

            player.Chatted:Connect(function(message)

                handleCommand(
                    message,
                    player
                )

            end)

        end

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayerChat(player)
        end

        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(function(player)

            connectPlayerChat(player)

        end)

        Players.PlayerRemoving:Connect(function(player)

            connectedPlayers[player] = nil

            if targetPlayer == player then

                stopFollow()

                if _G.BotVars.ActiveMode == "follow" then
                    _G.BotVars.ActiveMode = nil
                end

            end

        end)

        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        if characterConnection then
            characterConnection:Disconnect()
        end

        characterConnection =
            LocalPlayer.CharacterAdded:Connect(function()

                task.wait(1)

                updateCharacter()

                if _G.BotVars.ActiveMode == "follow"
                    and targetPlayer then

                    startFollow(targetPlayer)

                end

            end)

        ----------------------------------------------------------------
        -- FINISHED
        ----------------------------------------------------------------

        print(
            "[Follow] Loaded: stable straight-line formation."
        )

    end
}