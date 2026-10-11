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

        local IsTanpanama = PlaceId == PLACE_TANPANAMA
        local IsCidro = PlaceId == PLACE_CIDRO

        local CurrentPlaceName

        if IsCidro then
            CurrentPlaceName = "Cidro Janji"
        elseif IsTanpanama then
            CurrentPlaceName = "TANPANAMA"
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
            warn("[Sync] Gagal memuat Admin.lua:", Admin)
            vars.SyncLoaded = false
            return
        end

        --------------------------------------------------
        -- FIND EVENTS FOLDER
        --------------------------------------------------

        local EventsFolder =
            ReplicatedStorage:WaitForChild("Events", 10)

        if not EventsFolder then
            warn(
                "[Sync] ReplicatedStorage.Events tidak ditemukan."
            )

            vars.SyncLoaded = false
            return
        end

        --------------------------------------------------
        -- GET SYNC REMOTE
        --------------------------------------------------

        local SyncRemote

        if IsCidro then
            SyncRemote = EventsFolder:WaitForChild(
                "RequestSync",
                10
            )

            if not SyncRemote then
                warn("[Sync] RequestSync tidak ditemukan.")
                vars.SyncLoaded = false
                return
            end

            print("[Sync] Remote: Events.RequestSync")

        elseif IsTanpanama then
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
                warn("[Sync] startSync tidak ditemukan.")
                vars.SyncLoaded = false
                return
            end

            print("[Sync] Remote: Events.Dance.startSync")
        end

        --------------------------------------------------
        -- VALIDATE REMOTE
        --------------------------------------------------

        if not SyncRemote
            or not SyncRemote:IsA("RemoteEvent") then

            warn("[Sync] Sync remote bukan RemoteEvent.")
            vars.SyncLoaded = false
            return
        end

        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayer(name)
            if not name or name == "" then
                return nil
            end

            name = tostring(name):lower()

            -- Exact username
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower() == name then
                    return player
                end
            end

            -- Exact display name
            for _, player in ipairs(Players:GetPlayers()) do
                if player.DisplayName:lower() == name then
                    return player
                end
            end

            -- Username prefix
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower():sub(1, #name) == name then
                    return player
                end
            end

            -- Display name prefix
            for _, player in ipairs(Players:GetPlayers()) do
                if player.DisplayName:lower():sub(1, #name) == name then
                    return player
                end
            end

            return nil
        end

        --------------------------------------------------
        -- GET CURRENT FOLLOW TARGET
        --------------------------------------------------
        -- PENTING:
        --
        -- CommandTarget dikelola oleh sistem movement,
        -- misalnya Follow.lua.
        --
        -- Sync tidak boleh mengganti CommandTarget.
        --
        -- Jika admin sebelumnya mengetik:
        -- !follow namaPlayer
        --
        -- Lalu mengetik:
        -- !sync
        --
        -- target sync menggunakan CommandTarget yang sama.
        --------------------------------------------------

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

        local function stopSync()
            --------------------------------------------------
            -- JANGAN MEMATIKAN FOLLOW
            --------------------------------------------------
            -- Sync adalah mode tambahan.
            -- ActiveMode milik Follow/formasi tidak diubah.
            --------------------------------------------------

            vars.SyncTarget = nil

            --------------------------------------------------
            -- TANPANAMA: REQUEST STOP
            --------------------------------------------------

            if IsTanpanama then
                local ok, err = pcall(function()
                    SyncRemote:FireServer(
                        LocalPlayer,
                        false
                    )
                end)

                if not ok then
                    warn("[Sync] Permintaan stop gagal:", err)
                    return false
                end

                print("[Sync] Permintaan stop TANPANAMA dikirim.")
                return true
            end

            --------------------------------------------------
            -- CIDRO JANJI
            --------------------------------------------------
            -- Mempertahankan perilaku lama.
            -- Remote stop khusus Cidro belum ditambahkan,
            -- karena argumen stop-nya belum diketahui.
            --------------------------------------------------

            if IsCidro then
                print(
                    "[Sync] Target sync lokal dibersihkan untuk Cidro Janji."
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
        -- Sync tidak menghentikan movement mode.
        -- Sync juga tidak mengganti CommandTarget.
        --------------------------------------------------

        local function requestSync(target)
            if not target then
                warn("[Sync] Target tidak ditemukan.")
                return false
            end

            if not target:IsA("Player")
                or not target:IsDescendantOf(Players) then

                warn("[Sync] Target sudah tidak tersedia.")
                return false
            end

            --------------------------------------------------
            -- JANGAN STOP OTHER MODES
            --------------------------------------------------
            -- Jangan panggil stopOtherModes().
            -- Jangan mengubah vars.ActiveMode.
            -- Jangan mengubah vars.CommandTarget.
            --
            -- Dengan demikian Follow.lua tetap berjalan.
            --------------------------------------------------

            local ok, err = pcall(function()
                if IsCidro then
                    SyncRemote:FireServer(target)

                elseif IsTanpanama then
                    SyncRemote:FireServer(target, true)
                end
            end)

            if not ok then
                warn("[Sync] Request sync gagal:", err)
                return false
            end

            --------------------------------------------------
            -- ONLY UPDATE SYNC TARGET
            --------------------------------------------------

            vars.SyncTarget = target

            print("[Sync] Permintaan sync dikirim.")
            print("[Sync] Place:", CurrentPlaceName)
            print("[Sync] Target sync:", target.Name)

            if vars.ActiveMode == "follow" then
                print(
                    "[Sync] Follow tetap aktif ke:",
                    vars.CommandTarget
                        and vars.CommandTarget.Name
                        or "target sebelumnya"
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
            -- ADMIN / COMMAND TARGET
            --------------------------------------------------

            local senderIsAdmin = isAdmin(sender)

            local senderIsCommandTarget =
                vars.CommandTarget == sender

            --------------------------------------------------
            -- NORMALIZE MESSAGE
            --------------------------------------------------

            message = tostring(message)
                :lower()
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
                -- !sync
                -- Gunakan target follow yang aktif jika ada.
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
                -- !sync username
                -- Hanya admin yang boleh menentukan target lain.
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

                -- Tidak mengganti vars.CommandTarget.
                requestSync(target)
                return
            end

            --------------------------------------------------
            -- !STOP
            -- Hanya admin yang boleh menghentikan semua mode.
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
        print("[Sync] Sync tidak akan mengganti movement mode.")
        print("[Sync] Commands:")
        print("[Sync] !sync")
        print("[Sync] !sync username")
        print("[Sync] !stop")
        print("----------------------------------------")
    end
}