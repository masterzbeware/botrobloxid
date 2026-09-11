return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")

        --------------------------------------------------
        -- LOCAL PLAYER
        --------------------------------------------------

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Rest] LocalPlayer tidak ditemukan")
            return
        end

        --------------------------------------------------
        -- GLOBAL SYSTEM
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}

        --------------------------------------------------
        -- LOAD ADMIN
        --------------------------------------------------

        local Admin

        local successAdmin, resultAdmin = pcall(function()

            return loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            ))()

        end)

        if not successAdmin or not resultAdmin then

            warn(
                "[Rest] Gagal load Admin.lua:",
                resultAdmin
            )

            return

        end

        Admin = resultAdmin

        --------------------------------------------------
        -- EMOTE / ANIMATION ID
        --------------------------------------------------

        local EMOTE_ID = "75628064640924"

        --------------------------------------------------
        -- CURRENT TRACK
        --------------------------------------------------

        local currentTrack = nil

        --------------------------------------------------
        -- ACTIVE STATE
        --------------------------------------------------

        local isPlaying = false

        --------------------------------------------------
        -- GET CHARACTER
        --------------------------------------------------

        local function getCharacter()

            local character =
                LocalPlayer.Character

            if not character then
                return nil
            end

            return character

        end

        --------------------------------------------------
        -- GET HUMANOID
        --------------------------------------------------

        local function getHumanoid()

            local character =
                getCharacter()

            if not character then
                return nil
            end

            return character:FindFirstChildOfClass(
                "Humanoid"
            )

        end

        --------------------------------------------------
        -- GET ANIMATOR
        --------------------------------------------------

        local function getAnimator()

            local humanoid =
                getHumanoid()

            if not humanoid then
                return nil
            end

            local animator =
                humanoid:FindFirstChildOfClass(
                    "Animator"
                )

            if not animator then

                animator =
                    Instance.new("Animator")

                animator.Parent = humanoid

            end

            return animator

        end

        --------------------------------------------------
        -- STOP CURRENT TRACK
        --------------------------------------------------

        local function stopCurrentTrack()

            if currentTrack then

                pcall(function()

                    if currentTrack.IsPlaying then

                        currentTrack:Stop(0.15)

                    end

                end)

                currentTrack = nil

            end

            isPlaying = false

        end

        --------------------------------------------------
        -- ENABLE DEFAULT ANIMATE
        --------------------------------------------------

        local function enableDefaultAnimate()

            local character =
                getCharacter()

            if not character then
                return
            end

            local animate =
                character:FindFirstChild("Animate")

            if animate then
                animate.Disabled = false
            end

        end

        --------------------------------------------------
        -- DISABLE DEFAULT ANIMATE
        --------------------------------------------------

        local function disableDefaultAnimate()

            local character =
                getCharacter()

            if not character then
                return
            end

            local animate =
                character:FindFirstChild("Animate")

            if animate then
                animate.Disabled = true
            end

        end

        --------------------------------------------------
        -- STOP REST
        --------------------------------------------------

        local function stopRest()

            --------------------------------------------------
            -- STOP TRACK
            --------------------------------------------------

            stopCurrentTrack()

            --------------------------------------------------
            -- ENABLE DEFAULT ANIMATION
            --------------------------------------------------

            enableDefaultAnimate()

            --------------------------------------------------
            -- CLEAR MODE
            --------------------------------------------------

            if _G.BotVars.ActiveMode == "rest" then

                _G.BotVars.ActiveMode = nil

            end

            print(
                "[Rest] Rest dihentikan"
            )

        end

        --------------------------------------------------
        -- REGISTER CONTROLLER
        --------------------------------------------------

        _G.BotVars.ModeControllers.rest =
            stopRest

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "rest"
                    and type(stopFunction) == "function" then

                    print(
                        "[Rest] Menghentikan mode:",
                        name
                    )

                    pcall(function()

                        stopFunction()

                    end)

                end

            end

        end

        --------------------------------------------------
        -- PLAY REST ANIMATION
        --------------------------------------------------

        local function playRest()

            print(
                "================================"
            )

            print(
                "[Rest] playRest() dipanggil"
            )

            print(
                "[Rest] Animation ID:",
                EMOTE_ID
            )

            --------------------------------------------------
            -- GET HUMANOID
            --------------------------------------------------

            local humanoid =
                getHumanoid()

            if not humanoid then

                warn(
                    "[Rest] Humanoid tidak ditemukan"
                )

                return

            end

            --------------------------------------------------
            -- STOP OTHER MODES
            --------------------------------------------------

            stopOtherModes()

            --------------------------------------------------
            -- STOP REST LAMA
            --------------------------------------------------

            stopCurrentTrack()

            --------------------------------------------------
            -- DISABLE DEFAULT ANIMATE
            --------------------------------------------------

            disableDefaultAnimate()

            --------------------------------------------------
            -- SET ACTIVE MODE
            --------------------------------------------------

            _G.BotVars.ActiveMode = "rest"

            --------------------------------------------------
            -- GET ANIMATOR
            --------------------------------------------------

            local animator =
                getAnimator()

            if not animator then

                warn(
                    "[Rest] Animator tidak ditemukan"
                )

                _G.BotVars.ActiveMode = nil

                enableDefaultAnimate()

                return

            end

            --------------------------------------------------
            -- CREATE ANIMATION
            --------------------------------------------------

            local animation =
                Instance.new("Animation")

            animation.Name =
                "MasterZ_RestAnimation"

            animation.AnimationId =
                "rbxassetid://" .. EMOTE_ID

            --------------------------------------------------
            -- LOAD ANIMATION
            --------------------------------------------------

            local successLoad, track =
                pcall(function()

                    return animator:LoadAnimation(
                        animation
                    )

                end)

            --------------------------------------------------
            -- LOAD FAILED
            --------------------------------------------------

            if not successLoad then

                warn(
                    "[Rest] Gagal LoadAnimation:",
                    track
                )

                animation:Destroy()

                _G.BotVars.ActiveMode = nil

                enableDefaultAnimate()

                return

            end

            if not track then

                warn(
                    "[Rest] Track tidak dibuat"
                )

                animation:Destroy()

                _G.BotVars.ActiveMode = nil

                enableDefaultAnimate()

                return

            end

            --------------------------------------------------
            -- SET PRIORITY
            --------------------------------------------------

            track.Priority =
                Enum.AnimationPriority.Action

            --------------------------------------------------
            -- LOOP
            --------------------------------------------------

            track.Looped = true

            --------------------------------------------------
            -- SAVE TRACK
            --------------------------------------------------

            currentTrack = track

            isPlaying = true

            --------------------------------------------------
            -- PLAY
            --------------------------------------------------

            local successPlay, playError =
                pcall(function()

                    track:Play(
                        0.15,
                        1,
                        1
                    )

                end)

            --------------------------------------------------
            -- PLAY FAILED
            --------------------------------------------------

            if not successPlay then

                warn(
                    "[Rest] Gagal Play:",
                    playError
                )

                stopCurrentTrack()

                animation:Destroy()

                _G.BotVars.ActiveMode = nil

                enableDefaultAnimate()

                return

            end

            --------------------------------------------------
            -- VERIFY
            --------------------------------------------------

            task.wait(0.1)

            if currentTrack
                and currentTrack.IsPlaying then

                print(
                    "[Rest] ================================="
                )

                print(
                    "[Rest] REST BERHASIL DIMAINKAN"
                )

                print(
                    "[Rest] Animation:",
                    EMOTE_ID
                )

                print(
                    "[Rest] IsPlaying:",
                    currentTrack.IsPlaying
                )

                print(
                    "[Rest] ActiveMode:",
                    _G.BotVars.ActiveMode
                )

                print(
                    "[Rest] ================================="
                )

            else

                warn(
                    "[Rest] Track berhasil dibuat tetapi tidak playing"
                )

            end

        end

        --------------------------------------------------
        -- COMMAND HANDLER
        --------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            if not sender then
                return
            end

            --------------------------------------------------
            -- ADMIN CHECK
            --------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            --------------------------------------------------
            -- NORMALIZE
            --------------------------------------------------

            local command =
                tostring(message)
                    :lower()
                    :match("^%s*(.-)%s*$")

            --------------------------------------------------
            -- REST
            --------------------------------------------------

            if command == "!rest" then

                print(
                    "[Rest] !rest diterima dari:",
                    sender.Name
                )

                playRest()

                return

            end

            --------------------------------------------------
            -- STOP
            --------------------------------------------------

            if command == "!stop" then

                print(
                    "[Rest] !stop diterima dari:",
                    sender.Name
                )

                --------------------------------------------------
                -- STOP ALL MODES
                --------------------------------------------------

                for name, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction) == "function" then

                        print(
                            "[Rest] Stop controller:",
                            name
                        )

                        pcall(function()

                            stopFunction()

                        end)

                    end

                end

                --------------------------------------------------
                -- CLEAR ACTIVE MODE
                --------------------------------------------------

                _G.BotVars.ActiveMode = nil

                print(
                    "[Rest] Semua mode dihentikan"
                )

                return

            end

        end

        --------------------------------------------------
        -- CHAT CONNECTION
        --------------------------------------------------

        TextChatService.MessageReceived:Connect(
            function(message)

                if not message then
                    return
                end

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

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function(character)

                print(
                    "[Rest] Character respawn"
                )

                --------------------------------------------------
                -- CLEAR OLD TRACK
                --------------------------------------------------

                currentTrack = nil
                isPlaying = false

                --------------------------------------------------
                -- CLEAR MODE
                --------------------------------------------------

                if _G.BotVars.ActiveMode == "rest" then

                    _G.BotVars.ActiveMode = nil

                end

                --------------------------------------------------
                -- WAIT CHARACTER READY
                --------------------------------------------------

                task.wait(1)

                --------------------------------------------------
                -- ENABLE DEFAULT ANIMATE
                --------------------------------------------------

                local animate =
                    character:FindFirstChild(
                        "Animate"
                    )

                if animate then

                    animate.Disabled = false

                end

                print(
                    "[Rest] Character siap"
                )

            end
        )

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print(
            "================================"
        )

        print(
            "[Rest] Rest.lua aktif!"
        )

        print(
            "[Rest] Animation ID:",
            EMOTE_ID
        )

        print(
            "================================"
        )

    end
}