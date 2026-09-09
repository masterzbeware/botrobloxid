return {
    Execute = function()
        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")

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

        local vars = _G.BotVars

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
        -- CHARACTER
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        ----------------------------------------------------------------
        -- STATE
        ----------------------------------------------------------------

        local frontlineRightActive = false
        local frontlineRightConnection = nil
        local targetPlayer = nil

        ----------------------------------------------------------------
        -- FORMATION SETTINGS
        ----------------------------------------------------------------

        local formationDistance = 5
        local formationSpacing = 3
        local stopThreshold = 1.5
        local formationHeight = 0

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

            if not message then
                return
            end

            local channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

            if not channel then
                warn(
                    "[FRONTLINE RIGHT] RBXGeneral tidak ditemukan"
                )
                return
            end

            pcall(function()
                channel:SendAsync(message)
            end)

        end

        ----------------------------------------------------------------
        -- STOP FRONTLINE RIGHT
        ----------------------------------------------------------------

        local function stopFrontlineRight()

            frontlineRightActive = false
            targetPlayer = nil

            if frontlineRightConnection then

                frontlineRightConnection:Disconnect()
                frontlineRightConnection = nil

            end

            if humanoid then
                humanoid.AutoRotate = true
            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        vars.ModeControllers.frontlineright =
            stopFrontlineRight

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
            ) do

                if name ~= "frontlineright"
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
            -- EXACT MATCH
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
            -- PARTIAL MATCH
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
        -- GET BOT DISTANCE
        ----------------------------------------------------------------

        local function getBotDistance(player)

            local distance = 1

            ------------------------------------------------------------
            -- ADMIN DEFAULT
            ------------------------------------------------------------

            if Admin:IsAdmin(player) then
                distance = 1
            end

            ------------------------------------------------------------
            -- SPECIAL DISTANCE
            ------------------------------------------------------------

            local specialDistance =
                Distance:GetDistance(
                    tostring(LocalPlayer.UserId),
                    tostring(player.UserId)
                )

            if specialDistance then
                distance = specialDistance
            end

            return distance

        end

        ----------------------------------------------------------------
        -- GET FRONTLINE RIGHT POSITION
        ----------------------------------------------------------------

        local function getFrontlinePosition(
            myIndex,
            targetHRP,
            distance
        )

            if not myIndex
                or not targetHRP
                or not distance then

                return nil

            end

            ------------------------------------------------------------
            -- JUMLAH BOT
            ------------------------------------------------------------

            local totalBots =
                #botOrder

            ------------------------------------------------------------
            -- POSISI TENGAH
            ------------------------------------------------------------

            local center =
                (totalBots + 1) / 2

            ------------------------------------------------------------
            -- OFFSET KIRI / KANAN
            ------------------------------------------------------------

            local horizontalOffset =
                (myIndex - center)
                * formationSpacing

            ------------------------------------------------------------
            -- DEPAN PLAYER
            ------------------------------------------------------------

            local frontPosition =
                targetHRP.Position
                +
                (
                    targetHRP.CFrame.LookVector
                    *
                    (
                        formationDistance
                        + distance
                    )
                )

            ------------------------------------------------------------
            -- KIRI / KANAN
            ------------------------------------------------------------

            local sidePosition =
                targetHRP.CFrame.RightVector
                * horizontalOffset

            ------------------------------------------------------------
            -- FINAL POSITION
            ------------------------------------------------------------

            return frontPosition
                + sidePosition
                + Vector3.new(
                    0,
                    formationHeight,
                    0
                )

        end

        ----------------------------------------------------------------
        -- FACE RIGHT
        ----------------------------------------------------------------
        --
        -- Player menghadap:
        --
        --        DEPAN
        --          ↑
        --          |
        --
        -- PLAYER → RIGHT
        --
        -- Bot akan menghadap 90 derajat ke KANAN
        -- dari arah hadap player.
        --
        ----------------------------------------------------------------

        local function faceRight(
            targetHRP
        )

            if not targetHRP
                or not myHRP then

                return

            end

            ------------------------------------------------------------
            -- ARAH KANAN DARI PLAYER
            ------------------------------------------------------------

            local rightVector =
                targetHRP.CFrame.RightVector

            ------------------------------------------------------------
            -- BUAT CFrame MENGHADAP KANAN
            ------------------------------------------------------------

            myHRP.CFrame =
                CFrame.lookAt(
                    myHRP.Position,
                    myHRP.Position + rightVector
                )

        end

        ----------------------------------------------------------------
        -- START FRONTLINE RIGHT
        ----------------------------------------------------------------

        local function startFrontlineRight(player)

            if not player then
                return
            end

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- ACTIVE MODE
            ------------------------------------------------------------

            vars.ActiveMode =
                "frontlineright"

            ------------------------------------------------------------
            -- DISCONNECT LOOP LAMA
            ------------------------------------------------------------

            if frontlineRightConnection then

                frontlineRightConnection:Disconnect()
                frontlineRightConnection = nil

            end

            ------------------------------------------------------------
            -- STATE
            ------------------------------------------------------------

            frontlineRightActive = true
            targetPlayer = player

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- FIND BOT INDEX
            ------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            ------------------------------------------------------------
            -- BOT TIDAK ADA DI FRONTLINE
            ------------------------------------------------------------

            if not myIndex then

                print(
                    "[FRONTLINE RIGHT]",
                    "Bot ini bukan Bot 1-11:",
                    LocalPlayer.UserId
                )

                stopFrontlineRight()

                return

            end

            ------------------------------------------------------------
            -- DEBUG
            ------------------------------------------------------------

            print(
                "[FRONTLINE RIGHT]",
                "Bot Index:",
                myIndex,
                "UserId:",
                LocalPlayer.UserId
            )

            ------------------------------------------------------------
            -- HEARTBEAT
            ------------------------------------------------------------

            frontlineRightConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE CHECK
                        ------------------------------------------------

                        if vars.ActiveMode
                            ~= "frontlineright" then

                            stopFrontlineRight()

                            return

                        end

                        ------------------------------------------------
                        -- ACTIVE CHECK
                        ------------------------------------------------

                        if not frontlineRightActive then
                            return
                        end

                        ------------------------------------------------
                        -- CHARACTER CHECK
                        ------------------------------------------------

                        if not humanoid
                            or not myHRP then

                            return

                        end

                        ------------------------------------------------
                        -- TARGET CHECK
                        ------------------------------------------------

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

                        ------------------------------------------------
                        -- TARGET HRP
                        ------------------------------------------------

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

                        local botDistance =
                            getBotDistance(
                                targetPlayer
                            )

                        ------------------------------------------------
                        -- POSITION
                        ------------------------------------------------

                        local targetPosition =
                            getFrontlinePosition(
                                myIndex,
                                targetHRP,
                                botDistance
                            )

                        if not targetPosition then
                            return
                        end

                        ------------------------------------------------
                        -- DISTANCE TO FORMATION
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

                        if distanceToTarget
                            > stopThreshold then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ------------------------------------------------
                        -- SUDAH SAMPAI
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        ------------------------------------------------
                        -- MENGHADAP KANAN
                        ------------------------------------------------

                        faceRight(
                            targetHRP
                        )

                    end
                )

        end

        ----------------------------------------------------------------
        -- HANDLE COMMAND
        ----------------------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            ------------------------------------------------------------
            -- ADMIN ONLY
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            ------------------------------------------------------------
            -- !FRONTLINERIGHT
            ------------------------------------------------------------

            if lower == "!frontlineright" then

                startFrontlineRight(
                    sender
                )

                return

            end

            ------------------------------------------------------------
            -- !FRONTLINERIGHT PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!frontlineright%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startFrontlineRight(
                        target
                    )

                end

                return

            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unfrontlineright" then

                vars.ActiveMode = nil

                stopFrontlineRight()

                return

            end

        end

        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE
        ----------------------------------------------------------------

        TextChatService.MessageReceived:Connect(
            function(message)

                if not message.TextSource then
                    return
                end

                local userId =
                    message.TextSource.UserId

                local sender =
                    Players:GetPlayerByUserId(
                        userId
                    )

                if not sender then
                    return
                end

                handleCommand(
                    message.Text,
                    sender
                )

            end
        )

        ----------------------------------------------------------------
        -- RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()

                --------------------------------------------------------
                -- RESTART FRONTLINE RIGHT
                --------------------------------------------------------

                if vars.ActiveMode
                    == "frontlineright"
                    and targetPlayer then

                    startFrontlineRight(
                        targetPlayer
                    )

                end

            end
        )

        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[FRONTLINE RIGHT] FrontlineRight.lua aktif!"
        )

    end
}