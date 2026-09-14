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
            warn("[Behindline] LocalPlayer tidak ditemukan.")
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

                warn("[Behindline] Gagal load Admin.lua.")
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

                warn("[Behindline] Gagal load Distance.lua.")
                return

            end
        end


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid = nil
        local myHRP = nil

        local behindlining = false
        local targetPlayer = nil

        local behindlineConnection = nil


        ----------------------------------------------------------------
        -- FORMATION DISTANCE
        ----------------------------------------------------------------

        -- Jarak formasi dari Player/Admin.
        local adminBehindlineDistance = 6
        local defaultBotBehindlineDistance = 6

        -- Jarak antar bot.
        local formationSpacing = 3


        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

        -- FORMASI BEHINDLINE:
        --
        --             PLAYER
        --
        -- B1 B2 B3 B4 B5 B6 B7 B8 B9 B10 B11
        --
        -- Semua bot berada DI BELAKANG Player.
        -- Semua bot menghadap arah yang sama dengan Player.
        --

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
        -- STOP BEHINDLINE
        ----------------------------------------------------------------

        local function stopBehindline()

            behindlining = false
            targetPlayer = nil


            if behindlineConnection then

                behindlineConnection:Disconnect()
                behindlineConnection = nil

            end


            if humanoid then
                humanoid.AutoRotate = true
            end

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.behindline =
            stopBehindline


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "behindline"
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
        -- START BEHINDLINE
        ----------------------------------------------------------------

        local function startBehindline(player)

            if not player then

                warn(
                    "[Behindline] Target player tidak ditemukan."
                )

                return

            end


            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()


            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "behindline"


            ------------------------------------------------------------
            -- DISCONNECT CONNECTION LAMA
            ------------------------------------------------------------

            if behindlineConnection then

                behindlineConnection:Disconnect()
                behindlineConnection = nil

            end


            ------------------------------------------------------------
            -- CARI INDEX BOT
            ------------------------------------------------------------

            local myIndex =
                getMyIndex()


            if not myIndex then

                warn(
                    "[Behindline] Bot ini tidak terdapat di botOrder."
                )

                warn(
                    "[Behindline] LocalPlayer:",
                    LocalPlayer.Name
                )

                warn(
                    "[Behindline] UserId:",
                    LocalPlayer.UserId
                )

                warn(
                    "[Behindline] Tambahkan UserId bot ini ke botOrder."
                )


                _G.BotVars.ActiveMode = nil

                stopBehindline()

                return

            end


            ------------------------------------------------------------
            -- START
            ------------------------------------------------------------

            behindlining = true
            targetPlayer = player


            sendChat("Yes, Sir!")


            ----------------------------------------------------------------
            -- BEHINDLINE LOOP
            ----------------------------------------------------------------

            behindlineConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE SUDAH BERGANTI
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "behindline" then

                            stopBehindline()

                            return

                        end


                        if not behindlining then
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

                            stopBehindline()

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
                            defaultBotBehindlineDistance


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
                                adminBehindlineDistance

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


                        ----------------------------------------------------------------
                        -- FORMATION POSITION
                        ----------------------------------------------------------------
                        --
                        -- Satu garis di belakang Player.
                        --
                        -- B1 B2 B3 B4 B5 B6 B7 B8 B9 B10 B11
                        --
                        -- Karena LookVector menunjuk ke DEPAN target,
                        -- maka -LookVector adalah arah BELAKANG.
                        ----------------------------------------------------------------

                        local centerIndex =
                            (#botOrder + 1) / 2


                        ------------------------------------------------
                        -- HORIZONTAL OFFSET
                        ------------------------------------------------

                        local horizontalOffset =
                            (
                                myIndex
                                - centerIndex
                            )
                            * formationSpacing


                        ----------------------------------------------------------------
                        -- TARGET POSITION
                        ----------------------------------------------------------------

                        local targetPosition =
                            targetHRP.Position

                            -

                            (
                                targetHRP.CFrame.LookVector
                                * distance
                            )

                            +

                            (
                                targetHRP.CFrame.RightVector
                                * horizontalOffset
                            )


                        ------------------------------------------------
                        -- DISTANCE KE POSISI
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
                        -- SUDAH SAMPAI
                        ----------------------------------------------------------------

                        humanoid.AutoRotate = false


                        ----------------------------------------------------------------
                        -- MENGHADAP ARAH YANG SAMA
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

            if not message then
                return
            end


            if not sender then
                return
            end


            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            local isAdmin = false


            pcall(function()

                isAdmin =
                    Admin:IsAdmin(sender)

            end)


            if not isAdmin then
                return
            end


            ------------------------------------------------------------
            -- CLEAN MESSAGE
            ------------------------------------------------------------

            local lower =
                message:lower()


            lower =
                lower:gsub(
                    "^%s+",
                    ""
                )


            lower =
                lower:gsub(
                    "%s+$",
                    ""
                )


            ------------------------------------------------------------
            -- !BEHINDLINE
            ------------------------------------------------------------

            if lower == "!behindline" then

                print(
                    "[Behindline] Command diterima dari:",
                    sender.Name
                )


                startBehindline(sender)


                return

            end


            ------------------------------------------------------------
            -- !BEHINDLINE PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!behindline%s+(.+)$"
                )


            if targetName then

                print(
                    "[Behindline] Target command:",
                    targetName
                )


                local target =
                    findPlayerByName(
                        targetName
                    )


                if target then

                    print(
                        "[Behindline] Target ditemukan:",
                        target.Name
                    )


                    startBehindline(
                        target
                    )

                else

                    warn(
                        "[Behindline] Player tidak ditemukan:",
                        targetName
                    )

                end


                return

            end


            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unbehindline" then

                print(
                    "[Behindline] Stop command dari:",
                    sender.Name
                )


                _G.BotVars.ActiveMode = nil


                stopBehindline()


                return

            end

        end


        ----------------------------------------------------------------
        -- CHAT HANDLER
        ----------------------------------------------------------------

        -- Sengaja menggunakan Player.Chatted agar tidak bentrok
        -- dengan module mode lain.

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

                    stopBehindline()

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
                -- RESTORE BEHINDLINE
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "behindline"
                    and targetPlayer then

                    local currentTarget =
                        targetPlayer


                    task.wait(0.2)


                    startBehindline(
                        currentTarget
                    )

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Behindline] Loaded untuk:",
            LocalPlayer.Name,
            "| UserId:",
            LocalPlayer.UserId
        )


        local myIndex =
            getMyIndex()


        if myIndex then

            print(
                "[Behindline] Bot Index:",
                myIndex
            )

        else

            warn(
                "[Behindline] UserId bot ini BELUM ADA di botOrder:",
                LocalPlayer.UserId
            )

        end

    end
}
```

Kemudian di `Bot.lua`, tambahkan `Behindline.lua` ke daftar command dan jalankan modulnya. Jangan lagi memakai `Frontline.lua` untuk mode ini:

```lua
local commandFiles = {
    "Perfix.lua",
    "Main.lua",
    "Follow.lua",
    "Behindline.lua",
    "Circle.lua",
    "Fourline.lua",
    "Rest.lua",
}