return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[ScubaDance] LocalPlayer tidak ditemukan.")
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
                local source = game:HttpGet(
                    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
                )

                local loader, compileError = loadstring(source)

                if not loader then
                    error(compileError or "Gagal compile Admin.lua")
                end

                return loader()
            end)

            if success and result then
                Admin = result
            else
                warn(
                    "[ScubaDance] Gagal load Admin.lua:",
                    tostring(result)
                )
                return
            end
        end

        ----------------------------------------------------------------
        -- FE ANIMATION ID
        ----------------------------------------------------------------

        local SCUBA_DANCE_ANIMATION_ID = "70919402339484"

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

            local character = LocalPlayer.Character

            if not character then
                return
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

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
            -- STOP SCUBA DANCE TRACK
            ------------------------------------------------------------

            if danceTrack then
                local oldTrack = danceTrack
                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.15)
                end)
            end

            ------------------------------------------------------------
            -- STOP ACTION TRACKS
            ------------------------------------------------------------

            local animator =
                humanoid:FindFirstChildOfClass("Animator")

            if animator then
                for _, track in ipairs(
                    animator:GetPlayingAnimationTracks()
                ) do
                    local priority = track.Priority

                    if priority == Enum.AnimationPriority.Action
                        or priority == Enum.AnimationPriority.Action2
                        or priority == Enum.AnimationPriority.Action3
                        or priority == Enum.AnimationPriority.Action4 then

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

                if cleanupGeneration ~= danceGeneration then
                    return
                end

                if humanoid and humanoid.Parent then
                    pcall(function()
                        humanoid:ChangeState(
                            Enum.HumanoidStateType.Running
                        )
                    end)
                end
            end)

            print("[ScubaDance] Animasi normal dipulihkan.")
        end

        ----------------------------------------------------------------
        -- STOP SCUBA DANCE
        -- Tidak menghapus CommandTarget.
        ----------------------------------------------------------------

        local function stopScubaDance()

            danceGeneration = danceGeneration + 1

            local generation = danceGeneration

            dancing = false

            if danceTrack then
                local oldTrack = danceTrack
                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.15)
                end)
            end

            restoreNormalAnimation(generation)
        end

        ----------------------------------------------------------------
        -- REGISTER MODE CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.scubadance =
            stopScubaDance

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do
                if name ~= "scubadance"
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
            -- EXACT USERNAME / DISPLAY NAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then
                    return player
                end
            end

            ------------------------------------------------------------
            -- USERNAME PREFIX
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower():sub(1, #name) == name then
                    return player
                end
            end

            return nil
        end

        ----------------------------------------------------------------
        -- PLAY SCUBA DANCE
        ----------------------------------------------------------------

        local function playScubaDance(targetPlayer)

            ------------------------------------------------------------
            -- NEW GENERATION
            ------------------------------------------------------------

            danceGeneration = danceGeneration + 1

            local generation = danceGeneration

            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "scubadance"

            ------------------------------------------------------------
            -- SET COMMAND TARGET
            ------------------------------------------------------------

            if targetPlayer then
                _G.BotVars.CommandTarget = targetPlayer
            end

            ------------------------------------------------------------
            -- STOP OTHER MODES
            ------------------------------------------------------------

            stopOtherModes()

            if generation ~= danceGeneration then
                return
            end

            ------------------------------------------------------------
            -- STOP PREVIOUS TRACK
            ------------------------------------------------------------

            if danceTrack then
                local oldTrack = danceTrack
                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.1)
                end)
            end

            ------------------------------------------------------------
            -- GET CHARACTER
            ------------------------------------------------------------

            local character = getCharacter()

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                warn("[ScubaDance] Humanoid tidak ditemukan.")
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

                local ok, track = pcall(function()
                    return humanoid:
                        PlayEmoteAndGetAnimTrackById(
                            SCUBA_DANCE_ANIMATION_ID
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
                    "[ScubaDance] FE Animation berhasil dimainkan:",
                    SCUBA_DANCE_ANIMATION_ID,
                    "| Bot:",
                    LocalPlayer.Name
                )

                --------------------------------------------------------
                -- MONITOR TRACK
                --------------------------------------------------------

                task.spawn(function()

                    local track = result
                    local trackGeneration = generation

                    pcall(function()
                        track.Stopped:Wait()
                    end)

                    if danceTrack == track
                        and dancing
                        and trackGeneration == danceGeneration then

                        danceTrack = nil
                        dancing = false
                    end
                end)

            else

                warn(
                    "[ScubaDance] Animasi gagal dimainkan setelah",
                    maxAttempts,
                    "percobaan.",
                    "| Bot:",
                    LocalPlayer.Name,
                    "| Last Error:",
                    tostring(result)
                )
            end
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(message, sender)

            if not message or not sender then
                return
            end

            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            local isAdmin = false

            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            ------------------------------------------------------------
            -- NORMALIZE MESSAGE
            ------------------------------------------------------------

            local lower = message:lower()
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
            -- HANYA ADMIN
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

                print("[ScubaDance] Semua mode dihentikan oleh admin.")
                return
            end

            ------------------------------------------------------------
            -- !UNSCUBADANCE
            -- HANYA ADMIN
            ------------------------------------------------------------

            if lower == "!unscubadance" then

                if not isAdmin then
                    return
                end

                if _G.BotVars.ActiveMode == "scubadance" then
                    _G.BotVars.ActiveMode = nil
                end

                stopScubaDance()

                print("[ScubaDance] Dihentikan oleh admin.")
                return
            end

            ------------------------------------------------------------
            -- !SCUBADANCE
            -- ADMIN ATAU COMMAND TARGET
            ------------------------------------------------------------

            if lower == "!scubadance" then

                if not isAdmin and not isCommandTarget then
                    return
                end

                _G.BotVars.CommandTarget = sender

                playScubaDance(sender)
                return
            end

            ------------------------------------------------------------
            -- !SCUBADANCE PLAYER
            -- HANYA ADMIN
            ------------------------------------------------------------

            local targetName =
                lower:match("^!scubadance%s+(.+)$")

            if targetName then

                if not isAdmin then
                    return
                end

                local target = findPlayerByName(targetName)

                if not target then
                    warn(
                        "[ScubaDance] Player tidak ditemukan:",
                        targetName
                    )
                    return
                end

                _G.BotVars.CommandTarget = target

                playScubaDance(target)
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

            player.Chatted:Connect(function(message)
                handleCommand(message, player)
            end)
        end

        ----------------------------------------------------------------
        -- EXISTING PLAYERS
        ----------------------------------------------------------------

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayerChat(player)
        end

        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(function(player)
            connectPlayerChat(player)
        end)

        ----------------------------------------------------------------
        -- PLAYER REMOVING
        ----------------------------------------------------------------

        Players.PlayerRemoving:Connect(function(player)
            connectedPlayers[player] = nil
        end)

        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function()

            task.wait(1)

            danceGeneration = danceGeneration + 1

            local generation = danceGeneration

            danceTrack = nil
            dancing = false

            if _G.BotVars.ActiveMode == "scubadance" then

                task.wait(0.5)

                if generation ~= danceGeneration then
                    return
                end

                playScubaDance(
                    _G.BotVars.CommandTarget
                )
            end
        end)

        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[ScubaDance] Loaded untuk:",
            LocalPlayer.Name,
            "| FE Animation:",
            SCUBA_DANCE_ANIMATION_ID
        )
    end
}