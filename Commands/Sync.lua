return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

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
        -- Sinkron dance ke Admin (HANYA Admin):
        --   sync / mirror / syncdance
        --   (Bot 1, 2, 3, 4, 5, 6, ... semua sinkron dance
        --    ke Admin yang mengetik perintah)
        --
        -- Batalkan sync (HANYA Admin):
        --   unsync / batalkan sync
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
                    Priority = 1,

                    Words = {
                        sync = 2,
                        mirror = 2,
                        syncdance = 2,
                    },
                }

            -- Batalkan sync: "unsync" / "batalkan sync".
            -- Kata sync / mirror / syncdance bernilai 1 di sini supaya
            -- "batalkan sync" (skor 3) menang atas intent sync (skor 2).
            NLP.Intents.unsync =
                NLP.Intents.unsync
                or {
                    Threshold = 3,
                    Priority = 2,
                    StrictRemainder = true,

                    Words = {
                        unsync = 3,

                        batalkan = 2,
                        batal = 2,

                        sync = 1,
                        mirror = 1,
                        syncdance = 1,
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
        -- URUTAN BOT
        --------------------------------------------------
        -- Urutan bot (berdasarkan UserId) sama dengan modul
        -- formasi lain. Semua bot yang hadir di server
        -- sinkron dance ke Admin.
        --------------------------------------------------

        local botOrder = {

            "11960661126", -- Bot 1
            "11960702834", -- Bot 2

            "11957234942", -- Bot 3
            "11954814620", -- Bot 4

            "11954816098", -- Bot 5
            "11960711816", -- Bot 6

            "11965361702", -- Bot 7
            "11960770617", -- Bot 8

        }

        --------------------------------------------------
        -- SETTINGS
        --------------------------------------------------

        -- Jeda antar bot saat mengirim RequestSync (detik).
        -- Bot 1 langsung, Bot 2 setelah 1x jeda, dst.
        -- Isi 0 jika semua bot harus mengirim bersamaan.
        local SYNC_STEP_DELAY = 0.2

        -- Jeda setelah membatalkan sync sebelumnya sebelum
        -- sync baru dimulai (detik).
        local SWITCH_DELAY = 1.0

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
        -- ReplicatedStorage.Events.RequestSync
        --------------------------------------------------

        local Events =
            ReplicatedStorage:WaitForChild("Events", 10)

        if not Events then
            warn("[Sync] ReplicatedStorage.Events tidak ditemukan.")
            vars.SyncLoaded = false
            return
        end

        local RequestSync =
            Events:WaitForChild("RequestSync", 10)

        if not RequestSync
            or not RequestSync:IsA("RemoteEvent") then

            warn(
                "[Sync] RequestSync tidak tersedia atau bukan RemoteEvent."
            )

            vars.SyncLoaded = false
            return
        end

        print(
            "[Sync] Remote ditemukan:",
            RequestSync:GetFullName()
        )

        --------------------------------------------------
        -- REMOTE ACTIONS
        --------------------------------------------------

        -- Sinkron dance ke pemain target
        local function fireSync(target)

            local ok, err = pcall(function()
                RequestSync:FireServer(target)
            end)

            if not ok then
                warn(
                    "[Sync] Remote gagal (sync):",
                    err
                )
            end

            return ok

        end

        -- Membatalkan sync (RequestSync dengan nil)
        local function cancelSync()

            local ok, err = pcall(function()
                RequestSync:FireServer(nil)
            end)

            if not ok then
                warn(
                    "[Sync] Remote gagal (batal):",
                    err
                )
            end

            return ok

        end

        --------------------------------------------------
        -- STATE
        --------------------------------------------------

        local syncGeneration = 0
        local syncActive = false

        --------------------------------------------------
        -- STOP SYNC
        --------------------------------------------------
        -- Membatalkan langkah yang belum berjalan dan, jika
        -- bot ini sedang sync, mengirim RequestSync(nil).
        --------------------------------------------------

        local function stopSync(forceCancel)

            syncGeneration =
                syncGeneration + 1

            vars.SyncTarget = nil

            local wasActive = syncActive

            syncActive = false

            if wasActive or forceCancel == true then

                cancelSync()

                print("[Sync] Sync dibatalkan.")

            end

            return wasActive

        end

        --------------------------------------------------
        -- REGISTER SYNC CONTROLLER
        --------------------------------------------------
        -- Mode lain yang dimulai akan memanggil controller ini,
        -- jadi sync otomatis dibatalkan.
        --------------------------------------------------

        vars.ModeControllers.sync = stopSync

        --------------------------------------------------
        -- START SYNC
        --------------------------------------------------
        -- Setiap bot mengirim RequestSync(Admin) sesuai
        -- urutannya, dipisahkan SYNC_STEP_DELAY.
        --------------------------------------------------

        local function startSync(target)

            if not target then
                return
            end

            --------------------------------------------------
            -- BATALKAN SYNC SEBELUMNYA DULU
            --------------------------------------------------

            if syncActive then

                stopSync(true)

                -- Beri waktu server memproses pembatalan.
                task.wait(SWITCH_DELAY)

            end

            --------------------------------------------------
            -- BATALKAN LANGKAH LAMA
            --------------------------------------------------

            syncGeneration =
                syncGeneration + 1

            local generation =
                syncGeneration

            syncActive = false

            --------------------------------------------------
            -- POSISI BOT INI DI botOrder
            --------------------------------------------------

            local myIndex = nil

            for index, userId in ipairs(botOrder) do

                if tonumber(userId) == LocalPlayer.UserId then
                    myIndex = index
                    break
                end

            end

            if not myIndex then

                warn(
                    "[Sync] Bot ini tidak ada di botOrder:",
                    LocalPlayer.Name
                )

                return

            end

            --------------------------------------------------
            -- VALIDASI TARGET
            --------------------------------------------------

            if target == LocalPlayer then
                return
            end

            if not target:IsDescendantOf(Players) then

                warn(
                    "[Sync] Target tidak ada di server:",
                    target.Name
                )

                return

            end

            syncActive = true

            vars.SyncTarget = target

            print(
                "[Sync] Sync dimulai | Bot:",
                LocalPlayer.Name,
                "| Posisi:",
                myIndex,
                "| Target:",
                target.Name
            )

            --------------------------------------------------
            -- JADWAL BOT INI
            --------------------------------------------------

            task.spawn(function()

                local startTime = os.clock()

                local fireAt =
                    (myIndex - 1) * SYNC_STEP_DELAY

                -- Menunggu sampai waktu tertentu.
                -- False jika sync dibatalkan / diganti.
                while os.clock() < startTime + fireAt do

                    if generation ~= syncGeneration then
                        return
                    end

                    task.wait(0.05)

                end

                if generation ~= syncGeneration then
                    return
                end

                if not target:IsDescendantOf(Players) then
                    return
                end

                fireSync(target)

                print(
                    "[Sync] Sinkron dance ke:",
                    target.Name
                )

            end)

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

            --------------------------------------------------
            -- ANALISA PESAN (BAHASA NATURAL)
            --------------------------------------------------

            local intent, args

            if NLP then
                intent, args = NLP.Classify(message, NLP.Intents)
            end

            if not intent then
                return
            end

            --------------------------------------------------
            -- SYNC / MIRROR / SYNCDANCE
            -- HANYA ADMIN. Target = Admin yang mengetik.
            --------------------------------------------------

            if intent == "sync" and #args == 0 then

                if not senderIsAdmin then

                    print(
                        "[Sync] Perintah ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end

                print(
                    "[Sync] Perintah diterima dari:",
                    sender.Name
                )

                startSync(sender)
                return
            end

            --------------------------------------------------
            -- UNSYNC / BATALKAN SYNC
            -- HANYA ADMIN
            --------------------------------------------------

            if intent == "unsync" then

                if not senderIsAdmin then
                    return
                end

                stopSync(true)
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

                -- Perintah berhenti: batalkan sync.
                stopSync(true)

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
            end)

        --------------------------------------------------
        -- GLOBAL INFO
        --------------------------------------------------

        vars.SyncRemote = RequestSync

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------
        -- Sync hilang saat respawn, jadi langkah yang
        -- belum berjalan dibatalkan.
        --------------------------------------------------

        connections.CharacterAdded =
            LocalPlayer.CharacterAdded:Connect(function()
                syncGeneration = syncGeneration + 1
                syncActive = false
            end)

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print("----------------------------------------")
        print("[Sync] Loaded successfully.")
        print("[Sync] Remote:", RequestSync:GetFullName())
        print("[Sync] Commands:")
        print("[Sync] sync / mirror / syncdance")
        print("[Sync] unsync / batalkan sync")
        print("[Sync] stop")
        print("----------------------------------------")

    end
}
