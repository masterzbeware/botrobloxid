return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Salute] LocalPlayer tidak ditemukan.")
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

                warn("[Salute] Gagal load Admin.lua.")
                return

            end
        end


        ----------------------------------------------------------------
        -- EMOTE ID
        ----------------------------------------------------------------

        local SALUTE_EMOTE_ID =
            "108307316311180"


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local saluteTrack = nil
        local saluting = false


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
            -- STOP SALUTE EMOTE
            ------------------------------------------------------------

            if saluteTrack then

                pcall(function()

                    saluteTrack:Stop(0.15)

                end)

                saluteTrack = nil

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
                "[Salute] Animasi normal dipulihkan."
            )

        end


        ----------------------------------------------------------------
        -- STOP SALUTE
        ----------------------------------------------------------------

        local function stopSalute()

            saluting = false

            restoreNormalAnimation()

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.salute =
            stopSalute


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "salute"
                    and type(stopFunction) == "function" then

                    pcall(function()

                        stopFunction()

                    end)

                end

            end

        end


        ----------------------------------------------------------------
        -- PLAY SALUTE EMOTE
        ----------------------------------------------------------------

        local function playSalute()

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()


            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "salute"


            ------------------------------------------------------------
            -- STOP PREVIOUS SALUTE
            ------------------------------------------------------------

            if saluteTrack then

                pcall(function()

                    saluteTrack:Stop(0.1)

                end)

                saluteTrack = nil

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
                    "[Salute] Humanoid tidak ditemukan."
                )

                return

            end


            ------------------------------------------------------------
            -- PLAY EMOTE
            ------------------------------------------------------------

            local success, result =
                pcall(function()

                    return humanoid:PlayEmoteAndGetAnimTrackById(
                        SALUTE_EMOTE_ID
                    )

                end)


            if success and result then

                saluteTrack = result
                saluting = true


                print(
                    "[Salute] Emote berhasil dimainkan:",
                    SALUTE_EMOTE_ID
                )


                --------------------------------------------------------
                -- MONITOR TRACK
                --------------------------------------------------------

                task.spawn(function()

                    local track =
                        saluteTrack


                    if not track then
                        return
                    end


                    pcall(function()

                        track.Stopped:Wait()

                    end)


                    if saluteTrack == track
                        and saluting then

                        saluteTrack = nil

                    end

                end)

            else

                warn(
                    "[Salute] Emote gagal dimainkan:",
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
            -- !SALUTE
            ------------------------------------------------------------

            if lower == "!salute" then

                print(
                    "[Salute] Command diterima dari:",
                    sender.Name
                )


                playSalute()


                return

            end


            ------------------------------------------------------------
            -- !UNSALUTE
            ------------------------------------------------------------

            if lower == "!unsalute" then

                print(
                    "[Salute] Unsalute command dari:",
                    sender.Name
                )


                if _G.BotVars.ActiveMode
                    == "salute" then

                    _G.BotVars.ActiveMode = nil

                end


                stopSalute()


                return

            end


            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop" then

                print(
                    "[Salute] Stop command dari:",
                    sender.Name
                )


                if _G.BotVars.ActiveMode
                    == "salute" then

                    _G.BotVars.ActiveMode = nil

                end


                stopSalute()


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

                saluteTrack = nil


                --------------------------------------------------------
                -- JIKA MASIH MODE SALUTE
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "salute" then

                    task.wait(0.5)

                    playSalute()

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Salute] Loaded untuk:",
            LocalPlayer.Name,
            "| Emote:",
            SALUTE_EMOTE_ID
        )

    end
}
