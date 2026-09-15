return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local PathfindingService = game:GetService("PathfindingService")

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
        -- DISTANCE
        ----------------------------------------------------------------

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2

        ----------------------------------------------------------------
        -- SMART FOLLOW SETTINGS
        ----------------------------------------------------------------

        -- Seberapa sering path dihitung ulang.
        local pathUpdateInterval = 0.35

        -- Jarak waypoint dianggap sudah tercapai.
        local waypointReachDistance = 2

        -- Jika target berada lebih tinggi dari bot sebesar ini,
        -- bot akan mencoba lompat.
        local verticalJumpThreshold = 2.2

        -- Jika target mempunyai velocity Y sebesar ini,
        -- dianggap sedang melakukan lompatan.
        local jumpVelocityThreshold = 5

        -- Prediksi gerakan target.
        local predictionTime = 0.12

        -- Jangan spam Jump() setiap frame.
        local jumpCooldown = 0.45

        ----------------------------------------------------------------
        -- PATH VARIABLES
        ----------------------------------------------------------------

        local currentPath = nil
        local currentWaypoints = {}
        local currentWaypointIndex = 0

        local lastPathUpdate = 0
        local lastJumpTime = 0

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

        local botOrder = {

            "11611503633", -- Bot 1
            "11611534165", -- Bot 2
            "11611567975", -- Bot 3
            "11611562042", -- Bot 4
            "11611591921", -- Bot 5
            "11611597741", -- Bot 6
            "11122806815", -- Bot 7
            "11122806817", -- Bot 8
            "11122687468", -- Bot 9
            "11122854402", -- Bot 10
            "11641280895", -- Bot 11
            "11641342530", -- Bot 12

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
        -- RESET PATH
        ----------------------------------------------------------------

        local function resetPath()

            currentPath = nil
            currentWaypoints = {}
            currentWaypointIndex = 0
            lastPathUpdate = 0

        end

        ----------------------------------------------------------------
        -- SMART JUMP
        ----------------------------------------------------------------

        local function tryJump()

            if not humanoid then
                return
            end

            local now = tick()

            if now - lastJumpTime < jumpCooldown then
                return
            end

            local state = humanoid:GetState()

            if state == Enum.HumanoidStateType.Jumping
                or state == Enum.HumanoidStateType.Freefall
                or state == Enum.HumanoidStateType.FallingDown then

                return

            end

            lastJumpTime = now

            pcall(function()

                humanoid.Jump = true

            end)

        end

        ----------------------------------------------------------------
        -- CHECK TARGET JUMP
        ----------------------------------------------------------------

        local function targetIsJumping(targetHumanoid)

            if not targetHumanoid then
                return false
            end

            local state =
                targetHumanoid:GetState()

            ------------------------------------------------------------
            -- STATE JUMP
            ------------------------------------------------------------

            if state == Enum.HumanoidStateType.Jumping then
                return true
            end

            ------------------------------------------------------------
            -- FREEFALL
            ------------------------------------------------------------

            if state == Enum.HumanoidStateType.Freefall then
                return true
            end

            ------------------------------------------------------------
            -- FALLING DOWN
            ------------------------------------------------------------

            if state == Enum.HumanoidStateType.FallingDown then
                return true
            end

            ------------------------------------------------------------
            -- VELOCITY
            ------------------------------------------------------------

            local targetRoot =
                targetHumanoid.Parent
                and targetHumanoid.Parent:FindFirstChild(
                    "HumanoidRootPart"
                )

            if targetRoot then

                if targetRoot.AssemblyLinearVelocity.Y
                    > jumpVelocityThreshold then

                    return true

                end

            end

            return false

        end

        ----------------------------------------------------------------
        -- CREATE PATH
        ----------------------------------------------------------------

        local function createPath(targetPosition)

            if not myHRP then
                return false
            end

            local path

            local success =
                pcall(function()

                    path =
                        PathfindingService:CreatePath({

                            AgentRadius = 2,

                            AgentHeight = 5,

                            AgentCanJump = true,

                            AgentCanClimb = true,

                            WaypointSpacing = 3,

                        })

                    path:ComputeAsync(
                        myHRP.Position,
                        targetPosition
                    )

                end)

            if not success
                or not path then

                return false

            end

            if path.Status
                ~= Enum.PathStatus.Success then

                return false

            end

            local waypoints =
                path:GetWaypoints()

            if #waypoints < 2 then

                return false

            end

            currentPath = path
            currentWaypoints = waypoints

            ------------------------------------------------------------
            -- WAYPOINT PERTAMA BIASANYA POSISI BOT
            ------------------------------------------------------------

            currentWaypointIndex = 2

            return true

        end

        ----------------------------------------------------------------
        -- FOLLOW WAYPOINT
        ----------------------------------------------------------------

        local function followWaypoint()

            if not humanoid
                or not myHRP then

                return false

            end

            if #currentWaypoints == 0 then
                return false
            end

            ------------------------------------------------------------
            -- CARI WAYPOINT AKTIF
            ------------------------------------------------------------

            local waypoint =
                currentWaypoints[currentWaypointIndex]

            if not waypoint then

                return false

            end

            ------------------------------------------------------------
            -- CHECK DISTANCE
            ------------------------------------------------------------

            local distance =
                (
                    myHRP.Position
                    - waypoint.Position
                ).Magnitude

            if distance <= waypointReachDistance then

                currentWaypointIndex =
                    currentWaypointIndex + 1

                waypoint =
                    currentWaypoints[currentWaypointIndex]

                if not waypoint then

                    return false

                end

            end

            ------------------------------------------------------------
            -- WAYPOINT JUMP
            ------------------------------------------------------------

            if waypoint.Action
                == Enum.PathWaypointAction.Jump then

                tryJump()

            end

            ------------------------------------------------------------
            -- MOVE
            ------------------------------------------------------------

            humanoid.AutoRotate = true

            humanoid:MoveTo(
                waypoint.Position
            )

            return true

        end

        ----------------------------------------------------------------
        -- STOP FOLLOW
        ----------------------------------------------------------------

        local function stopFollow()

            following = false
            targetPlayer = nil

            resetPath()

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
        -- START FOLLOW
        ----------------------------------------------------------------

        local function startFollow(player)

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

            _G.BotVars.ActiveMode = "follow"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            resetPath()

            following = true
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

                stopFollow()

                return

            end

            ----------------------------------------------------------------
            -- FOLLOW LOOP
            ----------------------------------------------------------------

            followConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE BERUBAH
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "follow" then

                            stopFollow()

                            return

                        end

                        ------------------------------------------------
                        -- VALIDASI
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

                        local targetHumanoid =
                            targetCharacter:FindFirstChildOfClass(
                                "Humanoid"
                            )

                        if not targetHRP
                            or not targetHumanoid then

                            return

                        end

                        ------------------------------------------------
                        -- DISTANCE
                        ------------------------------------------------

                        local distance =
                            defaultBotFollowDistance

                        if Admin:IsAdmin(
                            targetPlayer
                        ) then

                            distance =
                                adminFollowDistance

                        end

                        local specialDistance =
                            Distance:GetDistance(
                                tostring(
                                    LocalPlayer.UserId
                                ),
                                tostring(
                                    targetPlayer.UserId
                                )
                            )

                        if specialDistance then

                            distance =
                                specialDistance

                        end

                        ------------------------------------------------
                        -- TARGET POSITION
                        ------------------------------------------------

                        local targetVelocity =
                            targetHRP.AssemblyLinearVelocity

                        local predictedPosition =
                            targetHRP.Position
                            + (
                                targetVelocity
                                * predictionTime
                            )

                        ------------------------------------------------
                        -- POSISI FORMASI BOT
                        ------------------------------------------------

                        local targetPosition =
                            predictedPosition
                            - (
                                targetHRP.CFrame.LookVector
                                * (distance * myIndex)
                            )

                        ------------------------------------------------
                        -- TARGET JUMP DETECTION
                        ------------------------------------------------

                        local targetJumping =
                            targetIsJumping(
                                targetHumanoid
                            )

                        if targetJumping then

                            tryJump()

                        end

                        ------------------------------------------------
                        -- TARGET LEBIH TINGGI
                        ------------------------------------------------

                        local verticalDifference =
                            targetPosition.Y
                            - myHRP.Position.Y

                        if verticalDifference
                            > verticalJumpThreshold then

                            tryJump()

                        end

                        ------------------------------------------------
                        -- DISTANCE
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                - targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- PATH UPDATE
                        ------------------------------------------------

                        local now = tick()

                        if now - lastPathUpdate
                            >= pathUpdateInterval then

                            lastPathUpdate = now

                            createPath(
                                targetPosition
                            )

                        end

                        ------------------------------------------------
                        -- FOLLOW WAYPOINT
                        ------------------------------------------------

                        local usedPath =
                            followWaypoint()

                        ------------------------------------------------
                        -- FALLBACK MOVE TO
                        ------------------------------------------------

                        if not usedPath then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                        end

                        ------------------------------------------------
                        -- TARGET DEKAT
                        ------------------------------------------------

                        if distanceToTarget <= 1.5 then

                            humanoid.AutoRotate = false

                            local targetRotation =
                                targetHRP.CFrame
                                - targetHRP.Position

                            myHRP.CFrame =
                                CFrame.new(
                                    myHRP.Position
                                )
                                * targetRotation

                        end

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

                resetPath()

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