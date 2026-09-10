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
            warn("[AtEase] LocalPlayer tidak ditemukan")
            return
        end

        --------------------------------------------------
        -- GLOBAL MODE SYSTEM
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}

        --------------------------------------------------
        -- LOAD ADMIN
        --------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        --------------------------------------------------
        -- EMOTE ID
        --------------------------------------------------

        local EMOTE_ID = "75628064640924"

        --------------------------------------------------
        -- CURRENT EMOTE TRACK
        --------------------------------------------------

        local currentTrack = nil

        --------------------------------------------------
        -- STOP EMOTE
        --------------------------------------------------

        local function stopEmote()

            --------------------------------------------------
            -- STOP CURRENT TRACK
            --------------------------------------------------

            if currentTrack then

                pcall(function()

                    if currentTrack.IsPlaying then
                        currentTrack:Stop(0.15)
                    end

                    currentTrack:Destroy()

                end)

                currentTrack = nil

            end

            --------------------------------------------------
            -- GET CHARACTER
            --------------------------------------------------

            local character =
                LocalPlayer.Character

            if not character then
                return
            end

            --------------------------------------------------
            -- RESET ACTIVE MODE
            --------------------------------------------------

            if _G.BotVars.ActiveMode == "atease" then
                _G.BotVars.ActiveMode = nil
            end

            --------------------------------------------------
            -- ENABLE DEFAULT ANIMATE
            --------------------------------------------------

            local animate =
                character:FindFirstChild("Animate")

            if animate then

                --------------------------------------------------
                -- RESTART DEFAULT ANIMATION SCRIPT
                --------------------------------------------------

                animate.Disabled = true

                task.wait()

                animate.Disabled = false

            end

            --------------------------------------------------
            -- RESET HUMANOID
            --------------------------------------------------

            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            if humanoid then

                --------------------------------------------------
                -- STOP REMAINING CUSTOM TRACKS
                --------------------------------------------------

                local animator =
                    humanoid:FindFirstChildOfClass(
                        "Animator"
                    )

                if animator then

                    for _, track in ipairs(
                        animator:GetPlayingAnimationTracks()
                    ) do

                        pcall(function()

                            track:Stop(0.15)

                        end)

                    end

                end

            end

            --------------------------------------------------
            -- WAIT FOR DEFAULT ANIMATION
            --------------------------------------------------

            task.delay(0.1, function()

                if not LocalPlayer.Character then
                    return
                end

                local currentCharacter =
                    LocalPlayer.Character

                local currentAnimate =
                    currentCharacter:FindFirstChild(
                        "Animate"
                    )

                if currentAnimate then
                    currentAnimate.Disabled = false
                end

            end)

            print(
                "[AtEase] Emote dihentikan dan pose dikembalikan"
            )

        end

        --------------------------------------------------
        -- REGISTER CONTROLLER
        --------------------------------------------------

        _G.BotVars.ModeControllers.atease =
            stopEmote

        --------------------------------------------------
        -- STOP SEMUA MODE LAIN
        --------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "atease"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

            end

        end

        --------------------------------------------------
        -- PLAY EMOTE
        --------------------------------------------------

        local function playEmote()

            --------------------------------------------------
            -- CHARACTER
            --------------------------------------------------

            local character =
                LocalPlayer.Character

            if not character then

                warn(
                    "[AtEase] Character tidak ditemukan"
                )

                return

            end

            --------------------------------------------------
            -- HUMANOID
            --------------------------------------------------

            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            if not humanoid then

                warn(
                    "[AtEase] Humanoid tidak ditemukan"
                )

                return

            end

            --------------------------------------------------
            -- STOP MODE LAIN
            --------------------------------------------------

            stopOtherModes()

            --------------------------------------------------
            -- SET ACTIVE MODE
            --------------------------------------------------

            _G.BotVars.ActiveMode = "atease"

            --------------------------------------------------
            -- STOP ATEASE LAMA
            --------------------------------------------------

            stopEmote()

            --------------------------------------------------
            -- SET ACTIVE MODE AGAIN
            --------------------------------------------------

            _G.BotVars.ActiveMode = "atease"

            --------------------------------------------------
            -- PLAY EMOTE
            --------------------------------------------------

            local success, track =
                pcall(function()

                    return humanoid:
                        PlayEmoteAndGetAnimTrackById(
                            EMOTE_ID
                        )

                end)

            --------------------------------------------------
            -- FAILED
            --------------------------------------------------

            if not success then

                warn(
                    "[AtEase] Gagal memainkan emote:",
                    track
                )

                _G.BotVars.ActiveMode = nil

                return

            end

            --------------------------------------------------
            -- TRACK NOT FOUND
            --------------------------------------------------

            if not track then

                warn(
                    "[AtEase] Emote tidak dapat dimainkan:",
                    EMOTE_ID
                )

                _G.BotVars.ActiveMode = nil

                return

            end

            --------------------------------------------------
            -- SAVE TRACK
            --------------------------------------------------

            currentTrack = track

            print(
                "[AtEase] Emote berhasil dimainkan:",
                EMOTE_ID
            )

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
            -- NORMALIZE COMMAND
            --------------------------------------------------

            local command =
                message:lower():match(
                    "^%s*(.-)%s*$"
                )

            --------------------------------------------------
            -- !ATEASE
            --------------------------------------------------

            if command == "!atease" then

                print(
                    "[AtEase] Command !AtEase diterima dari:",
                    sender.Name
                )

                playEmote()

                return
            end

            --------------------------------------------------
            -- !STOP
            --------------------------------------------------

            if command == "!stop" then

                print(
                    "[AtEase] Command !Stop diterima dari:",
                    sender.Name
                )

                --------------------------------------------------
                -- STOP SEMUA MODE
                --------------------------------------------------

                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction) == "function" then

                        pcall(stopFunction)

                    end

                end

                --------------------------------------------------
                -- RESET ACTIVE MODE
                --------------------------------------------------

                _G.BotVars.ActiveMode = nil

                return
            end

        end

        --------------------------------------------------
        -- TEXT CHAT
        --------------------------------------------------

        TextChatService.MessageReceived:Connect(
            function(message)

                if not message.TextSource then
                    return
                end

                --------------------------------------------------
                -- GET USER ID
                --------------------------------------------------

                local userId =
                    message.TextSource.UserId

                --------------------------------------------------
                -- GET PLAYER
                --------------------------------------------------

                local sender =
                    Players:GetPlayerByUserId(
                        userId
                    )

                if not sender then
                    return
                end

                --------------------------------------------------
                -- HANDLE COMMAND
                --------------------------------------------------

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
            function()

                currentTrack = nil

                task.wait(1)

                --------------------------------------------------
                -- DEFAULT ANIMATION
                --------------------------------------------------

                local character =
                    LocalPlayer.Character

                if not character then
                    return
                end

                local animate =
                    character:FindFirstChild("Animate")

                if animate then
                    animate.Disabled = false
                end

            end
        )

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print(
            "[AtEase] AtEase.lua aktif!"
        )

    end
}