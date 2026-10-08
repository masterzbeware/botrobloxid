return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players =
            game:GetService("Players")

        local RunService =
            game:GetService("RunService")

        local TextChatService =
            game:GetService("TextChatService")

        local ReplicatedStorage =
            game:GetService("ReplicatedStorage")

        local LocalPlayer =
            Players.LocalPlayer


        ----------------------------------------------------------------
        -- VALIDATE LOCAL PLAYER
        ----------------------------------------------------------------

        if not LocalPlayer then
            warn("[RoofLeft] LocalPlayer tidak ditemukan.")
            return
        end


        ----------------------------------------------------------------
        -- GLOBAL SYSTEM
        ----------------------------------------------------------------

        _G.BotVars =
            _G.BotVars or {}

        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}


        ----------------------------------------------------------------
        -- PLACE ID
        ----------------------------------------------------------------

        local TANPANAMA_PLACE_ID =
            119031818630096


        ----------------------------------------------------------------
        -- PLACE CHECK
        ----------------------------------------------------------------

        if game.PlaceId ~= TANPANAMA_PLACE_ID then

            warn(
                "[RoofLeft] Command tidak aktif di place ini.",
                "PlaceId:",
                game.PlaceId
            )

            return
        end


        ----------------------------------------------------------------
        -- LOAD ADMIN
        ----------------------------------------------------------------

        local Admin

        local successAdmin, resultAdmin =
            pcall(function()

                return loadstring(
                    game:HttpGet(
                        "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
                    )
                )()

            end)


        if not successAdmin then

            warn(
                "[RoofLeft] Gagal load Admin.lua:",
                resultAdmin
            )

            return
        end


        Admin = resultAdmin


        if not Admin then

            warn(
                "[RoofLeft] Admin.lua tidak menghasilkan module."
            )

            return
        end


        ----------------------------------------------------------------
        -- LOAD DISTANCE
        ----------------------------------------------------------------

        local Distance

        local successDistance, resultDistance =
            pcall(function()

                return loadstring(
                    game:HttpGet(
                        "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
                    )
                )()

            end)


        if not successDistance then

            warn(
                "[RoofLeft] Gagal load Distance.lua:",
                resultDistance
            )

            return
        end


        Distance = resultDistance


        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------
        -- Formasi:
        --
        -- Bot 1
        -- Bot 2
        -- Bot 3
        -- Bot 4
        -- Bot 5
        -- Bot 6
        -- Bot 7
        -- Bot 8
        -- Bot 9
        -- Bot 10
        --
        -- Bot 1 berada paling depan.
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

        }


        ----------------------------------------------------------------
        -- ROOF KIRI ROUTE
        ----------------------------------------------------------------

        local route = {

            ------------------------------------------------------------
            -- STEP 1
            ------------------------------------------------------------

            Vector3.new(
                2759.09,
                5.04,
                6.04
            ),

            ------------------------------------------------------------
            -- STEP 2
            ------------------------------------------------------------

            Vector3.new(
                2758.87,
                5.04,
                16.71
            ),

            ------------------------------------------------------------
            -- STEP 1 KANAN
            ------------------------------------------------------------

            Vector3.new(
                2737.54,
                5.04,
                16.33
            ),

            ------------------------------------------------------------
            -- STEP 2 KANAN
            ------------------------------------------------------------

            Vector3.new(
                2725.21,
                16.51,
                16.25
            ),

            ------------------------------------------------------------
            -- STEP 3 KANAN
            ------------------------------------------------------------

            Vector3.new(
                2707.95,
                28.83,
                16.14
            ),

            ------------------------------------------------------------
            -- STEP 4 KANAN
            ------------------------------------------------------------

            Vector3.new(
                2707.56,
                28.75,
                2.06
            ),

            ------------------------------------------------------------
            -- ROOF KIRI MIDDLE
            ------------------------------------------------------------

            Vector3.new(
                2760.92,
                28.78,
                -1.82
            ),

        }


        ----------------------------------------------------------------
        -- FORMATION DISTANCE
        ----------------------------------------------------------------
        --
        -- Mengikuti konsep Follow.lua.
        --
        -- Bot 1 = leader
        -- Bot 2 = 1 x spacing di belakang
        -- Bot 3 = 2 x spacing di belakang
        -- dst.
        --
        -- Jarak default = 2 studs.
        --
        -- Distance.lua tetap digunakan apabila pasangan bot
        -- mempunyai konfigurasi jarak khusus.
        ----------------------------------------------------------------

        local DEFAULT_DISTANCE = 2


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        local roofLeftActive = false
        local roofLeftConnection = nil

        local currentRouteDistance = 0
        local routeFinished = false


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
                    TextChatService.TextChannels:
                    FindFirstChild(
                        "RBXGeneral"
                    )


                if channel then

                    pcall(function()

                        channel:SendAsync(
                            message
                        )

                    end)

                    success = true

                end

            end


            ------------------------------------------------------------
            -- LEGACY CHAT
            ------------------------------------------------------------

            if not success then

                pcall(function()

                    local chatEvents =
                        ReplicatedStorage:
                        FindFirstChild(
                            "DefaultChatSystemChatEvents"
                        )


                    if chatEvents then

                        local sayMessageRequest =
                            chatEvents:
                            FindFirstChild(
                                "SayMessageRequest"
                            )


                        if sayMessageRequest then

                            sayMessageRequest:
                            FireServer(
                                message,
                                "All"
                            )

                        end

                    end

                end)

            end

        end


        ----------------------------------------------------------------
        -- CALCULATE ROUTE SEGMENTS
        ----------------------------------------------------------------

        local segments = {}
        local totalRouteLength = 0


        for i = 1, #route - 1 do

            local a = route[i]
            local b = route[i + 1]

            local length =
                (b - a).Magnitude


            segments[i] = {
                Start = a,
                Finish = b,
                Length = length,
                StartDistance = totalRouteLength,
                EndDistance =
                    totalRouteLength + length,
            }


            totalRouteLength =
                totalRouteLength + length

        end


        ----------------------------------------------------------------
        -- GET POSITION ON ROUTE
        ----------------------------------------------------------------

        local function getPositionOnRoute(distance)

            if distance <= 0 then
                return route[1]
            end


            if distance >= totalRouteLength then
                return route[#route]
            end


            for _, segment in ipairs(segments) do

                if distance >= segment.StartDistance
                    and distance <= segment.EndDistance then

                    local alpha =
                        (
                            distance
                            - segment.StartDistance
                        )
                        /
                        segment.Length


                    return segment.Start:Lerp(
                        segment.Finish,
                        alpha
                    )

                end

            end


            return route[#route]

        end


        ----------------------------------------------------------------
        -- GET ROUTE DISTANCE FROM POSITION
        ----------------------------------------------------------------
        --
        -- Digunakan supaya setiap bot bisa mengetahui posisi
        -- progresnya di sepanjang jalur.
        ----------------------------------------------------------------

        local function getClosestRouteDistance(position)

            local bestDistance = 0
            local bestDifference = math.huge


            for _, segment in ipairs(segments) do

                local segmentVector =
                    segment.Finish
                    - segment.Start


                local segmentLengthSquared =
                    segmentVector:Dot(
                        segmentVector
                    )


                if segmentLengthSquared > 0 then

                    local alpha =
                        (
                            position
                            - segment.Start
                        ):Dot(segmentVector)
                        /
                        segmentLengthSquared


                    alpha =
                        math.clamp(
                            alpha,
                            0,
                            1
                        )


                    local closestPoint =
                        segment.Start
                        + segmentVector * alpha


                    local difference =
                        (
                            position
                            - closestPoint
                        ).Magnitude


                    if difference < bestDifference then

                        bestDifference =
                            difference


                        bestDistance =
                            segment.StartDistance
                            +
                            segment.Length
                            * alpha

                    end

                end

            end


            return bestDistance

        end


        ----------------------------------------------------------------
        -- GET BOT INDEX
        ----------------------------------------------------------------

        local function getBotIndex()

            return table.find(
                botOrder,
                tostring(
                    LocalPlayer.UserId
                )
            )

        end


        ----------------------------------------------------------------
        -- GET FORMATION DISTANCE
        ----------------------------------------------------------------

        local function getFormationDistance()

            local myIndex =
                getBotIndex()


            if not myIndex then
                return DEFAULT_DISTANCE
            end


            ------------------------------------------------------------
            -- Bot pertama tidak mempunyai jarak belakang.
            ------------------------------------------------------------

            if myIndex <= 1 then
                return 0
            end


            ------------------------------------------------------------
            -- Ikuti konfigurasi Distance.lua apabila tersedia.
            ------------------------------------------------------------

            local previousBotId =
                botOrder[myIndex - 1]


            local currentBotId =
                botOrder[myIndex]


            local specialDistance =
                Distance:GetDistance(
                    currentBotId,
                    previousBotId
                )


            if specialDistance then
                return specialDistance
            end


            return DEFAULT_DISTANCE

        end


        ----------------------------------------------------------------
        -- GET TARGET DISTANCE
        ----------------------------------------------------------------

        local function getTargetRouteDistance()

            local myIndex =
                getBotIndex()


            if not myIndex then
                return currentRouteDistance
            end


            ------------------------------------------------------------
            -- Bot 1 menjadi leader.
            ------------------------------------------------------------

            if myIndex == 1 then
                return currentRouteDistance
            end


            ------------------------------------------------------------
            -- Setiap bot berada sedikit di belakang bot sebelumnya.
            --
            -- Karena Distance.lua memiliki pasangan:
            --
            -- Bot 1 - Bot 2 = 2
            -- Bot 3 - Bot 4 = 2
            -- ...
            --
            -- Untuk formasi baris penuh, kita gunakan jarak 2
            -- antar setiap bot.
            ------------------------------------------------------------

            local spacing =
                getFormationDistance()


            local targetDistance =
                currentRouteDistance
                -
                (
                    spacing
                    *
                    (myIndex - 1)
                )


            return math.max(
                0,
                targetDistance
            )

        end


        ----------------------------------------------------------------
        -- STOP ROOF LEFT
        ----------------------------------------------------------------

        local function stopRoofLeft()

            roofLeftActive = false
            routeFinished = false


            if roofLeftConnection then

                roofLeftConnection:Disconnect()
                roofLeftConnection = nil

            end


            if humanoid then

                humanoid.AutoRotate = true

            end


            print(
                "[RoofLeft] Mode dihentikan."
            )

        end


        ----------------------------------------------------------------
        -- REGISTER MODE CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.roofleft =
            stopRoofLeft


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "roofleft"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

            end

        end


        ----------------------------------------------------------------
        -- START ROOF LEFT
        ----------------------------------------------------------------

        local function startRoofLeft()

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()


            ------------------------------------------------------------
            -- ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode =
                "roofleft"


            ------------------------------------------------------------
            -- RESET
            ------------------------------------------------------------

            if roofLeftConnection then

                roofLeftConnection:Disconnect()
                roofLeftConnection = nil

            end


            roofLeftActive = true
            routeFinished = false


            ------------------------------------------------------------
            -- BOT INDEX
            ------------------------------------------------------------

            local myIndex =
                getBotIndex()


            if not myIndex then

                warn(
                    "[RoofLeft] Player ini bukan salah satu Bot."
                )

                stopRoofLeft()

                return

            end


            ------------------------------------------------------------
            -- MULAI DARI POSISI ROUTE TERDEKAT
            ------------------------------------------------------------

            currentRouteDistance =
                getClosestRouteDistance(
                    myHRP.Position
                )


            ------------------------------------------------------------
            -- BOT 1 DIARAHKAN KE STEP 1
            --
            -- Bot lain juga akan mengejar posisi route mereka
            -- berdasarkan jarak formasi.
            ------------------------------------------------------------

            if myIndex == 1 then

                currentRouteDistance = 0

            else

                currentRouteDistance =
                    math.max(
                        0,
                        currentRouteDistance
                    )

            end


            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat(
                "Roof Left!"
            )


            print(
                "[RoofLeft] Started."
            )

            print(
                "[RoofLeft] Bot:",
                myIndex
            )


            ------------------------------------------------------------
            -- MOVEMENT LOOP
            ------------------------------------------------------------

            roofLeftConnection =
                RunService.Heartbeat:Connect(
                    function(deltaTime)

                        ------------------------------------------------
                        -- ACTIVE MODE CHECK
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "roofleft" then

                            stopRoofLeft()

                            return

                        end


                        ------------------------------------------------
                        -- ACTIVE CHECK
                        ------------------------------------------------

                        if not roofLeftActive then
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
                        -- ROUTE PROGRESS
                        ------------------------------------------------
                        --
                        -- Bot 1 bergerak sepanjang route.
                        --
                        -- Semua bot menggunakan progres route yang
                        -- sama sehingga formasi tetap berbaris.
                        ------------------------------------------------

                        if myIndex == 1 then

                            if currentRouteDistance
                                < totalRouteLength then

                                ------------------------------------------------
                                -- Kecepatan gerak mengikuti Humanoid.WalkSpeed.
                                ------------------------------------------------

                                local speed =
                                    math.max(
                                        humanoid.WalkSpeed,
                                        1
                                    )


                                currentRouteDistance =
                                    math.min(
                                        totalRouteLength,
                                        currentRouteDistance
                                        +
                                        (
                                            speed
                                            * deltaTime
                                        )
                                    )

                            else

                                routeFinished = true

                            end

                        else

                            ------------------------------------------------
                            -- Bot follower membaca posisi aktualnya
                            -- terhadap route.
                            ------------------------------------------------

                            local actualRouteDistance =
                                getClosestRouteDistance(
                                    myHRP.Position
                                )


                            local desiredDistance =
                                getTargetRouteDistance()


                            ------------------------------------------------
                            -- Bila terlalu jauh di belakang,
                            -- percepat progres route internal.
                            ------------------------------------------------

                            if actualRouteDistance
                                < desiredDistance - 0.5 then

                                currentRouteDistance =
                                    math.min(
                                        totalRouteLength,
                                        currentRouteDistance
                                        +
                                        (
                                            math.max(
                                                humanoid.WalkSpeed,
                                                1
                                            )
                                            * deltaTime
                                        )
                                    )

                            elseif actualRouteDistance
                                > desiredDistance + 0.5 then

                                currentRouteDistance =
                                    math.max(
                                        0,
                                        currentRouteDistance
                                        -
                                        (
                                            math.max(
                                                humanoid.WalkSpeed,
                                                1
                                            )
                                            * deltaTime
                                        )
                                    )

                            end

                        end


                        ------------------------------------------------
                        -- TARGET ROUTE POSITION
                        ------------------------------------------------

                        local targetDistance =
                            getTargetRouteDistance()


                        local targetPosition =
                            getPositionOnRoute(
                                targetDistance
                            )


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

                        if distanceToTarget > 1.5 then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end


                        ------------------------------------------------
                        -- ARRIVED
                        ------------------------------------------------

                        humanoid.AutoRotate = false


                        ------------------------------------------------
                        -- FACE DIRECTION ROUTE
                        ------------------------------------------------

                        local lookDistance =
                            math.min(
                                totalRouteLength,
                                targetDistance + 1
                            )


                        local lookPosition =
                            getPositionOnRoute(
                                lookDistance
                            )


                        local direction =
                            lookPosition
                            -
                            myHRP.Position


                        if direction.Magnitude > 0.05 then

                            myHRP.CFrame =
                                CFrame.lookAt(
                                    myHRP.Position,
                                    myHRP.Position
                                    + direction.Unit
                                )

                        end


                        ------------------------------------------------
                        -- FINAL POSITION
                        ------------------------------------------------

                        if routeFinished
                            and targetDistance
                                >= totalRouteLength then

                            humanoid.AutoRotate = false

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

            if not sender then
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


            if not isAdmin then
                return
            end


            ------------------------------------------------------------
            -- CLEAN MESSAGE
            ------------------------------------------------------------

            local lower =
                tostring(message)
                :lower()
                :gsub(
                    "^%s+",
                    ""
                )
                :gsub(
                    "%s+$",
                    ""
                )


            ------------------------------------------------------------
            -- !ROOFLEFT
            ------------------------------------------------------------

            if lower == "!roofleft" then

                startRoofLeft()

                return

            end


            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop" then

                _G.BotVars.ActiveMode =
                    nil

                _G.BotVars.CommandTarget =
                    nil


                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction)
                        == "function" then

                        pcall(
                            stopFunction
                        )

                    end

                end

                return

            end

        end


        ----------------------------------------------------------------
        -- TEXT CHAT
        ----------------------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels:
                FindFirstChild(
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


                if _G.BotVars.ActiveMode
                    == "roofleft"
                    and roofLeftActive then

                    startRoofLeft()

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print("----------------------------------------")
        print("[RoofLeft] Loaded successfully.")
        print("[RoofLeft] Place: TANPANAMA")
        print("[RoofLeft] PlaceId:", TANPANAMA_PLACE_ID)
        print("[RoofLeft] Command: !roofleft")
        print("[RoofLeft] Bots: 10")
        print("[RoofLeft] Route points:", #route)
        print("----------------------------------------")

    end
}