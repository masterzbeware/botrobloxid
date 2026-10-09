return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[BrazilDance] LocalPlayer tidak ditemukan.")
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

                warn("[BrazilDance] Gagal load Admin.lua.")
                return

            end
        end

        ----------------------------------------------------------------
        -- FE ANIMATION ID
        ----------------------------------------------------------------

        local BRAZIL_DANCE_ANIMATION_ID =
            "81300570590946"

        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local danceTrack = nil
        local dancing = false

        local danceGeneration = 0

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

        local function restoreNormalAnimation(generation)

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
            -- VALIDATE GENERATION
            ------------------------------------------------------------

            if generation
                and generation ~= danceGeneration then

                return

            end

            ------------------------------------------------------------
            -- STOP BRAZIL DANCE
            ------------------------------------------------------------

            if danceTrack then

                local oldTrack =
                    danceTrack

                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.15)
                end)

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
            -- RESTART DEFAULT ANIMATE
            ------------------------------------------------------------

            local animateScript =
                character:FindFirstChild("Animate")

            if animateScript
                and animateScript:IsA("LocalScript") then

                pcall(function()
                    animateScript.Enabled = false
                end)

                task.wait()

                if generation
                    and generation ~= danceGeneration then

                    return

                end

                pcall(function()
                    animateScript.Enabled = true
                end)

            end

            ------------------------------------------------------------
            -- FORCE RUNNING
            ------------------------------------------------------------

            if generation
                and generation ~= danceGeneration then

                return

            end

            pcall(function()

                humanoid:ChangeState(
                    Enum.HumanoidStateType.Running
                )

            end)

            ------------------------------------------------------------
            -- DELAYED RUNNING STATE
            ------------------------------------------------------------

            local cleanupGeneration =
                generation or danceGeneration

            task.defer(function()

                task.wait(0.1)

                if cleanupGeneration
                    ~= danceGeneration then

                    return

                end

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
                "[BrazilDance] Animasi normal dipulihkan."
            )

        end

        ----------------------------------------------------------------
        -- STOP BRAZIL DANCE
        ----------------------------------------------------------------
        --
        -- TIDAK menghapus CommandTarget.
        --
        ----------------------------------------------------------------

        local function stopBrazilDance()

            danceGeneration =
                danceGeneration + 1

            local generation =
                danceGeneration

            dancing = false

            ------------------------------------------------------------
            -- STOP TRACK
            ------------------------------------------------------------

            if danceTrack then

                local oldTrack =
                    danceTrack

                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.15)
                end)

            end

            ------------------------------------------------------------
            -- RESTORE NORMAL ANIMATION
            ------------------------------------------------------------

            restoreNormalAnimation(
                generation
            )

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.brazildance =
            stopBrazilDance

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "brazildance"
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

            name = name:lower()

            ------------------------------------------------------------
            -- EXACT USERNAME / DISPLAY NAME
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
            -- USERNAME PREFIX
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

            end

            return nil

        end

        ----------------------------------------------------------------
        -- PLAY BRAZIL DANCE
        ----------------------------------------------------------------
        --
        -- targetPlayer digunakan sebagai CommandTarget.
        --
        ----------------------------------------------------------------

        local function playBrazilDance(
            targetPlayer
        )

            ------------------------------------------------------------
            -- NEW GENERATION
            ------------------------------------------------------------

            danceGeneration =
                danceGeneration + 1

            local generation =
                danceGeneration

            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode =
                "brazildance"

            ------------------------------------------------------------
            -- SET COMMAND TARGET
            ------------------------------------------------------------

            if targetPlayer then

                _G.BotVars.CommandTarget =
                    targetPlayer

            end

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- VALIDATE GENERATION
            ------------------------------------------------------------

            if generation ~= danceGeneration then
                return
            end

            ------------------------------------------------------------
            -- STOP PREVIOUS TRACK
            ------------------------------------------------------------

            if danceTrack then

                local oldTrack =
                    danceTrack

                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.1)
                end)

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
                    "[BrazilDance] Humanoid tidak ditemukan."
                )

                return

            end

            ------------------------------------------------------------
            -- PLAY FE ANIMATION WITH RETRY
            ------------------------------------------------------------

            local maxAttempts = 3
            local success = false
            local result = nil

            for attempt = 1, maxAttempts do

                if generation ~= danceGeneration then
                    return
                end

                local ok, track =
                    pcall(function()

                        return humanoid:
                            PlayEmoteAndGetAnimTrackById(
                                BRAZIL_DANCE_ANIMATION_ID
                            )

                    end)

                if ok and track then

                    success = true
                    result = track

                    break

                end

                result = track

                if attempt < maxAttempts then
                    task.wait(0.1)
                end

            end

            ------------------------------------------------------------
            -- VALIDATE GENERATION
            ------------------------------------------------------------

            if generation ~= danceGeneration then

                if result then

                    pcall(function()
                        result:Stop(0)
                    end)

                end

                return

            end

            ------------------------------------------------------------
            -- RESULT
            ------------------------------------------------------------

            if success and result then

                danceTrack = result
                dancing = true

                print(
                    "[BrazilDance] FE Animation berhasil dimainkan:",
                    BRAZIL_DANCE_ANIMATION_ID,
                    "| Bot:",
                    LocalPlayer.Name
                )

                --------------------------------------------------------
                -- MONITOR TRACK
                --------------------------------------------------------

                task.spawn(function()

                    local track = result
                    local trackGeneration =
                        generation

                    if not track then
                        return
                    end

                    pcall(function()
                        track.Stopped:Wait()
                    end)

                    if danceTrack == track
                        and dancing
                        and trackGeneration
                            == danceGeneration then

                        danceTrack = nil

                    end

                end)

            else

                warn(
                    "[BrazilDance] FE Animation gagal dimainkan setelah",
                    maxAttempts,
                    "percobaan.",
                    "| Bot:",
                    LocalPlayer.Name,
                    "| Last Error:",
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

            if not message
                or not sender then

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

            ------------------------------------------------------------
            -- NORMALIZE
            ------------------------------------------------------------

            local lower =
                message
                :lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            ------------------------------------------------------------
            -- CURRENT COMMAND TARGET
            ------------------------------------------------------------

            local commandTarget =
                _G.BotVars.CommandTarget

            local isCommandTarget =
                commandTarget == sender

            ------------------------------------------------------------
            -- !STOP
            --
            -- HANYA ADMIN
            --
            -- !stop menghapus CommandTarget.
            ------------------------------------------------------------

            if lower == "!stop" then

                if not isAdmin then
                    return
                end

                _G.BotVars.ActiveMode = nil
                _G.BotVars.CommandTarget = nil

                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction) == "function" then

                        pcall(function()
                            stopFunction()
                        end)

                    end

                end

                return

            end

            ------------------------------------------------------------
            -- !UNBRAZILDANCE
            --
            -- HANYA ADMIN
            --
            -- Tidak menghapus CommandTarget.
            ------------------------------------------------------------

            if lower == "!unbrazildance" then

                if not isAdmin then
                    return
                end

                if _G.BotVars.ActiveMode
                    == "brazildance" then

                    _G.BotVars.ActiveMode = nil

                end

                stopBrazilDance()

                return

            end

            ------------------------------------------------------------
            -- !BRAZILDANCE
            --
            -- ADMIN:
            -- !brazildance
            --
            -- COMMAND TARGET:
            -- !brazildance
            ------------------------------------------------------------

            if lower == "!brazildance" then

                if not isAdmin
                    and not isCommandTarget then

                    return

                end

                --------------------------------------------------------
                -- TARGET MENJADI DIRINYA SENDIRI
                --------------------------------------------------------

                _G.BotVars.CommandTarget =
                    sender

                playBrazilDance(
                    sender
                )

                return

            end

            ------------------------------------------------------------
            -- !BRAZILDANCE PLAYER
            --
            -- HANYA ADMIN
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!brazildance%s+(.+)$"
                )

            if targetName then

                if not isAdmin then
                    return
                end

                local target =
                    findPlayerByName(
                        targetName
                    )

                if not target then
                    return
                end

                _G.BotVars.CommandTarget =
                    target

                playBrazilDance(
                    target
                )

                return

            end

        end

        ----------------------------------------------------------------
        -- CHAT CONNECTION
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

                danceGeneration =
                    danceGeneration + 1

                local generation =
                    danceGeneration

                danceTrack = nil
                dancing = false

                --------------------------------------------------------
                -- RESTART JIKA MODE MASIH AKTIF
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "brazildance" then

                    task.wait(0.5)

                    if generation
                        ~= danceGeneration then

                        return

                    end

                    playBrazilDance(
                        _G.BotVars.CommandTarget
                    )

                end

            end
        )

        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[BrazilDance] Loaded untuk:",
            LocalPlayer.Name,
            "| FE Animation:",
            BRAZIL_DANCE_ANIMATION_ID
        )

    end
}