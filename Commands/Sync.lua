return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        local PlaceId = game.PlaceId

        if not LocalPlayer then
            warn("[Sync] LocalPlayer tidak ditemukan.")
            return
        end

        --------------------------------------------------
        -- GLOBAL SYSTEM
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        local vars = _G.BotVars

        vars.ModeControllers = vars.ModeControllers or {}

        --------------------------------------------------
        -- NATURAL LANGUAGE (TANPA PREFIX)
        --------------------------------------------------
        -- Parser berasal dari Perfix.lua (_G.BotVars.NLP).
        -- Perfix.lua belum memiliki intent sync, jadi modul ini
        -- mendaftarkan intent-nya sendiri ke NLP.Intents.
        --
        -- Sync dengan target saat ini (Admin atau CommandTarget):
        --   sync / sinkron
        --
        -- Sync dengan pemain tertentu (HANYA Admin):
        --   sync trevkaro
        --
        -- Berhenti (HANYA Admin):
        --   berhenti / stop / bubar
        --------------------------------------------------

        local NLP = vars.NLP

        if not NLP then

            warn(
                "[Sync] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            NLP.Intents.sync =
                NLP.Intents.sync
                or {
                    Words = {
                        sync = 2,
                        sinkron = 2,
                        sinkronkan = 2,
                    },
                }

        end

        --------------------------------------------------
        -- PREVENT DUPLICATE EXECUTE
        --------------------------------------------------

        if vars.SyncLoaded then
            warn("[Sync] Sync.lua sudah aktif.")
            return
        end

        vars.SyncLoaded = true

        --------------------------------------------------
        -- PLACE CONFIGURATION
        --------------------------------------------------

        local PLACE_CIDRO = 79312497897212
        local PLACE_TANPANAMA = 119031818630096
        local PLACE_THE_BUNKER = 133943904733338

        local IsCidro = PlaceId == PLACE_CIDRO
        local IsTanpanama = PlaceId == PLACE_TANPANAMA
        local IsTheBunker = PlaceId == PLACE_THE_BUNKER

        local CurrentPlaceName

        if IsCidro then
            CurrentPlaceName = "Cidro Janji"

        elseif IsTanpanama then
            CurrentPlaceName = "TANPANAMA"

        elseif IsTheBunker then
            CurrentPlaceName = "THE BUNKER"

        else
            warn(
                "[Sync] Place tidak didukung.",
                "PlaceId:",
                PlaceId
            )

            vars.SyncLoaded = false
            return
        end

        print(
            "[Sync] Place terdeteksi:",
            CurrentPlaceName,
            "(" .. tostring(PlaceId) .. ")"
        )

        --------------------------------------------------
        -- LOAD ADMIN MODULE
        --------------------------------------------------

        local adminOk, Admin = pcall(function()
            local source = game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            )

            local loader, compileError = loadstring(source)

            if not loader then
                error(compileError)
            end

            return loader()
        end)

        if not adminOk or not Admin then
            warn(
                "[Sync] Gagal memuat Admin.lua:",
                Admin
            )

            vars.SyncLoaded = false
            return
        end

        --------------------------------------------------
        -- FIND SYNC REMOTE
        --------------------------------------------------

        local SyncRemote

        --------------------------------------------------
        -- CIDRO JANJI
        -- ReplicatedStorage.Events.RequestSync
        --------------------------------------------------

        if IsCidro then
            local EventsFolder =
                ReplicatedStorage:WaitForChild("Events", 10)

            if not EventsFolder then
                warn(
                    "[Sync] ReplicatedStorage.Events tidak ditemukan."
                )

                vars.SyncLoaded = false
                return
            end

            SyncRemote = EventsFolder:WaitForChild(
                "RequestSync",
                10
            )

            if not SyncRemote then
                warn("[Sync] Events.RequestSync tidak ditemukan.")
                vars.SyncLoaded = false
                return
            end

        --------------------------------------------------
        -- TANPANAMA
        -- ReplicatedStorage.Events.Dance.startSync
        --------------------------------------------------

        elseif IsTanpanama then
            local EventsFolder =
                ReplicatedStorage:WaitForChild("Events", 10)

            if not EventsFolder then
                warn(
                    "[Sync] ReplicatedStorage.Events tidak ditemukan."
                )

                vars.SyncLoaded = false
                return
            end

            local DanceFolder =
                EventsFolder:WaitForChild("Dance", 10)

            if not DanceFolder then
                warn("[Sync] Events.Dance tidak ditemukan.")
                vars.SyncLoaded = false
                return
            end

            SyncRemote = DanceFolder:WaitForChild(
                "startSync",
                10
            )

            if not SyncRemote then
                warn("[Sync] Events.Dance.startSync tidak ditemukan.")
                vars.SyncLoaded = false
                return
            end

        --------------------------------------------------
        -- THE BUNKER
        -- ReplicatedStorage.Remotes.Core.RequestSync
        --------------------------------------------------

        elseif IsTheBunker then
            local RemotesFolder =
                ReplicatedStorage:WaitForChild("Remotes", 10)

            if not RemotesFolder then
                warn(
                    "[Sync] ReplicatedStorage.Remotes tidak ditemukan."
                )

                vars.SyncLoaded = false
                return
            end

            local CoreFolder =
                RemotesFolder:WaitForChild("Core", 10)

            if not CoreFolder then
                warn(
                    "[Sync] ReplicatedStorage.Remotes.Core tidak ditemukan."
                )

                vars.SyncLoaded = false
                return
            end

            SyncRemote = CoreFolder:WaitForChild(
                "RequestSync",
                10
            )

            if not SyncRemote then
                warn(
                    "[Sync] Remotes.Core.RequestSync tidak ditemukan."
                )

                vars.SyncLoaded = false
                return
            end
        end

        --------------------------------------------------
        -- VALIDATE REMOTE
        --------------------------------------------------

        if not SyncRemote
            or not SyncRemote:IsA("RemoteEvent") then

            warn(
                "[Sync] Sync remote tidak tersedia atau bukan RemoteEvent."
            )

            vars.SyncLoaded = false
            return
        end

        print(
            "[Sync] Remote ditemukan:",
            SyncRemote:GetFullName()
        )

        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayer(name)
            if not name or name == "" then
                return nil
            end

            name = tostring(name):lower()

            --------------------------------------------------
            -- EXACT USERNAME
            --------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower() == name then
                    return player
                end
            end

            --------------------------------------------------
            -- EXACT DISPLAY NAME
            --------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do
                if player.DisplayName:lower() == name then
                    return player
                end
            end

            --------------------------------------------------
            -- USERNAME PREFIX
            --------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower():sub(1, #name) == name then
                    return player
                end
            end

            --------------------------------------------------
            -- DISPLAY NAME PREFIX
            --------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do
                if player.DisplayName:lower():sub(1, #name) == name then
                    return player
                end
            end

            return nil
        end

        --------------------------------------------------
        -- GET DEFAULT SYNC TARGET
        --------------------------------------------------
        -- Jika ada CommandTarget yang masih berada di server,
        -- gunakan target tersebut.
        --
        -- Jika tidak ada target, gunakan pengirim command.
        --
        -- Sync tidak mengubah CommandTarget.

        local function getDefaultSyncTarget(sender)
            local target = vars.CommandTarget

            if target
                and target:IsA("Player")
                and target:IsDescendantOf(Players) then

                return target
            end

            return sender
        end

        --------------------------------------------------
        -- STOP SYNC
        --------------------------------------------------
        -- Mempertahankan perilaku stop yang ada.
        -- Untuk THE BUNKER, remote stop khusus belum diketahui.
        --------------------------------------------------

        --------------------------------------------------
        -- AUTO SYNC SETTINGS
        --------------------------------------------------
        -- Animasi yang menghentikan sync selama dimainkan
        -- (sama dengan ID di Pose/Salute.lua dan Pose/Standby.lua).
        --------------------------------------------------

        local SALUTE_ANIMATION_ID = "104670223060882"
        local STANDBY_ANIMATION_ID = "99340305804606"

        -- Seberapa sering status sync dicek (detik).
        local AUTO_SYNC_INTERVAL = 0.5

        -- Jeda sebelum sync otomatis berjalan lagi setelah
        -- sync dihentikan (detik).
        local AUTO_SYNC_RESUME_DELAY = 1.5

        -- Jeda jika permintaan sync otomatis gagal (detik).
        local AUTO_SYNC_RETRY_DELAY = 5

        -- Waktu paling awal sync otomatis boleh berjalan.
        local resumeAt = 0

        local function stopSync()
            vars.SyncTarget = nil

            -- Sync otomatis berjalan lagi setelah jeda singkat.
            resumeAt = os.clock() + AUTO_SYNC_RESUME_DELAY

            --------------------------------------------------
            -- TANPANAMA
            --------------------------------------------------

            if IsTanpanama then
                local ok, err = pcall(function()
                    SyncRemote:FireServer(
                        LocalPlayer,
                        false
                    )
                end)

                if not ok then
                    warn(
                        "[Sync] Permintaan stop TANPANAMA gagal:",
                        err
                    )

                    return false
                end

                print("[Sync] Permintaan stop TANPANAMA dikirim.")
                return true
            end

            --------------------------------------------------
            -- CIDRO JANJI
            -- Events.RequestSync:FireServer(nil)
            --------------------------------------------------
            -- Stop sync = mengirim nil ke remote yang sama
            -- dengan start sync (hasil remote spy).
            --------------------------------------------------

            if IsCidro then
                local ok, err = pcall(function()
                    SyncRemote:FireServer(nil)
                end)

                if not ok then
                    warn(
                        "[Sync] Permintaan stop CIDRO gagal:",
                        err
                    )

                    return false
                end

                print("[Sync] Permintaan stop CIDRO dikirim.")
                return true
            end

            --------------------------------------------------
            -- THE BUNKER
            --------------------------------------------------
            -- Hanya membersihkan target lokal.
            -- Tidak mengirim argumen stop yang belum diketahui.
            --------------------------------------------------

            if IsTheBunker then
                print(
                    "[Sync] Target sync lokal dibersihkan:",
                    CurrentPlaceName
                )

                return true
            end

            return false
        end

        --------------------------------------------------
        -- REGISTER SYNC CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.sync = stopSync

        --------------------------------------------------
        -- REQUEST SYNC
        --------------------------------------------------

        local function requestSync(target)
            if not target then
                warn("[Sync] Target tidak ditemukan.")
                return false
            end

            if not target:IsA("Player")
                or not target:IsDescendantOf(Players) then

                warn("[Sync] Target tidak tersedia di server.")
                return false
            end

            --------------------------------------------------
            -- FIRE REMOTE BY PLACE
            --------------------------------------------------

            local ok, err = pcall(function()

                --------------------------------------------------
                -- CIDRO JANJI
                -- RequestSync:FireServer(target)
                --------------------------------------------------

                if IsCidro then
                    SyncRemote:FireServer(target)

                --------------------------------------------------
                -- TANPANAMA
                -- startSync:FireServer(target, true)
                --------------------------------------------------

                elseif IsTanpanama then
                    SyncRemote:FireServer(
                        target,
                        true
                    )

                --------------------------------------------------
                -- THE BUNKER
                -- RequestSync:FireServer(target)
                --------------------------------------------------

                elseif IsTheBunker then
                    SyncRemote:FireServer(target)
                end

            end)

            if not ok then
                warn(
                    "[Sync] Request sync gagal:",
                    err
                )

                return false
            end

            --------------------------------------------------
            -- SAVE SYNC TARGET
            --------------------------------------------------
            -- Jangan menimpa CommandTarget.
            -- Jangan mengubah ActiveMode.
            -- Follow dan formasi tetap menggunakan target mereka.
            --------------------------------------------------

            vars.SyncTarget = target

            print("[Sync] Permintaan sync dikirim.")
            print("[Sync] Place:", CurrentPlaceName)
            print("[Sync] Target:", target.Name)

            if vars.ActiveMode == "follow" then
                print(
                    "[Sync] Mode follow tetap aktif."
                )
            end

            return true
        end

        --------------------------------------------------
        -- ADMIN CHECK
        --------------------------------------------------

        local function isAdmin(sender)
            if not sender then
                return false
            end

            local ok, result = pcall(function()
                return Admin:IsAdmin(sender)
            end)

            return ok and result == true
        end

        --------------------------------------------------
        -- AUTO SYNC
        --------------------------------------------------
        -- Bot sync otomatis tanpa perlu perintah:
        --
        -- 1. Target = CommandTarget yang masih online. Jika tidak
        --    ada, gunakan Admin yang berada di server.
        --
        -- 2. Setelah sync dihentikan (misalnya perintah berhenti),
        --    sync berjalan otomatis lagi setelah jeda singkat.
        --
        -- 3. Selama animasi Salute atau Standby sedang dimainkan,
        --    sync dihentikan dan tidak dijalankan lagi sampai
        --    animasi tersebut selesai.
        --------------------------------------------------

        local function getAutoSyncTarget()
            local target = vars.CommandTarget

            if target
                and target ~= LocalPlayer
                and target:IsA("Player")
                and target:IsDescendantOf(Players) then

                return target
            end

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer
                    and isAdmin(player) then

                    return player
                end
            end

            return nil
        end

        local function isSaluteOrStandbyPlaying()
            local character = LocalPlayer.Character

            local humanoid =
                character
                and character:FindFirstChildOfClass("Humanoid")

            local animator =
                humanoid
                and humanoid:FindFirstChildOfClass("Animator")

            if not animator then
                return false
            end

            for _, track in ipairs(
                animator:GetPlayingAnimationTracks()
            ) do
                local ok, matched = pcall(function()
                    local animation = track.Animation

                    if not animation then
                        return false
                    end

                    local animationId =
                        tostring(animation.AnimationId)

                    return string.find(
                        animationId,
                        SALUTE_ANIMATION_ID,
                        1,
                        true
                    ) ~= nil
                        or string.find(
                            animationId,
                            STANDBY_ANIMATION_ID,
                            1,
                            true
                        ) ~= nil
                end)

                if ok and matched then
                    return true
                end
            end

            return false
        end

        task.spawn(function()
            while true do
                task.wait(AUTO_SYNC_INTERVAL)

                if isSaluteOrStandbyPlaying() then

                    -- Hentikan sync selama animasi berjalan.
                    if vars.SyncTarget then
                        stopSync()
                    end

                    -- Tunda sync otomatis sampai animasi selesai.
                    resumeAt = os.clock() + AUTO_SYNC_RESUME_DELAY

                elseif not vars.SyncTarget
                    and os.clock() >= resumeAt then

                    local target = getAutoSyncTarget()

                    if target and not requestSync(target) then
                        resumeAt = os.clock() + AUTO_SYNC_RETRY_DELAY
                    end

                end
            end
        end)

        --------------------------------------------------
        -- HANDLE COMMAND
        --------------------------------------------------

        local function handleCommand(sender, message)
            if not sender or not message then
                return
            end

            --------------------------------------------------
            -- PERMISSIONS
            --------------------------------------------------

            local senderIsAdmin = isAdmin(sender)

            local senderIsCommandTarget =
                vars.CommandTarget == sender

            --------------------------------------------------
            -- NORMALIZE MESSAGE
            --------------------------------------------------

            local intent, args

            if NLP then
                intent, args = NLP.Classify(message, NLP.Intents)
            end

            if not intent then
                return
            end

            local targetName = ""

            if intent == "sync" and #args > 0 then

                targetName =
                    NLP.ResolveTarget(args, findPlayer)
                    or table.concat(args, " ")

            end

            --------------------------------------------------
            -- SYNC
            --------------------------------------------------

            if intent == "sync" then

                --------------------------------------------------
                -- SYNC (tanpa nama)
                -- Gunakan CommandTarget yang masih online.
                --------------------------------------------------

                if not targetName or targetName == "" then
                    if not senderIsAdmin
                        and not senderIsCommandTarget then

                        return
                    end

                    local target =
                        getDefaultSyncTarget(sender)

                    requestSync(target)
                    return
                end

                --------------------------------------------------
                -- SYNC <nama pemain>
                -- HANYA ADMIN YANG DAPAT MEMILIH TARGET BARU.
                --------------------------------------------------

                if not senderIsAdmin then
                    return
                end

                local target = findPlayer(targetName)

                if not target then
                    warn(
                        "[Sync] Player tidak ditemukan:",
                        targetName
                    )

                    return
                end

                requestSync(target)
                return
            end

            --------------------------------------------------
            -- STOP (berhenti / stop / bubar)
            -- HANYA ADMIN
            --------------------------------------------------

            if intent == "stop" then
                if not senderIsAdmin then
                    return
                end

                --------------------------------------------------
                -- CLEAR GLOBAL STATE
                --------------------------------------------------

                vars.ActiveMode = nil
                vars.CommandTarget = nil

                -- vars.SyncTarget dihapus oleh stopSync
                -- (lewat ModeControllers di bawah).

                --------------------------------------------------
                -- STOP ALL REGISTERED MODES
                --------------------------------------------------

                for _, stopFunction in pairs(
                    vars.ModeControllers
                ) do
                    if type(stopFunction) == "function" then
                        pcall(stopFunction)
                    end
                end

                print(
                    "[Sync] Perintah stop diproses oleh admin."
                )

                return
            end
        end

        --------------------------------------------------
        -- CHAT CONNECTIONS
        --------------------------------------------------

        local connections = {}
        vars.SyncConnections = connections

        --------------------------------------------------
        -- CONNECT PLAYER CHAT
        --------------------------------------------------

        local function connectPlayer(player)
            if connections[player] then
                connections[player]:Disconnect()
            end

            connections[player] = player.Chatted:Connect(
                function(message)
                    handleCommand(player, message)
                end
            )
        end

        --------------------------------------------------
        -- EXISTING PLAYERS
        --------------------------------------------------

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayer(player)
        end

        --------------------------------------------------
        -- PLAYER ADDED
        --------------------------------------------------

        connections.PlayerAdded =
            Players.PlayerAdded:Connect(function(player)
                connectPlayer(player)
            end)

        --------------------------------------------------
        -- PLAYER REMOVING
        --------------------------------------------------

        connections.PlayerRemoving =
            Players.PlayerRemoving:Connect(function(player)

                if connections[player] then
                    connections[player]:Disconnect()
                    connections[player] = nil
                end

                if vars.SyncTarget == player then
                    vars.SyncTarget = nil
                end
            end)

        --------------------------------------------------
        -- GLOBAL INFO
        --------------------------------------------------

        vars.SyncPlace = CurrentPlaceName
        vars.SyncPlaceId = PlaceId
        vars.SyncRemote = SyncRemote

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------
        -- Sync hilang saat respawn, jadi sync otomatis
        -- diminta ulang setelah character baru siap.
        --------------------------------------------------

        connections.CharacterAdded =
            LocalPlayer.CharacterAdded:Connect(function()
                vars.SyncTarget = nil
                resumeAt = os.clock() + 2
            end)

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print("----------------------------------------")
        print("[Sync] Loaded successfully.")
        print("[Sync] Place:", CurrentPlaceName)
        print("[Sync] PlaceId:", PlaceId)
        print("[Sync] Remote:", SyncRemote:GetFullName())
        print("[Sync] Commands:")
        print("[Sync] sync")
        print("[Sync] sync username")
        print("[Sync] stop")
        print("----------------------------------------")

    end
}