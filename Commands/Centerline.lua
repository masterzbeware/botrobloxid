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
            warn("[Centerline] LocalPlayer tidak ditemukan.")
            return
        end


        ----------------------------------------------------------------
        -- GLOBAL MODE SYSTEM
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}


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

            if success and result then
                Admin = result
            else
                warn("[Centerline] Gagal load Admin.lua.")
                return
            end
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

            if success and result then
                Distance = result
            else
                warn("[Centerline] Gagal load Distance.lua.")
                return
            end
        end


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid = nil
        local myHRP = nil

        local centerlining = false
        local targetPlayer = nil

        local centerlineConnection = nil


        ----------------------------------------------------------------
        -- FORMATION DISTANCE
        ----------------------------------------------------------------

        -- Jarak default Bot dengan Player/Admin
        local adminCenterlineDistance = 6
        local defaultBotCenterlineDistance = 6

        -- Jarak antar Bot
        local formationSpacing = 3

        -- Jarak antar baris
        local rowSpacing = 3


        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

local botOrder = {

    "11611503633", -- Bot 1
    "11611591921", -- Bot 2
    "11611597741", -- Bot 3
    "11672407300", -- Bot 4
    "11672403154", -- Bot 5
    "11672413029", -- Bot 6
    "11672983578", -- Bot 7
    "11122806815", -- Bot 8
    "11122806817", -- Bot 9
    "11122687468", -- Bot 10
    "11122854402", -- Bot 11
    "11001607521", -- Bot 12

}


        ----------------------------------------------------------------
        -- FORMATION DESIGN
        ----------------------------------------------------------------
        --
        --                    DEPAN
        --
        --              B1    B2    B3    B4
        --
        --
        --        B5    B6     PLAYER     B7    B8
        --
        --
        --              B9   B10   B11   B12
        --
        --                    BELAKANG
        --
        ----------------------------------------------------------------
        --
        -- Player/Admin berada di tengah.
        --
        -- Baris tengah:
        --
        -- B5     B6      PLAYER      B7     B8
        --
        -- Jarak:
        --
        -- B6 <-> PLAYER = 3
        -- PLAYER <-> B7 = 3
        --
        ----------------------------------------------------------------


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

            pcall(function()

                local TextChatService =
                    game:GetService("TextChatService")

                local channel =
                    TextChatService.TextChannels
                    and TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then

                    channel:SendAsync(message)

                    return

                end


                --------------------------------------------------------
                -- OLD CHAT FALLBACK
                --------------------------------------------------------

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


        ----------------------------------------------------------------
        -- STOP CENTERLINE
        ----------------------------------------------------------------

        local function stopCenterline()

            centerlining = false
            targetPlayer = nil

            if centerlineConnection then

                centerlineConnection:Disconnect()
                centerlineConnection = nil

            end

            if humanoid then
                humanoid.AutoRotate = true
            end

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.centerline =
            stopCenterline


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "centerline"
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

            if not name then
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

                if player.Name:lower():sub(
                    1,
                    #name
                ) == name then

                    return player

                end


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
        -- GET MY INDEX
        ----------------------------------------------------------------

        local function getMyIndex()

            local userId =
                tostring(LocalPlayer.UserId)

            return table.find(
                botOrder,
                userId
            )

        end


        ----------------------------------------------------------------
        -- GET FORMATION POSITION
        ----------------------------------------------------------------

        local function getFormationOffset(myIndex)

            ----------------------------------------------------------------
            -- CENTERLINE FORMATION
            ----------------------------------------------------------------
            --
            -- Bot 1 - 4
            -- Baris DEPAN
            --
            -- Bot 5 - 8
            -- Baris TENGAH
            --
            -- Bot 9 - 12
            -- Baris BELAKANG
            --
            ----------------------------------------------------------------


            local row =
                math.floor(
                    (myIndex - 1) / 4
                )

            local column =
                (myIndex - 1) % 4


            ------------------------------------------------------------
            -- CENTER EACH ROW
            ------------------------------------------------------------

            local horizontalOffset =
                (column - 1.5)
                * formationSpacing


            ------------------------------------------------------------
            -- FRONT ROW
            ------------------------------------------------------------

            if row == 0 then

                return {
                    horizontal = horizontalOffset,
                    depth = rowSpacing
                }

            end


            ------------------------------------------------------------
            -- MIDDLE ROW
            ------------------------------------------------------------
            --
            -- Baris tengah dibuat lebih lebar agar Player/Admin
            -- berada tepat di tengah.
            --
            -- Posisi:
            --
            -- B5     B6      PLAYER      B7     B8
            --
            -- B5 = -4.5
            -- B6 = -1.5
            -- B7 =  1.5
            -- B8 =  4.5
            --
            ------------------------------------------------------------

            if row == 1 then

                return {
                    horizontal = horizontalOffset,
                    depth = 0
                }

            end


            ------------------------------------------------------------
            -- BACK ROW
            ------------------------------------------------------------

            if row == 2 then

                return {
                    horizontal = horizontalOffset,
                    depth = -rowSpacing
                }

            end


            ------------------------------------------------------------
            -- FALLBACK
            ------------------------------------------------------------

            return {
                horizontal = horizontalOffset,
                depth = 0
            }

        end


        ----------------------------------------------------------------
        -- START CENTERLINE
        ----------------------------------------------------------------

        local function startCenterline(player)

            if not player then

                warn(
                    "[Centerline] Target player tidak ditemukan."
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

            _G.BotVars.ActiveMode = "centerline"


            ------------------------------------------------------------
            -- DISCONNECT OLD LOOP
            ------------------------------------------------------------

            if centerlineConnection then

                centerlineConnection:Disconnect()
                centerlineConnection = nil

            end


            ------------------------------------------------------------
            -- GET BOT INDEX
            ------------------------------------------------------------

            local myIndex =
                getMyIndex()


            if not myIndex then

                warn(
                    "[Centerline] Bot ini tidak terdapat di botOrder."
                )

                warn(
                    "[Centerline] LocalPlayer:",
                    LocalPlayer.Name
                )

                warn(
                    "[Centerline] UserId:",
                    LocalPlayer.UserId
                )

                warn(
                    "[Centerline] Tambahkan UserId bot ini ke botOrder."
                )

                _G.BotVars.ActiveMode = nil

                stopCenterline()

                return

            end


            ------------------------------------------------------------
            -- START
            ------------------------------------------------------------

            centerlining = true
            targetPlayer = player

            _G.BotVars.CommandTarget = player

            sendChat("Yes, Sir!")


            ----------------------------------------------------------------
            -- CENTERLINE LOOP
            ----------------------------------------------------------------

            centerlineConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- ACTIVE MODE CHECK
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "centerline" then

                            stopCenterline()

                            return

                        end


                        if not centerlining then
                            return
                        end


                        ------------------------------------------------
                        -- CHARACTER VALIDATION
                        ------------------------------------------------

                        if not humanoid
                            or not myHRP then

                            return

                        end


                        if not targetPlayer then

                            stopCenterline()

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
                            defaultBotCenterlineDistance


                        ------------------------------------------------
                        -- ADMIN DISTANCE
                        ------------------------------------------------

                        local isTargetAdmin = false

                        pcall(function()

                            isTargetAdmin =
                                Admin:IsAdmin(
                                    targetPlayer
                                )

                        end)


                        if isTargetAdmin then

                            distance =
                                adminCenterlineDistance

                        end


                        ------------------------------------------------
                        -- SPECIAL DISTANCE
                        ------------------------------------------------

                        local specialDistance = nil

                        pcall(function()

                            specialDistance =
                                Distance:GetDistance(
                                    tostring(
                                        LocalPlayer.UserId
                                    ),
                                    tostring(
                                        targetPlayer.UserId
                                    )
                                )

                        end)


                        if specialDistance then

                            distance =
                                specialDistance

                        end


                        ------------------------------------------------
                        -- FORMATION OFFSET
                        ------------------------------------------------

                        local formation =
                            getFormationOffset(
                                myIndex
                            )


                        local horizontalOffset =
                            formation.horizontal


                        local depthOffset =
                            formation.depth


                        ------------------------------------------------
                        -- POSITION
                        ------------------------------------------------
                        --
                        -- Local coordinate:
                        --
                        -- X = kiri / kanan
                        -- Y = tinggi
                        -- Z = depan / belakang
                        --
                        -- RightVector = kanan
                        -- LookVector  = depan
                        --
                        ------------------------------------------------

                        local targetPosition =
                            targetHRP.Position


                            ------------------------------------------------
                            -- KIRI / KANAN
                            ------------------------------------------------

                            +

                            (
                                targetHRP.CFrame.RightVector
                                * horizontalOffset
                            )


                            ------------------------------------------------
                            -- DEPAN / BELAKANG
                            ------------------------------------------------

                            +

                            (
                                targetHRP.CFrame.LookVector
                                * (
                                    distance
                                    * depthOffset
                                )
                            )


                        ------------------------------------------------
                        -- MOVE DISTANCE
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


                        ----------------------------------------------------------------
                        -- ARRIVED
                        ----------------------------------------------------------------

                        humanoid.AutoRotate = false


                        ----------------------------------------------------------------
                        -- FACE SAME DIRECTION
                        ----------------------------------------------------------------
                        --
                        -- Semua bot menghadap arah yang sama
                        -- dengan Player/Admin.
                        --
                        ----------------------------------------------------------------

                        local forwardDirection =
                            targetHRP.CFrame.LookVector


                        myHRP.CFrame =
                            CFrame.lookAt(
                                myHRP.Position,
                                myHRP.Position
                                + forwardDirection
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

            if not message or not sender then
                return
            end


            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            local isAdmin = false

            pcall(function()

                isAdmin =
                    Admin:IsAdmin(
                        sender
                    )

            end)


            ------------------------------------------------------------
            -- CLEAN MESSAGE
            ------------------------------------------------------------

            local lower =
                message
                :lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")


            ------------------------------------------------------------
            -- CURRENT TARGET
            ------------------------------------------------------------

            local commandTarget =
                _G.BotVars.CommandTarget


            ----------------------------------------------------------------
            -- !STOP
            ----------------------------------------------------------------

            if lower == "!stop"
                or lower == "!uncenterline" then

                if not isAdmin then
                    return
                end


                _G.BotVars.ActiveMode = nil
                _G.BotVars.CommandTarget = nil


                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction) == "function" then

                        pcall(
                            stopFunction
                        )

                    end

                end

                return

            end


            ----------------------------------------------------------------
            -- !CENTERLINE
            ----------------------------------------------------------------
            --
            -- Admin:
            -- langsung menjadi target.
            --
            -- Target aktif:
            -- boleh menjalankan ulang formasi untuk dirinya.
            --
            ----------------------------------------------------------------

            if lower == "!centerline" then

                if not isAdmin
                    and sender ~= commandTarget then

                    return

                end


                _G.BotVars.CommandTarget =
                    sender


                startCenterline(
                    sender
                )


                return

            end


            ----------------------------------------------------------------
            -- !CENTERLINE PLAYER
            ----------------------------------------------------------------
            --
            -- HANYA ADMIN.
            --
            ----------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!centerline%s+(.+)$"
                )


            if targetName then

                if not isAdmin then
                    return
                end


                local target =
                    findPlayerByName(
                        targetName
                    )


                if target then

                    _G.BotVars.CommandTarget =
                        target


                    startCenterline(
                        target
                    )

                else

                    warn(
                        "[Centerline] Player tidak ditemukan:",
                        targetName
                    )

                end


                return

            end

        end


        ----------------------------------------------------------------
        -- CHAT HANDLER
        ----------------------------------------------------------------
        --
        -- Menggunakan Player.Chatted supaya tidak bentrok dengan
        -- mode lain yang juga menggunakan sistem command.
        --
        ----------------------------------------------------------------

        local connectedPlayers = {}


        local function connectPlayerChat(player)

            if connectedPlayers[player] then
                return
            end


            connectedPlayers[player] = true


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
        -- EXISTING PLAYERS
        ----------------------------------------------------------------

        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            connectPlayerChat(
                player
            )

        end


        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                connectPlayerChat(
                    player
                )

            end
        )


        ----------------------------------------------------------------
        -- PLAYER REMOVING
        ----------------------------------------------------------------

        Players.PlayerRemoving:Connect(
            function(player)

                connectedPlayers[player] = nil


                if targetPlayer == player then

                    _G.BotVars.ActiveMode = nil

                    stopCenterline()

                end

            end
        )


        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()


                --------------------------------------------------------
                -- RESTORE CENTERLINE
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "centerline"
                    and targetPlayer then

                    local currentTarget =
                        targetPlayer


                    task.wait(0.2)


                    startCenterline(
                        currentTarget
                    )

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Centerline] Loaded untuk:",
            LocalPlayer.Name,
            "| UserId:",
            LocalPlayer.UserId
        )


        local myIndex =
            getMyIndex()


        if myIndex then

            print(
                "[Centerline] Bot Index:",
                myIndex
            )

        else

            warn(
                "[Centerline] UserId bot ini BELUM ADA di botOrder:",
                LocalPlayer.UserId
            )

        end

    end
}