return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Rest] LocalPlayer tidak ditemukan.")
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

                warn("[Rest] Gagal load Admin.lua.")
                return

            end
        end


        ----------------------------------------------------------------
        -- EMOTE ID
        ----------------------------------------------------------------

        local REST_EMOTE_ID =
            "115880435130348"


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local restTrack = nil
        local resting = false


        ----------------------------------------------------------------
        -- GET CHARACTER
        ----------------------------------------------------------------

        local function getCharacter()

            return LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

        end


        ----------------------------------------------------------------
        -- RESTORE NORMAL ANIMATION
        ----------------------------------------------------------------

        local function restoreNormalAnimation()

            local character =
                LocalPlayer.Character

            if not character then
                return
            end


            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            if not humanoid then
                return
            end


            ------------------------------------------------------------
            -- STOP EMOTE TRACK
            ------------------------------------------------------------

            if restTrack then

                pcall(function()

                    restTrack:Stop(0.15)

                end)

                restTrack = nil

            end


            ------------------------------------------------------------
            -- STOP ACTION TRACKS
            ------------------------------------------------------------

            local animator =
                humanoid:FindFirstChildOfClass(
                    "Animator"
                )

            if animator then

                for _, track in ipairs(
                    animator:GetPlayingAnimationTracks()
                ) do

                    if track.Priority
                        == Enum.AnimationPriority.Action
                        or track.Priority
                        == Enum.AnimationPriority.Action2
                        or track.Priority
                        == Enum.AnimationPriority.Action3
                        or track.Priority
                        == Enum.AnimationPriority.Action4 then

                        pcall(function()

                            track:Stop(0.15)

                        end)

                    end

                end

            end


            ------------------------------------------------------------
            -- RESTART DEFAULT ANIMATE SCRIPT
            ------------------------------------------------------------

            local animateScript =
                character:FindFirstChild(
                    "Animate"
                )


            if animateScript
                and animateScript:IsA("LocalScript") then

                --------------------------------------------------------
                -- Toggle agar controller animasi Roblox
                -- mengambil alih kembali.
                --------------------------------------------------------

                pcall(function()

                    animateScript.Enabled = false

                end)

                task.wait()


                pcall(function()

                    animateScript.Enabled = true

                end)

            end


            ------------------------------------------------------------
            -- FORCE HUMANOID BACK TO RUNNING
            ------------------------------------------------------------

            pcall(function()

                humanoid:ChangeState(
                    Enum.HumanoidStateType.Running
                )

            end)


            ------------------------------------------------------------
            -- SMALL DELAY UNTIL ANIMATE IS ACTIVE
            ------------------------------------------------------------

            task.defer(function()

                task.wait(0.1)

                if humanoid
                    and humanoid.Parent then

                    pcall(function()

                        humanoid:ChangeState(
                            Enum.HumanoidStateType.Running
                        )

                    end)

                end

            end)


            print(
                "[Rest] Animasi normal dipulihkan."
            )

        end


        ----------------------------------------------------------------
        -- STOP REST
        ----------------------------------------------------------------

        local function stopRest()

            resting = false

            restoreNormalAnimation()

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.rest =
            stopRest


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "rest"
                    and type(stopFunction) == "function" then

                    pcall(function()

                        stopFunction()

                    end)

                end

            end

        end


        ----------------------------------------------------------------
        -- PLAY REST EMOTE
        ----------------------------------------------------------------

        local function playRest()

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()


            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "rest"


            ------------------------------------------------------------
            -- STOP PREVIOUS REST
            ------------------------------------------------------------

            if restTrack then

                pcall(function()

                    restTrack:Stop(0.1)

                end)

                restTrack = nil

            end


            ------------------------------------------------------------
            -- GET CHARACTER
            ------------------------------------------------------------

            local character =
                getCharacter()


            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )


            if not humanoid then

                warn(
                    "[Rest] Humanoid tidak ditemukan."
                )

                return

            end


            ------------------------------------------------------------
            -- PLAY EMOTE
            ------------------------------------------------------------

            local success, result =
                pcall(function()

                    return humanoid:
                        PlayEmoteAndGetAnimTrackById(
                            REST_EMOTE_ID
                        )

                end)


            if success and result then

                restTrack = result
                resting = true


                print(
                    "[Rest] Emote berhasil dimainkan:",
                    REST_EMOTE_ID
                )


                --------------------------------------------------------
                -- MONITOR TRACK
                --------------------------------------------------------

                task.spawn(function()

                    local track =
                        restTrack


                    if not track then
                        return
                    end


                    pcall(function()

                        track.Stopped:Wait()

                    end)


                    if restTrack == track
                        and resting then

                        restTrack = nil

                    end

                end)

            else

                warn(
                    "[Rest] Emote gagal dimainkan:",
                    result
                )

            end

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
            -- !REST
            ------------------------------------------------------------

            if lower == "!rest" then

                print(
                    "[Rest] Command diterima dari:",
                    sender.Name
                )


                playRest()


                return

            end


            ------------------------------------------------------------
            -- !UNREST
            ------------------------------------------------------------

            if lower == "!unrest" then

                print(
                    "[Rest] Unrest command dari:",
                    sender.Name
                )


                if _G.BotVars.ActiveMode
                    == "rest" then

                    _G.BotVars.ActiveMode = nil

                end


                stopRest()


                return

            end


            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop" then

                print(
                    "[Rest] Stop command dari:",
                    sender.Name
                )


                if _G.BotVars.ActiveMode
                    == "rest" then

                    _G.BotVars.ActiveMode = nil

                end


                stopRest()


                return

            end

        end


        ----------------------------------------------------------------
        -- CHAT HANDLER
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

            end
        )


        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                restTrack = nil


                --------------------------------------------------------
                -- JIKA MASIH MODE REST
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "rest" then

                    task.wait(0.5)

                    playRest()

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Rest] Loaded untuk:",
            LocalPlayer.Name,
            "| Emote:",
            REST_EMOTE_ID
        )

    end
}