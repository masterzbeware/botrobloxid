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

        ----------------------------------------------------------------
        -- DEFAULT DISTANCE
        ----------------------------------------------------------------
        -- Jarak Admin -> Bot 1
        -- Jika Distance.lua mempunyai jarak pasangan,
        -- nilai pasangan tersebut akan digunakan.

        local adminFollowDistance = 3

        -- Fallback untuk hubungan bot yang tidak ditulis
        -- secara eksplisit di Distance.lua.
        local defaultBotFollowDistance = 3

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------
        -- Urutan formasi:
        --
        -- Admin
        --   ↓ 3
        -- Bot 1
        --   ↓ 3
        -- Bot 2
        --   ↓ 3
        -- Bot 3
        --   ↓ 3
        -- Bot 4

        local botOrder = {
            "11611503633", -- Bot 1
            "11611567975", -- Bot 2
            "11611562042", -- Bot 3
            "11611591921", -- Bot 4
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

                    pcall(function()
                        channel:SendAsync(message)
                    end)

                    success = true
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
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayerByName(name)

            name = name:lower()

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player
                end
            end

            return nil
        end

        ----------------------------------------------------------------
        -- GET MY BOT INDEX
        ----------------------------------------------------------------

        local function getMyBotIndex()

            return table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            )
        end

        ----------------------------------------------------------------
        -- GET PREVIOUS BOT
        ----------------------------------------------------------------

        local function getPreviousBot(myIndex)

            if not myIndex or myIndex <= 1 then
                return nil
            end

            local previousUserId =
                tonumber(
                    botOrder[myIndex - 1]
                )

            if not previousUserId then
                return nil
            end

            return Players:GetPlayerByUserId(
                previousUserId
            )
        end

        ----------------------------------------------------------------
        -- GET DISTANCE FROM DISTANCE.LUA
        ----------------------------------------------------------------

        local function getFormationDistance(
            myIndex,
            referencePlayer
        )

            ------------------------------------------------------------
            -- BOT 1
            ------------------------------------------------------------
            -- Bot 1 mengikuti Admin/player.
            ------------------------------------------------------------

            if myIndex == 1 then

                local distanceFromDistanceModule =
                    Distance:GetDistance(
                        tostring(LocalPlayer.UserId),
                        tostring(referencePlayer.UserId)
                    )

                if distanceFromDistanceModule then
                    return distanceFromDistanceModule
                end

                return adminFollowDistance
            end

            ------------------------------------------------------------
            -- BOT 2+
            ------------------------------------------------------------
            -- Cek pasangan yang didefinisikan Distance.lua.
            ------------------------------------------------------------

            local previousBot =
                getPreviousBot(myIndex)

            if previousBot then

                local specialDistance =
                    Distance:GetDistance(
                        tostring(LocalPlayer.UserId),
                        tostring(previousBot.UserId)
                    )

                if specialDistance then
                    return specialDistance
                end
            end

            ------------------------------------------------------------
            -- FALLBACK
            ------------------------------------------------------------

            return defaultBotFollowDistance
        end

        ----------------------------------------------------------------
        -- CHECK TARGET JUMPING
        ----------------------------------------------------------------

        local function isPlayerJumping(player)

            if not player then
                return false
            end

            local character =
                player.Character

            if not character then
                return false
            end

            local targetHumanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            local targetHRP =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )

            if not targetHumanoid
                or not targetHRP then

                return false
            end

            local state =
                targetHumanoid:GetState()

            ------------------------------------------------------------
            -- STATE JUMP
            ------------------------------------------------------------

            if state == Enum.HumanoidStateType.Jumping
                or state == Enum.HumanoidStateType.Freefall then

                return true
            end

            ------------------------------------------------------------
            -- VELOCITY JUMP DETECTION
            ------------------------------------------------------------

            if targetHRP.AssemblyLinearVelocity.Y > 3 then
                return true
            end

            return false
        end

        ----------------------------------------------------------------
        -- JUMP BOT
        ----------------------------------------------------------------

        local function makeBotJump()

            if not humanoid then
                return
            end

            local state =
                humanoid:GetState()

            if state == Enum.HumanoidStateType.Jumping
                or state == Enum.HumanoidStateType.Freefall then

                return
            end

            humanoid.Jump = true

            pcall(function()
                humanoid:ChangeState(
                    Enum.HumanoidStateType.Jumping
                )
            end)
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

            if humanoid then
                humanoid.AutoRotate = true
            end
        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.follow =
            stopFollow

        ----------------------------------------------------------------
        -- STOP ALL OTHER MODES
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
        -- START FOLLOW
        ----------------------------------------------------------------

        local function startFollow(player)

            if not player then
                return
            end

            ------------------------------------------------------------
            -- STOP OTHER MODES
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- SET MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "follow"

            ------------------------------------------------------------
            -- STOP OLD CONNECTION
            ------------------------------------------------------------

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            following = true
            targetPlayer = player

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- GET BOT INDEX
            ------------------------------------------------------------

            local myIndex =
                getMyBotIndex()

            if not myIndex then

                stopFollow()
                return

            end

            ------------------------------------------------------------
            -- FOLLOW LOOP
            ------------------------------------------------------------

            followConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE CHECK
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "follow" then

                            stopFollow()
                            return

                        end

                        ------------------------------------------------
                        -- VALIDATION
                        ------------------------------------------------

                        if not following then
                            return
                        end

                        if not humanoid
                            or not myHRP then

                            return
                        end

                        if not targetPlayer then
                            return
                        end

                        ------------------------------------------------
                        -- DETERMINE FORMATION TARGET
                        ------------------------------------------------
                        --
                        -- Bot 1 -> Admin
                        -- Bot 2 -> Bot 1
                        -- Bot 3 -> Bot 2
                        -- Bot 4 -> Bot 3
                        --

                        local formationTarget =
                            targetPlayer

                        if myIndex > 1 then

                            local previousBot =
                                getPreviousBot(myIndex)

                            if previousBot then

                                formationTarget =
                                    previousBot

                            end
                        end

                        ------------------------------------------------
                        -- TARGET CHARACTER
                        ------------------------------------------------

                        local targetCharacter =
                            formationTarget.Character

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

                        ------------------------------------------------
                        -- TARGET HUMANOID
                        ------------------------------------------------

                        local targetHumanoid =
                            targetCharacter:FindFirstChildOfClass(
                                "Humanoid"
                            )

                        ------------------------------------------------
                        -- JUMP FOLLOW
                        ------------------------------------------------
                        -- Jika target formasi melompat,
                        -- bot langsung ikut melompat.

                        if isPlayerJumping(
                            formationTarget
                        ) then

                            makeBotJump()

                        elseif myHRP.Position.Y
                            < targetHRP.Position.Y - 5 then

                            ------------------------------------------------
                            -- Jika bot tertinggal jauh secara vertikal,
                            -- bantu lompat untuk mengejar.
                            ------------------------------------------------

                            makeBotJump()

                        end

                        ------------------------------------------------
                        -- GET DISTANCE
                        ------------------------------------------------

                        local distance =
                            getFormationDistance(
                                myIndex,
                                formationTarget
                            )

                        ------------------------------------------------
                        -- FORMATION DIRECTION
                        ------------------------------------------------
                        -- Gunakan arah hadap target.
                        --
                        -- Bot selalu berada di belakang target
                        -- sebesar distance.

                        local lookVector =
                            targetHRP.CFrame.LookVector

                        ------------------------------------------------
                        -- TARGET POSITION
                        ------------------------------------------------

                        local targetPosition =
                            targetHRP.Position
                            -
                            (
                                lookVector
                                * distance
                            )

                        ------------------------------------------------
                        -- JAGA KETINGGIAN
                        ------------------------------------------------
                        -- Tidak mengunci Y secara keras.
                        -- Ini penting agar bot bisa mengikuti
                        -- tanjakan, turunan dan lompatan.

                        ------------------------------------------------
                        -- HITUNG JARAK
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- MOVEMENT
                        ------------------------------------------------

                        if distanceToTarget > 1.25 then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return
                        end

                        ------------------------------------------------
                        -- SUDAH DEKAT
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        ------------------------------------------------
                        -- HADAP SAMA DENGAN TARGET
                        ------------------------------------------------

                        local targetRotation =
                            CFrame.lookAt(
                                myHRP.Position,
                                myHRP.Position
                                +
                                targetHRP.CFrame.LookVector
                            )

                        myHRP.CFrame =
                            CFrame.new(
                                myHRP.Position
                            )
                            *
                            (
                                targetRotation
                                -
                                targetRotation.Position
                            )

                    end
                )
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
            -- !FOLLOW
            ------------------------------------------------------------

            if lower == "!follow" then

                startFollow(sender)

                return
            end

            ------------------------------------------------------------
            -- !FOLLOW PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!follow%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startFollow(target)

                end

                return
            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unfollow" then

                _G.BotVars.ActiveMode = nil

                stopFollow()

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
                    == "follow"
                    and targetPlayer then

                    startFollow(
                        targetPlayer
                    )

                end
            end
        )

    end
}