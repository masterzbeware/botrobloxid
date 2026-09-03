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

        local targetPlayer = nil

        local rolling = false
        local rollToken = 0

        ----------------------------------------------------------------
        -- DISTANCE CONFIG
        ----------------------------------------------------------------

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2

        ----------------------------------------------------------------
        -- ROLLING CONFIG
        ----------------------------------------------------------------

        local sideSpacing = 2.5
        local rowSpacing = 3

        local centerDistance = 2

        local stopThreshold = 1.5

        -- Jarak tambahan supaya "di belakang" bot sebelumnya
        local behindSpacing = 3

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

        local botOrder = {
            "11611503633", -- BOT 1
            "11611534165", -- BOT 2
            "11611567975", -- BOT 3
            "11611562042", -- BOT 4
            "11611591921", -- BOT 5
            "11122806815", -- BOT 6
            "11122806817", -- BOT 7
            "11122687468", -- BOT 8
            "11122854402", -- BOT 9
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
                character:WaitForChild(
                    "HumanoidRootPart"
                )

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
                    TextChatService.TextChannels
                        :FindFirstChild("RBXGeneral")

                if channel then

                    pcall(function()

                        channel:SendAsync(message)

                    end)

                    success = true
                end
            end

            if not success then

                pcall(function()

                    local chatEvents =
                        ReplicatedStorage
                            :FindFirstChild(
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
        -- STOP ROLLING
        ----------------------------------------------------------------

        local function stopRolling()

            rolling = false
            targetPlayer = nil

            rollToken += 1

            if humanoid then

                humanoid.AutoRotate = true

                if myHRP then

                    humanoid:MoveTo(
                        myHRP.Position
                    )

                end
            end
        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.rolling =
            stopRolling

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "rolling"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end
            end
        end

        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayerByName(name)

            if not name
                or name == "" then

                return nil
            end

            name = name:lower()

            ------------------------------------------------------------
            -- EXACT
            ------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end
            end

            ------------------------------------------------------------
            -- PARTIAL
            ------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower():find(
                    name,
                    1,
                    true
                )
                    or player.DisplayName:lower():find(
                        name,
                        1,
                        true
                    ) then

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
        -- GET BOT BY INDEX
        ----------------------------------------------------------------

        local function getBotByIndex(index)

            local userId =
                tonumber(botOrder[index])

            if not userId then
                return nil
            end

            return Players:GetPlayerByUserId(
                userId
            )
        end

        ----------------------------------------------------------------
        -- GET FOLLOW DISTANCE
        ----------------------------------------------------------------

        local function getFollowDistance(player)

            local distance =
                defaultBotFollowDistance

            if Admin:IsAdmin(player) then

                distance =
                    adminFollowDistance

            end

            local success, specialDistance =
                pcall(function()

                    return Distance:GetDistance(
                        tostring(LocalPlayer.UserId),
                        tostring(player.UserId)
                    )

                end)

            if success
                and specialDistance then

                distance =
                    specialDistance

            end

            return distance
        end

        ----------------------------------------------------------------
        -- GET ORIGINAL FORMATION POSITION
        --
        -- BOT 1  BOT 2
        -- BOT 3  BOT 4
        -- BOT 5  BOT 6
        -- BOT 7  BOT 8
        --             BOT 9
        ----------------------------------------------------------------

        local function getFormationPosition(
            index,
            targetHRP,
            distance
        )

            if not targetHRP then
                return nil
            end

            local row
            local side

            ------------------------------------------------------------
            -- BOT 9
            ------------------------------------------------------------

            if index == 9 then

                row = 5
                side = 1

            else

                row =
                    math.ceil(index / 2)

                if index % 2 == 1 then
                    side = -1
                else
                    side = 1
                end

            end

            local backDistance =
                distance
                + ((row - 1) * rowSpacing)

            local backOffset =
                targetHRP.CFrame.LookVector
                * -backDistance

            local sideOffset =
                targetHRP.CFrame.RightVector
                * (sideSpacing * side)

            return
                targetHRP.Position
                + backOffset
                + sideOffset
        end

        ----------------------------------------------------------------
        -- GET CENTER POSITION
        --
        -- Titik di antara BOT 1 dan BOT 2
        ----------------------------------------------------------------

        local function getCenterPosition(
            targetHRP,
            distance
        )

            if not targetHRP then
                return nil
            end

            return
                targetHRP.Position
                - targetHRP.CFrame.LookVector
                * (distance + centerDistance)
        end

        ----------------------------------------------------------------
        -- GET POSITION BEHIND ANOTHER BOT
        ----------------------------------------------------------------

        local function getPositionBehindBot(
            botPlayer
        )

            if not botPlayer then
                return nil
            end

            local character =
                botPlayer.Character

            if not character then
                return nil
            end

            local botHRP =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )

            if not botHRP then
                return nil
            end

            return
                botHRP.Position
                - botHRP.CFrame.LookVector
                * behindSpacing
        end

        ----------------------------------------------------------------
        -- GET ROLLING PREVIOUS BOT
        --
        -- BOT 1 -> belakang BOT 7
        -- BOT 2 -> belakang BOT 9
        -- BOT 3 -> belakang BOT 1
        -- BOT 4 -> belakang BOT 2
        -- BOT 5 -> belakang BOT 3
        -- BOT 6 -> belakang BOT 4
        -- BOT 7 -> belakang BOT 5
        -- BOT 8 -> belakang BOT 6
        -- BOT 9 -> belakang BOT 8
        ----------------------------------------------------------------

        local function getPreviousDestinationBot(
            index
        )

            local destinationBotIndex

            if index == 1 then

                destinationBotIndex = 7

            elseif index == 2 then

                destinationBotIndex = 9

            elseif index == 3 then

                destinationBotIndex = 1

            elseif index == 4 then

                destinationBotIndex = 2

            elseif index == 5 then

                destinationBotIndex = 3

            elseif index == 6 then

                destinationBotIndex = 4

            elseif index == 7 then

                destinationBotIndex = 5

            elseif index == 8 then

                destinationBotIndex = 6

            elseif index == 9 then

                destinationBotIndex = 8

            end

            if not destinationBotIndex then
                return nil
            end

            return getBotByIndex(
                destinationBotIndex
            )
        end

        ----------------------------------------------------------------
        -- MOVE TO POSITION
        ----------------------------------------------------------------

        local function moveAndWait(
            position,
            token
        )

            if not position then
                return false
            end

            if not humanoid
                or not myHRP then

                return false
            end

            humanoid.AutoRotate = true

            humanoid:MoveTo(
                position
            )

            while rolling
                and token == rollToken do

                if not humanoid
                    or not myHRP then

                    return false
                end

                local distance =
                    (
                        myHRP.Position
                        - position
                    ).Magnitude

                if distance
                    <= stopThreshold then

                    humanoid:MoveTo(
                        myHRP.Position
                    )

                    return true
                end

                RunService.Heartbeat:Wait()
            end

            return false
        end

        ----------------------------------------------------------------
        -- WAIT FOR PREVIOUS BOT
        --
        -- Ini yang membuat BOT 1 -> BOT 2 -> BOT 3
        -- benar-benar bergantian.
        ----------------------------------------------------------------

        local function waitForPreviousBot(
            previousBot,
            expectedPositionFunction,
            token
        )

            if not previousBot then
                return true
            end

            local timeout =
                120

            local startTime =
                os.clock()

            while rolling
                and token == rollToken do

                if os.clock() - startTime
                    > timeout then

                    return false
                end

                local position =
                    expectedPositionFunction()

                if position then

                    local character =
                        previousBot.Character

                    if character then

                        local previousHRP =
                            character:FindFirstChild(
                                "HumanoidRootPart"
                            )

                        if previousHRP then

                            local distance =
                                (
                                    previousHRP.Position
                                    - position
                                ).Magnitude

                            if distance
                                <= stopThreshold + 1 then

                                return true
                            end
                        end
                    end
                end

                RunService.Heartbeat:Wait()
            end

            return false
        end

        ----------------------------------------------------------------
        -- PERFORM ONE ROLL
        ----------------------------------------------------------------

        local function performRoll()

            local myIndex =
                getBotIndex()

            if not myIndex then

                stopRolling()
                return

            end

            local player =
                targetPlayer

            if not player then
                return
            end

            local token =
                rollToken

            ------------------------------------------------------------
            -- BOT 2+ WAIT FOR PREVIOUS BOT
            ------------------------------------------------------------

            if myIndex > 1 then

                local previousBot =
                    getBotByIndex(
                        myIndex - 1
                    )

                if not previousBot then
                    return
                end

                local function previousBotExpectedPosition()

                    local previousIndex =
                        myIndex - 1

                    local destinationBot =
                        getPreviousDestinationBot(
                            previousIndex
                        )

                    if not destinationBot then
                        return nil
                    end

                    return getPositionBehindBot(
                        destinationBot
                    )
                end

                local ready =
                    waitForPreviousBot(
                        previousBot,
                        previousBotExpectedPosition,
                        token
                    )

                if not ready then
                    return
                end

            end

            ------------------------------------------------------------
            -- GET TARGET
            ------------------------------------------------------------

            local character =
                player.Character

            if not character then
                return
            end

            local targetHRP =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )

            if not targetHRP then
                return
            end

            local distance =
                getFollowDistance(
                    player
                )

            ------------------------------------------------------------
            -- SEMUA BOT LEWAT TENGAH
            ------------------------------------------------------------

            local centerPosition =
                getCenterPosition(
                    targetHRP,
                    distance
                )

            local reachedCenter =
                moveAndWait(
                    centerPosition,
                    token
                )

            if not reachedCenter then
                return
            end

            ------------------------------------------------------------
            -- AMBIL BOT YANG MENJADI DEPAN
            ------------------------------------------------------------

            local destinationBot =
                getPreviousDestinationBot(
                    myIndex
                )

            if not destinationBot then
                return
            end

            ------------------------------------------------------------
            -- TUNGGU TARGET BOT VALID
            ------------------------------------------------------------

            local destinationPosition

            local startTime =
                os.clock()

            while rolling
                and token == rollToken do

                destinationPosition =
                    getPositionBehindBot(
                        destinationBot
                    )

                if destinationPosition then
                    break
                end

                if os.clock() - startTime
                    > 30 then

                    return
                end

                RunService.Heartbeat:Wait()
            end

            if not destinationPosition then
                return
            end

            ------------------------------------------------------------
            -- BERJALAN KE BELAKANG BOT TUJUAN
            ------------------------------------------------------------

            local reachedDestination =
                moveAndWait(
                    destinationPosition,
                    token
                )

            if not reachedDestination then
                return
            end

            ------------------------------------------------------------
            -- SELESAI
            ------------------------------------------------------------

            humanoid.AutoRotate = true

            print(
                "[ROLLING] BOT "
                    .. tostring(myIndex)
                    .. " selesai."
            )

        end

        ----------------------------------------------------------------
        -- START ROLLING
        ----------------------------------------------------------------

        local function startRolling(
            player
        )

            if not player then
                return
            end

            stopOtherModes()

            _G.BotVars.ActiveMode =
                "rolling"

            rolling = false
            rollToken += 1

            task.wait()

            rolling = true
            targetPlayer = player

            local myIndex =
                getBotIndex()

            if myIndex then

                print(
                    "[ROLLING] BOT "
                        .. tostring(myIndex)
                        .. " siap."
                )

            end

            sendChat("Yes, Sir!")

            local token =
                rollToken

            task.spawn(function()

                performRoll()

            end)

        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            ------------------------------------------------------------
            -- !rolling
            ------------------------------------------------------------

            if lower == "!rolling" then

                startRolling(
                    sender
                )

                return
            end

            ------------------------------------------------------------
            -- !rolling PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!rolling%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startRolling(
                        target
                    )

                end

                return
            end

            ------------------------------------------------------------
            -- STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unrolling" then

                _G.BotVars.ActiveMode = nil

                stopRolling()

                return
            end
        end

        ----------------------------------------------------------------
        -- TEXT CHAT
        ----------------------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels
                    :FindFirstChild(
                        "RBXGeneral"
                    )

            if channel then

                channel.OnIncomingMessage =
                    function(message)

                        local userId =
                            message.TextSource
                            and message.TextSource.UserId

                        local sender =
                            userId
                            and Players:GetPlayerByUserId(
                                userId
                            )

                        if sender then

                            handleCommand(
                                message.Text,
                                sender
                            )

                        end

                    end
            end
        end

        ----------------------------------------------------------------
        -- FALLBACK CHAT
        ----------------------------------------------------------------

        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            player.Chatted:Connect(
                function(message)

                    handleCommand(
                        message,
                        player
                    )

                end
            )

        end

        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                player.Chatted:Connect(
                    function(message)

                        handleCommand(
                            message,
                            player
                        )

                    end
                )

            end
        )

        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()

                if _G.BotVars.ActiveMode
                    == "rolling"
                    and targetPlayer then

                    local oldTarget =
                        targetPlayer

                    stopRolling()

                    task.wait(0.5)

                    startRolling(
                        oldTarget
                    )

                end

            end
        )

    end
}