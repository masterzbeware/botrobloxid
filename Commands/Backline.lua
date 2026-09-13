return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[BACKLINE] LocalPlayer tidak ditemukan")
            return
        end

        ----------------------------------------------------------------
        -- GLOBAL VARIABLES
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        local vars = _G.BotVars

        vars.ModeControllers =
            vars.ModeControllers or {}

        vars.CommandHandlers =
            vars.CommandHandlers or {}

        ----------------------------------------------------------------
        -- LOAD ADMIN
        ----------------------------------------------------------------

        local Admin

        do
            local success, result = pcall(function()

                return loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
                ))()

            end)

            if not success or not result then

                warn(
                    "[BACKLINE] Gagal load Admin.lua:",
                    result
                )

                return

            end

            Admin = result
        end

        ----------------------------------------------------------------
        -- LOAD DISTANCE
        ----------------------------------------------------------------

        local Distance

        do
            local success, result = pcall(function()

                return loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
                ))()

            end)

            if not success or not result then

                warn(
                    "[BACKLINE] Gagal load Distance.lua:",
                    result
                )

                return

            end

            Distance = result
        end

        ----------------------------------------------------------------
        -- CHARACTER
        ----------------------------------------------------------------

        local humanoid = nil
        local myHRP = nil

        ----------------------------------------------------------------
        -- STATE
        ----------------------------------------------------------------

        local backlineActive = false
        local backlineConnection = nil
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
                character:WaitForChild(
                    "Humanoid"
                )

            myHRP =
                character:WaitForChild(
                    "HumanoidRootPart"
                )

            humanoid.AutoRotate = true

            print(
                "[BACKLINE] Character updated"
            )

        end

        updateCharacter()

        ----------------------------------------------------------------
        -- SEND CHAT
        ----------------------------------------------------------------

        local function sendChat(message)

            if not message then
                return
            end

            local success = false

            ------------------------------------------------------------
            -- TEXT CHAT
            ------------------------------------------------------------

            local TextChatService =
                game:GetService("TextChatService")

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then

                    local ok = pcall(function()

                        channel:SendAsync(
                            message
                        )

                    end)

                    if ok then
                        success = true
                    end

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
        -- STOP BACKLINE
        ----------------------------------------------------------------

        local function stopBackline()

            backlineActive = false
            targetPlayer = nil

            if backlineConnection then

                backlineConnection:Disconnect()
                backlineConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

            print("[BACKLINE] Stopped")

        end

        ----------------------------------------------------------------
        -- REGISTER MODE CONTROLLER
        ----------------------------------------------------------------

        vars.ModeControllers.backline =
            stopBackline

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
            ) do

                if name ~= "backline"
                    and type(stopFunction) == "function" then

                    pcall(function()

                        stopFunction()

                    end)

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

            local success, specialDistance =
                pcall(function()

                    return Distance:GetDistance(
                        tostring(LocalPlayer.UserId),
                        tostring(player.UserId)
                    )

                end)

            if success and specialDistance then

                distance = specialDistance

            end

            return distance

        end

        ----------------------------------------------------------------
        -- GET BACKLINE POSITION
        ----------------------------------------------------------------

        local function getBacklinePosition(
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
            -- TOTAL BOT
            ------------------------------------------------------------

            local totalBots =
                #botOrder

            ------------------------------------------------------------
            -- CENTER
            ------------------------------------------------------------

            local center =
                (totalBots + 1) / 2

            ------------------------------------------------------------
            -- LEFT / RIGHT
            ------------------------------------------------------------

            local horizontalOffset =
                (myIndex - center)
                * formationSpacing

            ------------------------------------------------------------
            -- BACK OF PLAYER
            ------------------------------------------------------------

            local backPosition =
                targetHRP.Position
                +
                (
                    -targetHRP.CFrame.LookVector
                    *
                    (
                        formationDistance
                        + distance
                    )
                )

            ------------------------------------------------------------
            -- SIDE
            ------------------------------------------------------------

            local sidePosition =
                targetHRP.CFrame.RightVector
                * horizontalOffset

            ------------------------------------------------------------
            -- FINAL
            ------------------------------------------------------------

            return backPosition
                + sidePosition
                + Vector3.new(
                    0,
                    formationHeight,
                    0
                )

        end

        ----------------------------------------------------------------
        -- COPY TARGET ROTATION
        ----------------------------------------------------------------

        local function copyTargetRotation(
            targetHRP
        )

            if not targetHRP
                or not myHRP then

                return

            end

            local targetRotation =
                targetHRP.CFrame
                - targetHRP.Position

            myHRP.CFrame =
                CFrame.new(
                    myHRP.Position
                )
                * targetRotation

        end

        ----------------------------------------------------------------
        -- START BACKLINE
        ----------------------------------------------------------------

        local function startBackline(player)

            if not player then

                warn(
                    "[BACKLINE] Target player tidak ditemukan"
                )

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
                "backline"

            ------------------------------------------------------------
            -- DISCONNECT LOOP LAMA
            ------------------------------------------------------------

            if backlineConnection then

                backlineConnection:Disconnect()
                backlineConnection = nil

            end

            ------------------------------------------------------------
            -- STATE
            ------------------------------------------------------------

            backlineActive = true
            targetPlayer = player

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- BOT INDEX
            ------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(
                        LocalPlayer.UserId
                    )
                )

            if not myIndex then

                warn(
                    "[BACKLINE] Bot tidak terdaftar:",
                    LocalPlayer.UserId
                )

                stopBackline()

                vars.ActiveMode = nil

                return

            end

            print(
                "[BACKLINE] START",
                "Bot Index:",
                myIndex,
                "Target:",
                player.Name
            )

            ------------------------------------------------------------
            -- HEARTBEAT
            ------------------------------------------------------------

            backlineConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE CHECK
                        ------------------------------------------------

                        if vars.ActiveMode
                            ~= "backline" then

                            stopBackline()

                            return

                        end

                        ------------------------------------------------
                        -- ACTIVE CHECK
                        ------------------------------------------------

                        if not backlineActive then
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
                            getBacklinePosition(
                                myIndex,
                                targetHRP,
                                botDistance
                            )

                        if not targetPosition then
                            return
                        end

                        ------------------------------------------------
                        -- DISTANCE TO TARGET
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

                            humanoid.AutoRotate =
                                true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ------------------------------------------------
                        -- ARRIVED
                        ------------------------------------------------

                        humanoid.AutoRotate =
                            false

                        ------------------------------------------------
                        -- COPY ROTATION
                        ------------------------------------------------

                        copyTargetRotation(
                            targetHRP
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
            -- ADMIN CHECK
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower():match("^%s*(.-)%s*$")

            ------------------------------------------------------------
            -- !BACKLINE
            ------------------------------------------------------------

            if lower == "!backline" then

                startBackline(sender)

                return true

            end

            ------------------------------------------------------------
            -- !BACKLINE PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!backline%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startBackline(
                        target
                    )

                else

                    warn(
                        "[BACKLINE] Player tidak ditemukan:",
                        targetName
                    )

                end

                return true

            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unbackline" then

                if vars.ActiveMode
                    == "backline" then

                    vars.ActiveMode = nil

                    stopBackline()

                end

                return true

            end

            return false

        end

        ----------------------------------------------------------------
        -- REGISTER COMMAND KE CENTRAL BOT
        ----------------------------------------------------------------

        vars.CommandHandlers.backline =
            handleCommand

        print(
            "[BACKLINE] Command handler registered"
        )

        ----------------------------------------------------------------
        -- RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()

                --------------------------------------------------------
                -- RESTART BACKLINE
                --------------------------------------------------------

                if vars.ActiveMode
                    == "backline"
                    and targetPlayer then

                    local target =
                        targetPlayer

                    startBackline(
                        target
                    )

                end

            end
        )

        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "✅ [BACKLINE] System ready"
        )

    end
}