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

        local function stopSync()
            vars.SyncTarget = nil

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
            -- CIDRO / THE BUNKER
            --------------------------------------------------
            -- Hanya membersihkan target lokal.
            -- Tidak mengirim argumen stop yang belum diketahui.
            --------------------------------------------------

            if IsCidro or IsTheBunker then
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

            message = tostring(message)
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            if message == "" then
                return
            end

            local command, targetName =
                message:match("^(%S+)%s*(.*)$")

            if not command then
                return
            end

            command = command:lower()

            if targetName then
                targetName = targetName
                    :gsub("^%s+", "")
                    :gsub("%s+$", "")
            end

            --------------------------------------------------
            -- !SYNC
            --------------------------------------------------

            if command == "!sync" then

                --------------------------------------------------
                -- !SYNC
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
                -- !SYNC USERNAME
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
            -- !STOP
            -- HANYA ADMIN
            --------------------------------------------------

            if command == "!stop" then
                if not senderIsAdmin then
                    return
                end

                --------------------------------------------------
                -- CLEAR GLOBAL STATE
                --------------------------------------------------

                vars.ActiveMode = nil
                vars.CommandTarget = nil
                vars.SyncTarget = nil

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
                    "[Sync] Perintah !stop diproses oleh admin."
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
        -- READY
        --------------------------------------------------

        print("----------------------------------------")
        print("[Sync] Loaded successfully.")
        print("[Sync] Place:", CurrentPlaceName)
        print("[Sync] PlaceId:", PlaceId)
        print("[Sync] Remote:", SyncRemote:GetFullName())
        print("[Sync] Commands:")
        print("[Sync] !sync")
        print("[Sync] !sync username")
        print("[Sync] !stop")
        print("----------------------------------------")

    end
}