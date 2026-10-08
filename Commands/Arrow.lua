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

        local arrowing = false
        local targetPlayer = nil
        local arrowConnection = nil

        ----------------------------------------------------------------
        -- FORMATION SETTINGS
        ----------------------------------------------------------------

        local botSpacing = 3
        local rowSpacing = 3

        local adminArrowDistance = 3
        local defaultBotArrowDistance = 3

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
        -- STOP ARROW
        ----------------------------------------------------------------
        --
        -- PENTING:
        -- Jangan hapus CommandTarget di sini.
        --
        -- CommandTarget hanya dihapus oleh:
        -- Admin -> !stop
        --
        ----------------------------------------------------------------

        local function stopArrow()

            arrowing = false
            targetPlayer = nil

            if arrowConnection then

                arrowConnection:Disconnect()
                arrowConnection = nil

            end

            if humanoid then
                humanoid.AutoRotate = true
            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.arrow =
            stopArrow

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "arrow"
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

            ------------------------------------------------------------
            -- EXACT USERNAME / DISPLAY NAME
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
            -- USERNAME PREFIX
            ------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower():sub(
                    1,
                    #name
                ) == name then

                    return player

                end

            end

            return nil

        end

        ----------------------------------------------------------------
        -- GET ARROW FORMATION OFFSET
        ----------------------------------------------------------------
        --
        -- FORMASI:
        --
        -- B10  B9  B8  B7
        --
        -- B6          B5
        --
        --    B4  B3  B2
        --
        --        B1  A
        --
        ----------------------------------------------------------------

        local function getArrowOffset(
            index,
            distance
        )

            ------------------------------------------------------------
            -- B1
            ------------------------------------------------------------

            if index == 1 then

                return Vector3.new(
                    -botSpacing,
                    0,
                    0
                )

            end

            ------------------------------------------------------------
            -- B2 B3 B4
            ------------------------------------------------------------

            if index >= 2 and index <= 4 then

                local column =
                    index - 2

                local x =
                    (column - 1)
                    * botSpacing

                local z =
                    -(distance + rowSpacing)

                return Vector3.new(
                    x,
                    0,
                    z
                )

            end

            ------------------------------------------------------------
            -- B5
            ------------------------------------------------------------

            if index == 5 then

                return Vector3.new(
                    botSpacing * 2,
                    0,
                    -(distance + rowSpacing * 2)
                )

            end

            ------------------------------------------------------------
            -- B6
            ------------------------------------------------------------

            if index == 6 then

                return Vector3.new(
                    -botSpacing * 2,
                    0,
                    -(distance + rowSpacing * 2)
                )

            end

            ------------------------------------------------------------
            -- B7 B8 B9 B10
            ------------------------------------------------------------

            if index >= 7 and index <= 10 then

                local column =
                    index - 7

                local x =
                    (column - 1.5)
                    * botSpacing

                local z =
                    -(distance + rowSpacing * 3)

                return Vector3.new(
                    x,
                    0,
                    z
                )

            end

            ------------------------------------------------------------
            -- B11 B12
            --
            -- Tambahan baris paling belakang.
            ------------------------------------------------------------

            if index == 11 or index == 12 then

                local column =
                    index - 11

                local x =
                    (column - 0.5)
                    * botSpacing

                local z =
                    -(distance + rowSpacing * 4)

                return Vector3.new(
                    x,
                    0,
                    z
                )

            end

            ------------------------------------------------------------
            -- FALLBACK
            ------------------------------------------------------------

            return Vector3.zero

        end

        ----------------------------------------------------------------
        -- START ARROW
        ----------------------------------------------------------------

        local function startArrow(player)

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

            _G.BotVars.ActiveMode = "arrow"

            ------------------------------------------------------------
            -- SET COMMAND TARGET
            ------------------------------------------------------------

            _G.BotVars.CommandTarget = player

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if arrowConnection then

                arrowConnection:Disconnect()
                arrowConnection = nil

            end

            arrowing = true
            targetPlayer = player

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- CARI INDEX BOT
            ------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            if not myIndex then

                stopArrow()

                return

            end

            ------------------------------------------------------------
            -- ARROW LOOP
            ------------------------------------------------------------

            arrowConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE SUDAH BERGANTI
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode ~= "arrow" then

                            stopArrow()

                            return

                        end

                        ------------------------------------------------
                        -- VALIDASI
                        ------------------------------------------------

                        if not arrowing then
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
                        -- DISTANCE
                        ------------------------------------------------

                        local distance =
                            defaultBotArrowDistance

                        if Admin:IsAdmin(targetPlayer) then

                            distance =
                                adminArrowDistance

                        end

                        ------------------------------------------------
                        -- SPECIAL DISTANCE
                        ------------------------------------------------

                        local specialDistance =
                            Distance:GetDistance(
                                tostring(LocalPlayer.UserId),
                                tostring(targetPlayer.UserId)
                            )

                        if specialDistance then

                            distance =
                                specialDistance

                        end

                        ------------------------------------------------
                        -- FORMATION OFFSET
                        ------------------------------------------------

                        local arrowOffset =
                            getArrowOffset(
                                myIndex,
                                distance
                            )

                        ------------------------------------------------
                        -- CONVERT LOCAL OFFSET
                        -- TO WORLD POSITION
                        ------------------------------------------------

                        local right =
                            targetHRP.CFrame.RightVector

                        local forward =
                            targetHRP.CFrame.LookVector

                        local targetPosition =
                            targetHRP.Position
                            +
                            (right * arrowOffset.X)
                            +
                            (forward * arrowOffset.Z)

                        ------------------------------------------------
                        -- DISTANCE TO POSITION
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- MOVE
                        ------------------------------------------------

                        if distanceToTarget > 1.5 then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ------------------------------------------------
                        -- SUDAH SAMPAI
                        -- HADAP SAMA DENGAN TARGET
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        myHRP.CFrame =
                            CFrame.lookAt(
                                myHRP.Position,
                                myHRP.Position
                                    + targetHRP.CFrame.LookVector
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

            if not message
                or not sender then

                return

            end

            ------------------------------------------------------------
            -- CHECK ADMIN
            ------------------------------------------------------------

            local isAdmin = false

            pcall(function()

                isAdmin =
                    Admin:IsAdmin(sender)

            end)

            ------------------------------------------------------------
            -- NORMALIZE MESSAGE
            ------------------------------------------------------------

            local lower =
                message
                :lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            ------------------------------------------------------------
            -- CURRENT COMMAND TARGET
            ------------------------------------------------------------

            local commandTarget =
                _G.BotVars.CommandTarget

            ------------------------------------------------------------
            -- CHECK CURRENT TARGET
            ------------------------------------------------------------

            local isCommandTarget =
                commandTarget == sender

            ------------------------------------------------------------
            -- !STOP
            --
            -- HANYA ADMIN
            ------------------------------------------------------------

            if lower == "!stop" then

                if not isAdmin then
                    return
                end

                --------------------------------------------------------
                -- CLEAR GLOBAL STATE
                --------------------------------------------------------

                _G.BotVars.ActiveMode = nil
                _G.BotVars.CommandTarget = nil

                --------------------------------------------------------
                -- STOP SEMUA MODE
                --------------------------------------------------------

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
            -- !UNARROW
            --
            -- HANYA ADMIN
            --
            -- !unarrow hanya menghentikan Arrow.
            -- CommandTarget TIDAK dihapus.
            --
            ------------------------------------------------------------

            if lower == "!unarrow" then

                if not isAdmin then
                    return
                end

                if _G.BotVars.ActiveMode == "arrow" then

                    _G.BotVars.ActiveMode = nil

                end

                stopArrow()

                return

            end

            ------------------------------------------------------------
            -- !ARROW
            --
            -- ADMIN:
            -- !arrow
            --
            -- COMMAND TARGET:
            -- !arrow
            --
            -- KEDUANYA MENJADIKAN DIRINYA SENDIRI TARGET.
            ------------------------------------------------------------

            if lower == "!arrow" then

                if not isAdmin
                    and not isCommandTarget then

                    return

                end

                _G.BotVars.CommandTarget =
                    sender

                startArrow(sender)

                return

            end

            ------------------------------------------------------------
            -- !ARROW PLAYER
            --
            -- HANYA ADMIN
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!arrow%s+(.+)$"
                )

            if targetName then

                if not isAdmin then
                    return
                end

                local target =
                    findPlayerByName(
                        targetName
                    )

                if not target then
                    return
                end

                _G.BotVars.CommandTarget =
                    target

                startArrow(target)

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
                )

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

                if _G.BotVars.ActiveMode == "arrow"
                    and targetPlayer then

                    startArrow(
                        targetPlayer
                    )

                end

            end
        )

        ----------------------------------------------------------------
        -- DONE
        ----------------------------------------------------------------

        print(
            "[Arrow] Arrow formation system loaded."
        )

    end
}