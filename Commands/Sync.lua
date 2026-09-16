return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Sync] LocalPlayer tidak ditemukan.")
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

                warn("[Sync] Gagal load Admin.lua.")
                return

            end
        end


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local syncTrack = nil
        local syncTarget = nil

        local syncing = false

        local syncGeneration = 0

        ----------------------------------------------------------------
        -- STATE TARGET
        ----------------------------------------------------------------

        local lastTargetAnimationId = nil
        local lastTargetEmoteId = nil
        local lastTargetEmoteName = nil

        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayer(name)

            if not name then
                return nil
            end

            name = tostring(name):lower()

            ------------------------------------------------------------
            -- USERNAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name then
                    return player
                end

            end

            ------------------------------------------------------------
            -- DISPLAY NAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.DisplayName:lower() == name then
                    return player
                end

            end

            return nil
        end


        ----------------------------------------------------------------
        -- GET CHARACTER
        ----------------------------------------------------------------

        local function getCharacter(player)

            if not player then
                return nil
            end

            return player.Character
                or player.CharacterAdded:Wait()

        end


        ----------------------------------------------------------------
        -- NORMALIZE ID
        ----------------------------------------------------------------

        local function normalizeId(id)

            if id == nil then
                return nil
            end

            id = tostring(id)

            id = id:gsub("rbxassetid://", "")
            id = id:gsub("https://www.roblox.com/asset/%?id=", "")
            id = id:gsub("http://www.roblox.com/asset/%?id=", "")
            id = id:gsub("%s+", "")

            return id
        end


        ----------------------------------------------------------------
        -- GET ANIMATION TRACKS
        ----------------------------------------------------------------

        local function getAnimationTracks(player)

            local character =
                getCharacter(player)

            if not character then
                return {}
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                return {}
            end

            local animator =
                humanoid:FindFirstChildOfClass("Animator")

            if not animator then
                return {}
            end

            local success, tracks =
                pcall(function()

                    return animator:GetPlayingAnimationTracks()

                end)

            if not success or not tracks then
                return {}
            end

            return tracks
        end


        ----------------------------------------------------------------
        -- GET ALL REGISTERED EMOTES
        ----------------------------------------------------------------

        local function getRegisteredEmotes(player)

            local character =
                getCharacter(player)

            if not character then
                return {}
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                return {}
            end

            local success, description =
                pcall(function()

                    return humanoid:GetAppliedDescription()

                end)

            if not success or not description then
                return {}
            end

            local success2, emotes =
                pcall(function()

                    return description:GetEmotes()

                end)

            if not success2 or type(emotes) ~= "table" then
                return {}
            end

            return emotes
        end


        ----------------------------------------------------------------
        -- GET EQUIPPED EMOTES
        ----------------------------------------------------------------

        local function getEquippedEmotes(player)

            local character =
                getCharacter(player)

            if not character then
                return {}
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                return {}
            end

            local success, description =
                pcall(function()

                    return humanoid:GetAppliedDescription()

                end)

            if not success or not description then
                return {}
            end

            local success2, equipped =
                pcall(function()

                    return description:GetEquippedEmotes()

                end)

            if not success2 or type(equipped) ~= "table" then
                return {}
            end

            return equipped
        end


        ----------------------------------------------------------------
        -- EXTRACT EMOTE ID
        ----------------------------------------------------------------

        local function extractEmoteId(data)

            if data == nil then
                return nil
            end

            ------------------------------------------------------------
            -- NUMBER
            ------------------------------------------------------------

            if type(data) == "number" then

                return normalizeId(data)

            end

            ------------------------------------------------------------
            -- STRING
            ------------------------------------------------------------

            if type(data) == "string" then

                return normalizeId(data)

            end

            ------------------------------------------------------------
            -- TABLE
            ------------------------------------------------------------

            if type(data) == "table" then

                --------------------------------------------------------
                -- Common Roblox format:
                -- {123456789}
                --------------------------------------------------------

                for _, value in pairs(data) do

                    if type(value) == "number"
                        or type(value) == "string" then

                        local id =
                            normalizeId(value)

                        if id and id ~= "" then
                            return id
                        end

                    end

                end

            end

            return nil
        end


        ----------------------------------------------------------------
        -- BUILD EMOTE MAP
        --
        -- RESULT:
        --
        -- {
        --     ["Dance"] = "123456",
        --     ["Wave"] = "987654"
        -- }
        ----------------------------------------------------------------

        local function buildEmoteMap(player)

            local emotes =
                getRegisteredEmotes(player)

            local map = {}

            for name, data in pairs(emotes) do

                local emoteId =
                    extractEmoteId(data)

                if emoteId then

                    map[tostring(name)] =
                        emoteId

                end

            end

            return map
        end


        ----------------------------------------------------------------
        -- FIND EMOTE BY ID
        ----------------------------------------------------------------

        local function findEmoteById(player, emoteId)

            if not emoteId then
                return nil
            end

            emoteId =
                normalizeId(emoteId)

            local map =
                buildEmoteMap(player)

            for name, id in pairs(map) do

                if normalizeId(id) == emoteId then

                    return {
                        Name = name,
                        Id = id
                    }

                end

            end

            return nil
        end


        ----------------------------------------------------------------
        -- GET CURRENT ANIMATION
        --
        -- IMPORTANT:
        -- We still read AnimationTrack only to detect that
        -- target is currently doing an animation.
        --
        -- We DO NOT use AnimationTrack ID as the sync ID.
        ----------------------------------------------------------------

        local function getCurrentAnimation(player)

            local tracks =
                getAnimationTracks(player)

            local bestTrack = nil
            local bestPriority = -math.huge

            for _, track in ipairs(tracks) do

                if track
                    and track.IsPlaying
                    and track.Animation
                    and track.Animation.AnimationId
                    and track.Animation.AnimationId ~= "" then

                    local priorityValue = 0

                    if track.Priority ==
                        Enum.AnimationPriority.Action4 then

                        priorityValue = 4

                    elseif track.Priority ==
                        Enum.AnimationPriority.Action3 then

                        priorityValue = 3

                    elseif track.Priority ==
                        Enum.AnimationPriority.Action2 then

                        priorityValue = 2

                    elseif track.Priority ==
                        Enum.AnimationPriority.Action then

                        priorityValue = 1

                    elseif track.Priority ==
                        Enum.AnimationPriority.Movement then

                        priorityValue = 0

                    elseif track.Priority ==
                        Enum.AnimationPriority.Idle then

                        priorityValue = -1

                    elseif track.Priority ==
                        Enum.AnimationPriority.Core then

                        priorityValue = -2

                    end

                    if priorityValue > bestPriority then

                        bestPriority =
                            priorityValue

                        bestTrack =
                            track

                    end

                end

            end

            return bestTrack
        end


        ----------------------------------------------------------------
        -- GET ANIMATION ID
        ----------------------------------------------------------------

        local function getAnimationId(track)

            if not track then
                return nil
            end

            if not track.Animation then
                return nil
            end

            local id =
                track.Animation.AnimationId

            if not id or id == "" then
                return nil
            end

            return normalizeId(id)
        end


        ----------------------------------------------------------------
        -- DETECT EMOTE
        --
        -- This function tries to identify an emote from the
        -- target's currently registered emotes.
        --
        -- IMPORTANT:
        -- Roblox does NOT expose a public "currently playing emote"
        -- property for another player.
        ----------------------------------------------------------------

        local function detectTargetEmote(player, track)

            if not track then
                return nil
            end

            local animationId =
                getAnimationId(track)

            if not animationId then
                return nil
            end

            ------------------------------------------------------------
            -- 1. Build registered emote map
            ------------------------------------------------------------

            local emoteMap =
                buildEmoteMap(player)

            ------------------------------------------------------------
            -- 2. Direct match
            --
            -- This works if Emote ID == Animation ID.
            ------------------------------------------------------------

            for name, emoteId in pairs(emoteMap) do

                if normalizeId(emoteId) ==
                    animationId then

                    return {
                        Name = name,
                        Id = normalizeId(emoteId),
                        AnimationId = animationId,
                        Method = "DIRECT"
                    }

                end

            end

            ------------------------------------------------------------
            -- 3. SPECIAL CASE
            --
            -- Your case:
            --
            -- Emote ID:
            -- 104131847054135
            --
            -- Playing Animation:
            -- 83796130837213
            --
            -- Because Roblox can resolve a marketplace emote
            -- to another animation asset, the IDs may differ.
            --
            -- We therefore do NOT return the animation ID
            -- as an emote ID.
            ------------------------------------------------------------

            return nil
        end


        ----------------------------------------------------------------
        -- PLAY BOT EMOTE BY NAME
        ----------------------------------------------------------------

        local function playBotEmoteByName(
            emoteName,
            generation
        )

            if not emoteName then
                return nil
            end

            if generation ~= syncGeneration then
                return nil
            end

            local character =
                getCharacter(LocalPlayer)

            if not character then
                return nil
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                return nil
            end

            ------------------------------------------------------------
            -- Stop old track
            ------------------------------------------------------------

            if syncTrack then

                local oldTrack =
                    syncTrack

                syncTrack = nil

                pcall(function()

                    oldTrack:Stop(0.1)

                end)

            end

            ------------------------------------------------------------
            -- PLAY EMOTE
            --
            -- This is preferable to LoadAnimation because we are
            -- synchronizing the emote itself.
            ------------------------------------------------------------

            local success =
                pcall(function()

                    humanoid:PlayEmoteAsync(
                        emoteName
                    )

                end)

            if not success then

                --------------------------------------------------------
                -- Fallback to deprecated PlayEmote
                --------------------------------------------------------

                local fallbackSuccess =
                    pcall(function()

                        humanoid:PlayEmote(
                            emoteName
                        )

                    end)

                if not fallbackSuccess then
                    return nil
                end

            end

            ------------------------------------------------------------
            -- Find resulting track
            ------------------------------------------------------------

            task.wait()

            local animator =
                humanoid:FindFirstChildOfClass("Animator")

            if not animator then
                return nil
            end

            local tracks =
                animator:GetPlayingAnimationTracks()

            local newestTrack = nil

            for _, track in ipairs(tracks) do

                if track
                    and track.IsPlaying then

                    if track.Priority ==
                        Enum.AnimationPriority.Action4
                        or track.Priority ==
                        Enum.AnimationPriority.Action3
                        or track.Priority ==
                        Enum.AnimationPriority.Action2
                        or track.Priority ==
                        Enum.AnimationPriority.Action then

                        newestTrack = track
                        break

                    end

                end

            end

            if newestTrack then

                syncTrack =
                    newestTrack

                pcall(function()

                    newestTrack.Looped = true

                end)

                return newestTrack

            end

            return nil
        end


        ----------------------------------------------------------------
        -- PLAY BOT EMOTE BY ID
        --
        -- Used when we KNOW the actual Emote ID.
        ----------------------------------------------------------------

        local function playBotEmoteById(
            emoteId,
            generation
        )

            if not emoteId then
                return nil
            end

            if generation ~= syncGeneration then
                return nil
            end

            local character =
                getCharacter(LocalPlayer)

            if not character then
                return nil
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                return nil
            end

            ------------------------------------------------------------
            -- Stop current sync track
            ------------------------------------------------------------

            if syncTrack then

                local oldTrack =
                    syncTrack

                syncTrack = nil

                pcall(function()

                    oldTrack:Stop(0.1)

                end)

            end

            ------------------------------------------------------------
            -- PlayEmoteAndGetAnimTrackById
            --
            -- This method is internal Roblox API.
            -- It may work in executor environments, but is not
            -- guaranteed by public Roblox API.
            ------------------------------------------------------------

            local success, result =
                pcall(function()

                    return humanoid:
                        PlayEmoteAndGetAnimTrackById(
                            tonumber(emoteId)
                        )

                end)

            if success and result then

                local track = result

                syncTrack =
                    track

                pcall(function()

                    track.Looped = true

                end)

                return track
            end

            ------------------------------------------------------------
            -- If direct ID fails, try finding the name
            ------------------------------------------------------------

            local emote =
                findEmoteById(
                    LocalPlayer,
                    emoteId
                )

            if emote then

                return playBotEmoteByName(
                    emote.Name,
                    generation
                )

            end

            return nil
        end


        ----------------------------------------------------------------
        -- STOP SYNC
        ----------------------------------------------------------------

        local function stopSync()

            syncGeneration =
                syncGeneration + 1

            syncing = false

            syncTarget = nil

            lastTargetAnimationId = nil
            lastTargetEmoteId = nil
            lastTargetEmoteName = nil

            if syncTrack then

                local oldTrack =
                    syncTrack

                syncTrack = nil

                pcall(function()

                    oldTrack:Stop(0.15)

                end)

            end

            print(
                "[Sync] Sync dihentikan | Bot:",
                LocalPlayer.Name
            )
        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.sync =
            stopSync


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "sync"
                    and type(stopFunction) == "function" then

                    pcall(function()

                        stopFunction()

                    end)

                end

            end

        end


        ----------------------------------------------------------------
        -- START SYNC
        ----------------------------------------------------------------

        local function startSync(target)

            if not target then
                return
            end

            syncGeneration =
                syncGeneration + 1

            local generation =
                syncGeneration

            stopOtherModes()

            _G.BotVars.ActiveMode =
                "sync"

            syncTarget =
                target

            syncing =
                true

            lastTargetAnimationId = nil
            lastTargetEmoteId = nil
            lastTargetEmoteName = nil

            print(
                "[Sync] Target:",
                target.Name,
                "| DisplayName:",
                target.DisplayName
            )


            ----------------------------------------------------------------
            -- MONITOR TARGET
            ----------------------------------------------------------------

            task.spawn(function()

                while syncing
                    and syncTarget == target
                    and generation == syncGeneration
                    and target.Parent do


                    ----------------------------------------------------------------
                    -- GET CURRENT TRACK
                    ----------------------------------------------------------------

                    local targetTrack =
                        getCurrentAnimation(target)

                    local animationId =
                        getAnimationId(targetTrack)


                    ----------------------------------------------------------------
                    -- NO ANIMATION
                    ----------------------------------------------------------------

                    if not targetTrack
                        or not animationId then

                        if syncTrack then

                            pcall(function()

                                syncTrack:Stop(0.15)

                            end)

                            syncTrack = nil

                        end

                        lastTargetAnimationId = nil
                        lastTargetEmoteId = nil
                        lastTargetEmoteName = nil

                        task.wait(0.15)

                        continue
                    end


                    ----------------------------------------------------------------
                    -- TRY DETECT EMOTE
                    ----------------------------------------------------------------

                    local emote =
                        detectTargetEmote(
                            target,
                            targetTrack
                        )


                    ----------------------------------------------------------------
                    -- EMOTE FOUND
                    ----------------------------------------------------------------

                    if emote then

                        local changed =
                            emote.Id ~=
                                lastTargetEmoteId

                            or
                            emote.Name ~=
                                lastTargetEmoteName

                            or
                            not syncTrack

                            or
                            not syncTrack.IsPlaying


                        if changed then

                            print(
                                "[Sync] EMOTE DETECTED:",
                                emote.Name,
                                "| EmoteID:",
                                emote.Id,
                                "| AnimationID:",
                                animationId
                            )

                            local newTrack =
                                playBotEmoteById(
                                    emote.Id,
                                    generation
                                )

                            if newTrack then

                                lastTargetEmoteId =
                                    emote.Id

                                lastTargetEmoteName =
                                    emote.Name

                                lastTargetAnimationId =
                                    animationId

                                print(
                                    "[Sync] Bot memainkan EMOTE:",
                                    emote.Name,
                                    "| ID:",
                                    emote.Id
                                )

                            end

                        end


                    ----------------------------------------------------------------
                    -- UNKNOWN ANIMATION
                    ----------------------------------------------------------------

                    else

                        ------------------------------------------------------------
                        -- IMPORTANT
                        --
                        -- Jangan langsung memainkan animation ID karena
                        -- bisa saja animation tersebut sebenarnya adalah
                        -- hasil resolusi sebuah marketplace emote.
                        ------------------------------------------------------------

                        if animationId ~=
                            lastTargetAnimationId then

                            print(
                                "[Sync] Animation terdeteksi:",
                                animationId,
                                "| Tetapi belum dapat dipastikan sebagai Emote."
                            )

                            lastTargetAnimationId =
                                animationId

                        end

                    end


                    task.wait(0.15)

                end

            end)

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


            ----------------------------------------------------------------
            -- ADMIN CHECK
            ----------------------------------------------------------------

            local isAdmin =
                false

            pcall(function()

                isAdmin =
                    Admin:IsAdmin(sender)

            end)

            if not isAdmin then
                return
            end


            ----------------------------------------------------------------
            -- CLEAN MESSAGE
            ----------------------------------------------------------------

            local lower =
                message:lower()

            lower =
                lower:gsub("^%s+", "")

            lower =
                lower:gsub("%s+$", "")


            ----------------------------------------------------------------
            -- !SYNC
            ----------------------------------------------------------------

            if lower:sub(1, 6) == "!sync " then

                local targetName =
                    message:
                        sub(7):
                        gsub("^%s+", ""):
                        gsub("%s+$", "")

                if targetName == "" then

                    warn(
                        "[Sync] Gunakan: !sync Username/DisplayName"
                    )

                    return
                end

                local target =
                    findPlayer(targetName)

                if not target then

                    warn(
                        "[Sync] Player tidak ditemukan:",
                        targetName
                    )

                    return
                end

                print(
                    "[Sync] Command diterima | Bot:",
                    LocalPlayer.Name,
                    "| Target:",
                    target.Name,
                    "| DisplayName:",
                    target.DisplayName
                )

                startSync(target)

                return
            end


            ----------------------------------------------------------------
            -- !UNSYNC
            ----------------------------------------------------------------

            if lower == "!unsync" then

                if _G.BotVars.ActiveMode ==
                    "sync" then

                    _G.BotVars.ActiveMode = nil

                end

                stopSync()

                return
            end


            ----------------------------------------------------------------
            -- !STOP
            ----------------------------------------------------------------

            if lower == "!stop" then

                if _G.BotVars.ActiveMode ==
                    "sync" then

                    _G.BotVars.ActiveMode = nil

                    stopSync()

                end

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

            connectPlayerChat(player)

        end


        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                connectPlayerChat(player)

            end
        )


        ----------------------------------------------------------------
        -- PLAYER REMOVING
        ----------------------------------------------------------------

        Players.PlayerRemoving:Connect(
            function(player)

                connectedPlayers[player] = nil

                if syncTarget == player then

                    stopSync()

                    if _G.BotVars.ActiveMode ==
                        "sync" then

                        _G.BotVars.ActiveMode = nil

                    end

                end

            end
        )


        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                if _G.BotVars.ActiveMode ==
                    "sync"
                    and syncTarget then

                    syncGeneration =
                        syncGeneration + 1

                    local target =
                        syncTarget

                    syncTrack = nil

                    local generation =
                        syncGeneration

                    task.wait(0.5)

                    if syncing
                        and syncTarget == target
                        and generation == syncGeneration then

                        local targetTrack =
                            getCurrentAnimation(target)

                        if targetTrack then

                            local emote =
                                detectTargetEmote(
                                    target,
                                    targetTrack
                                )

                            if emote then

                                playBotEmoteById(
                                    emote.Id,
                                    generation
                                )

                                lastTargetEmoteId =
                                    emote.Id

                                lastTargetEmoteName =
                                    emote.Name

                            end

                        end

                    end

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Sync] Loaded untuk:",
            LocalPlayer.Name
        )

    end
}