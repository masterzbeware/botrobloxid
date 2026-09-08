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

        local active = false
        local targetPlayer = nil
        local vanguardConnection = nil

        ----------------------------------------------------------------
        -- CONFIG
        ----------------------------------------------------------------

        local stopDistance = 1.5

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

        local botOrder = {

            "11611503633", -- Bot 1
            "11611534165", -- Bot 2
            "11611567975", -- Bot 3
            "11611562042", -- Bot 4
            "11611591921", -- Bot 5
            "11122806815", -- Bot 6
            "11122806817", -- Bot 7
            "11122687468", -- Bot 8
            "11122854402", -- Bot 9
            "11641280895", -- Bot 10
            "11641342530", -- Bot 11
            "11001607521", -- Bot 12
            "11001608049", -- Bot 13
            "11601625681", -- Bot 14

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

            ------------------------------------------------------------
            -- TEXT CHAT
            ------------------------------------------------------------

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

            ------------------------------------------------------------
            -- OLD CHAT FALLBACK
            ------------------------------------------------------------

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
        -- STOP VANGUARD
        ----------------------------------------------------------------

        local function stopVanguard()

            active = false
            targetPlayer = nil

            if vanguardConnection then

                vanguardConnection:Disconnect()
                vanguardConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

            ------------------------------------------------------------
            -- CLEAR ACTIVE MODE
            ------------------------------------------------------------

            if _G.BotVars.ActiveMode == "vanguard" then

                _G.BotVars.ActiveMode = nil

            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.vanguard =
            stopVanguard

        ----------------------------------------------------------------
        -- STOP MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "vanguard"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

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
        -- GET FORMATION POSITION
        ----------------------------------------------------------------

        local function getFormationPosition(
            index,
            targetHRP
        )

            local origin =
                targetHRP.Position

            local forward =
                targetHRP.CFrame.LookVector

            local right =
                targetHRP.CFrame.RightVector

            ------------------------------------------------------------
            -- JARAK DEPAN
            --
            -- Semakin besar angka = semakin jauh dari player
            ------------------------------------------------------------

            local row1 = 5
            local row2 = 8
            local row3 = 11
            local row4 = 14
            local row5 = 17
            local row6 = 20
            local row7 = 23

            ------------------------------------------------------------
            -- BOT 1
            ------------------------------------------------------------

            if index == 1 then

                return
                    origin
                    + forward * row1

            ------------------------------------------------------------
            -- BOT 2
            ------------------------------------------------------------

            elseif index == 2 then

                return
                    origin
                    + forward * row2
                    - right * 3

            ------------------------------------------------------------
            -- BOT 3
            ------------------------------------------------------------

            elseif index == 3 then

                return
                    origin
                    + forward * row2
                    + right * 3

            ------------------------------------------------------------
            -- BOT 4
            ------------------------------------------------------------

            elseif index == 4 then

                return
                    origin
                    + forward * row3
                    - right * 5

            ------------------------------------------------------------
            -- BOT 5
            ------------------------------------------------------------

            elseif index == 5 then

                return
                    origin
                    + forward * row3
                    + right * 5

            ------------------------------------------------------------
            -- BOT 6
            ------------------------------------------------------------

            elseif index == 6 then

                return
                    origin
                    + forward * row4
                    - right * 7

            ------------------------------------------------------------
            -- BOT 7
            ------------------------------------------------------------

            elseif index == 7 then

                return
                    origin
                    + forward * row4
                    + right * 7

            ------------------------------------------------------------
            -- BOT 8
            ------------------------------------------------------------

            elseif index == 8 then

                return
                    origin
                    + forward * row5
                    - right * 5

            ------------------------------------------------------------
            -- BOT 9
            ------------------------------------------------------------

            elseif index == 9 then

                return
                    origin
                    + forward * row5
                    + right * 5

            ------------------------------------------------------------
            -- BOT 10
            ------------------------------------------------------------

            elseif index == 10 then

                return
                    origin
                    + forward * row5
                    - right * 2

            ------------------------------------------------------------
            -- BOT 11
            ------------------------------------------------------------

            elseif index == 11 then

                return
                    origin
                    + forward * row5
                    + right * 2

            ------------------------------------------------------------
            -- BOT 12
            ------------------------------------------------------------

            elseif index == 12 then

                return
                    origin
                    + forward * row6
                    - right * 2

            ------------------------------------------------------------
            -- BOT 13
            ------------------------------------------------------------

            elseif index == 13 then

                return
                    origin
                    + forward * row6
                    + right * 2

            ------------------------------------------------------------
            -- BOT 14
            ------------------------------------------------------------

            elseif index == 14 then

                return
                    origin
                    + forward * row7

            end

        end

        ----------------------------------------------------------------
        -- START VANGUARD
        ----------------------------------------------------------------

        local function startVanguard(player)

            if not player then
                return
            end

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- CARI INDEX BOT
            ------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            ------------------------------------------------------------
            -- JIKA BUKAN BOT
            ------------------------------------------------------------

            if not myIndex then

                return

            end

            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode =
                "vanguard"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if vanguardConnection then

                vanguardConnection:Disconnect()
                vanguardConnection = nil

            end

            ------------------------------------------------------------
            -- SET STATE
            ------------------------------------------------------------

            active = true
            targetPlayer = player

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- VANGUARD LOOP
            ------------------------------------------------------------

            vanguardConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE BERUBAH
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "vanguard" then

                            stopVanguard()

                            return

                        end

                        ------------------------------------------------
                        -- VALIDASI
                        ------------------------------------------------

                        if not active then
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
                        -- TARGET CHARACTER
                        ------------------------------------------------

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

                        ------------------------------------------------
                        -- DISTANCE SPECIAL
                        ------------------------------------------------

                        local specialDistance =
                            Distance:GetDistance(
                                tostring(LocalPlayer.UserId),
                                tostring(targetPlayer.UserId)
                            )

                        ------------------------------------------------
                        -- FORMATION
                        ------------------------------------------------

                        local formationPosition =
                            getFormationPosition(
                                myIndex,
                                targetHRP
                            )

                        if not formationPosition then
                            return
                        end

                        ------------------------------------------------
                        -- APPLY SPECIAL DISTANCE
                        ------------------------------------------------

                        if specialDistance then

                            formationPosition =
                                formationPosition
                                +
                                (
                                    targetHRP.CFrame.LookVector
                                    *
                                    specialDistance
                                )

                        end

                        ------------------------------------------------
                        -- DISTANCE
                        ------------------------------------------------

                        local distance =
                            (
                                myHRP.Position
                                -
                                formationPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- MOVE
                        ------------------------------------------------

                        if distance > stopDistance then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                formationPosition
                            )

                            return

                        end

                        ------------------------------------------------
                        -- SUDAH SAMPAI
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        local targetRotation =
                            targetHRP.CFrame
                            -
                            targetHRP.Position

                        myHRP.CFrame =
                            CFrame.new(
                                myHRP.Position
                            )
                            *
                            targetRotation

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

            ------------------------------------------------------------
            -- VALIDASI
            ------------------------------------------------------------

            if not sender then
                return
            end

            if not message then
                return
            end

            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            ------------------------------------------------------------
            -- !VANGUARD
            ------------------------------------------------------------

            if lower == "!vanguard"
                or lower == "!vandguard" then

                startVanguard(sender)

                return

            end

            ------------------------------------------------------------
            -- !VANGUARD PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!vanguard%s+(.+)$"
                )

            ------------------------------------------------------------
            -- TYPO COMMAND
            ------------------------------------------------------------

            if not targetName then

                targetName =
                    lower:match(
                        "^!vandguard%s+(.+)$"
                    )

            end

            ------------------------------------------------------------
            -- TARGET PLAYER
            ------------------------------------------------------------

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startVanguard(
                        target
                    )

                end

                return

            end

            ------------------------------------------------------------
            -- STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unvanguard" then

                _G.BotVars.ActiveMode = nil

                stopVanguard()

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
                    == "vanguard"
                    and targetPlayer then

                    startVanguard(
                        targetPlayer
                    )

                end

            end
        )

    end
}