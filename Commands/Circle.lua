return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            return
        end

        --------------------------------------------------
        -- GLOBAL VARIABLES
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        local vars = _G.BotVars

        vars.ModeControllers =
            vars.ModeControllers or {}

        --------------------------------------------------
        -- LOAD ADMIN
        --------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        if not Admin then
            warn("[CIRCLE] Gagal load Admin.lua")
            return
        end

        --------------------------------------------------
        -- LOAD DISTANCE
        --------------------------------------------------

        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        if not Distance then
            warn("[CIRCLE] Gagal load Distance.lua")
            return
        end

        --------------------------------------------------
        -- CHARACTER
        --------------------------------------------------

        local humanoid = nil
        local myHRP = nil

        --------------------------------------------------
        -- STATE
        --------------------------------------------------

        local circleActive = false
        local circleConnection = nil
        local targetPlayer = nil

        --------------------------------------------------
        -- BOT ORDER
        --------------------------------------------------

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

        --------------------------------------------------
        -- CIRCLE SETTINGS
        --------------------------------------------------

        local circleRadius = 8
        local stopThreshold = 1.5

        --------------------------------------------------
        -- UPDATE CHARACTER
        --------------------------------------------------

        local function updateCharacter()

            local character =
                LocalPlayer.Character

            if not character then
                character =
                    LocalPlayer.CharacterAdded:Wait()
            end

            humanoid =
                character:WaitForChild(
                    "Humanoid",
                    10
                )

            myHRP =
                character:WaitForChild(
                    "HumanoidRootPart",
                    10
                )

            if humanoid then
                humanoid.AutoRotate = true
            end

            print(
                "[CIRCLE] Character updated:",
                LocalPlayer.Name
            )

        end

        updateCharacter()

        --------------------------------------------------
        -- STOP CIRCLE
        --------------------------------------------------

        local function stopCircle()

            circleActive = false
            targetPlayer = nil

            if circleConnection then

                circleConnection:Disconnect()
                circleConnection = nil

            end

            if humanoid then
                humanoid.AutoRotate = true
            end

            print(
                "[CIRCLE] Stopped"
            )

        end

        --------------------------------------------------
        -- REGISTER CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.circle =
            stopCircle

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
            ) do

                if name ~= "circle"
                    and type(stopFunction) == "function" then

                    pcall(function()
                        stopFunction()
                    end)

                end

            end

        end

        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayerByName(name)

            if not name or name == "" then
                return nil
            end

            name = name:lower()

            --------------------------------------------------
            -- EXACT MATCH
            --------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            --------------------------------------------------
            -- PARTIAL MATCH
            --------------------------------------------------

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

        --------------------------------------------------
        -- GET BOT INDEX
        --------------------------------------------------

        local function getBotIndex()

            return table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            )

        end

        --------------------------------------------------
        -- GET BOT DISTANCE
        --------------------------------------------------

        local function getBotDistance(player)

            local distance = 5

            --------------------------------------------------
            -- ADMIN DEFAULT
            --------------------------------------------------

            if Admin:IsAdmin(player) then
                distance = 5
            end

            --------------------------------------------------
            -- SPECIAL DISTANCE
            --------------------------------------------------

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

        --------------------------------------------------
        -- GET CIRCLE POSITION
        --------------------------------------------------

        local function getCirclePosition(
            myIndex,
            targetHRP,
            distance
        )

            if not myIndex
                or not targetHRP then

                return nil
            end

            --------------------------------------------------
            -- TOTAL BOT
            --------------------------------------------------

            local totalBots =
                #botOrder

            if totalBots <= 0 then
                return nil
            end

            --------------------------------------------------
            -- ANGLE
            --------------------------------------------------

            local angle =
                ((myIndex - 1) / totalBots)
                * math.pi
                * 2

            --------------------------------------------------
            -- RADIUS
            --------------------------------------------------

            local radius =
                circleRadius + distance

            --------------------------------------------------
            -- AXIS
            --------------------------------------------------

            local forward =
                targetHRP.CFrame.LookVector

            local right =
                targetHRP.CFrame.RightVector

            local origin =
                targetHRP.Position

            --------------------------------------------------
            -- OFFSET
            --------------------------------------------------

            local forwardOffset =
                math.cos(angle) * radius

            local rightOffset =
                math.sin(angle) * radius

            --------------------------------------------------
            -- POSITION
            --------------------------------------------------

            return origin
                + forward * forwardOffset
                + right * rightOffset

        end

        --------------------------------------------------
        -- FACE TARGET
        --------------------------------------------------

        local function faceTarget(targetHRP)

            if not targetHRP
                or not myHRP then

                return
            end

            local targetPosition =
                targetHRP.Position

            local lookPosition =
                Vector3.new(
                    targetPosition.X,
                    myHRP.Position.Y,
                    targetPosition.Z
                )

            myHRP.CFrame =
                CFrame.lookAt(
                    myHRP.Position,
                    lookPosition
                )

        end

        --------------------------------------------------
        -- START CIRCLE
        --------------------------------------------------

        local function startCircle(player)

            if not player then
                return
            end

            --------------------------------------------------
            -- CHECK BOT INDEX FIRST
            --------------------------------------------------

            local myIndex =
                getBotIndex()

            if not myIndex then

                warn(
                    "[CIRCLE] Bot tidak terdaftar:",
                    LocalPlayer.Name,
                    LocalPlayer.UserId
                )

                return

            end

            --------------------------------------------------
            -- STOP MODE LAIN
            --------------------------------------------------

            stopOtherModes()

            --------------------------------------------------
            -- STOP CONNECTION LAMA
            --------------------------------------------------

            if circleConnection then

                circleConnection:Disconnect()
                circleConnection = nil

            end

            --------------------------------------------------
            -- ACTIVE MODE
            --------------------------------------------------

            vars.ActiveMode =
                "circle"

            circleActive = true
            targetPlayer = player

            print(
                "[CIRCLE] Started",
                "Target:",
                player.Name,
                "Bot Index:",
                myIndex
            )

            --------------------------------------------------
            -- HEARTBEAT
            --------------------------------------------------

            circleConnection =
                RunService.Heartbeat:Connect(
                    function()

                        --------------------------------------------------
                        -- MODE CHECK
                        --------------------------------------------------

                        if vars.ActiveMode
                            ~= "circle" then

                            stopCircle()
                            return

                        end

                        --------------------------------------------------
                        -- ACTIVE CHECK
                        --------------------------------------------------

                        if not circleActive then
                            return
                        end

                        --------------------------------------------------
                        -- CHARACTER CHECK
                        --------------------------------------------------

                        if not humanoid
                            or not myHRP then

                            return

                        end

                        --------------------------------------------------
                        -- TARGET CHECK
                        --------------------------------------------------

                        if not targetPlayer then
                            return
                        end

                        --------------------------------------------------
                        -- TARGET CHARACTER
                        --------------------------------------------------

                        local targetCharacter =
                            targetPlayer.Character

                        if not targetCharacter then
                            return
                        end

                        --------------------------------------------------
                        -- TARGET HRP
                        --------------------------------------------------

                        local targetHRP =
                            targetCharacter:FindFirstChild(
                                "HumanoidRootPart"
                            )

                        if not targetHRP then
                            return
                        end

                        --------------------------------------------------
                        -- DISTANCE
                        --------------------------------------------------

                        local botDistance =
                            getBotDistance(
                                targetPlayer
                            )

                        --------------------------------------------------
                        -- POSITION
                        --------------------------------------------------

                        local targetPosition =
                            getCirclePosition(
                                myIndex,
                                targetHRP,
                                botDistance
                            )

                        if not targetPosition then
                            return
                        end

                        --------------------------------------------------
                        -- DISTANCE TO POSITION
                        --------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                - targetPosition
                            ).Magnitude

                        --------------------------------------------------
                        -- MOVE
                        --------------------------------------------------

                        if distanceToTarget
                            > stopThreshold then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        --------------------------------------------------
                        -- REACHED POSITION
                        --------------------------------------------------

                        humanoid.AutoRotate = false

                        --------------------------------------------------
                        -- FACE CENTER
                        --------------------------------------------------

                        faceTarget(
                            targetHRP
                        )

                    end
                )

        end

        --------------------------------------------------
        -- HANDLE COMMAND
        --------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            if not message or not sender then
                return
            end

            --------------------------------------------------
            -- ADMIN ONLY
            --------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower():match("^%s*(.-)%s*$")

            --------------------------------------------------
            -- !CIRCLE
            --------------------------------------------------

            if lower == "!circle" then

                startCircle(sender)

                return

            end

            --------------------------------------------------
            -- !CIRCLE PLAYER
            --------------------------------------------------

            local targetName =
                lower:match(
                    "^!circle%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startCircle(
                        target
                    )

                else

                    warn(
                        "[CIRCLE] Target tidak ditemukan:",
                        targetName
                    )

                end

                return

            end

            --------------------------------------------------
            -- !STOP
            --------------------------------------------------

            if lower == "!stop"
                or lower == "!uncircle" then

                vars.ActiveMode = nil

                stopCircle()

                return

            end

        end

        --------------------------------------------------
        -- COMMAND HANDLER
        --------------------------------------------------
        -- PENTING:
        -- JANGAN memasang OnIncomingMessage di sini.
        --
        -- Bot.lua yang menjadi satu-satunya pengelola chat.
        --------------------------------------------------

        vars.CommandHandlers =
            vars.CommandHandlers or {}

        vars.CommandHandlers.circle =
            handleCommand

        --------------------------------------------------
        -- PLAYER CHAT FALLBACK
        --------------------------------------------------
        -- Tetap digunakan untuk kompatibilitas.
        -- Bot.lua juga akan menangani TextChatService.
        --------------------------------------------------

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

        --------------------------------------------------
        -- PLAYER ADDED
        --------------------------------------------------

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

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()

                --------------------------------------------------
                -- RESTART CIRCLE
                --------------------------------------------------

                if vars.ActiveMode
                    == "circle"
                    and targetPlayer then

                    local target =
                        targetPlayer

                    startCircle(
                        target
                    )

                end

            end
        )

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print(
            "[CIRCLE] Circle.lua aktif!"
        )

    end
}