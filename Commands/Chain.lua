return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Chain] LocalPlayer tidak ditemukan.")
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
        -- Perfix.lua belum memiliki intent chain, jadi modul ini
        -- mendaftarkan intent-nya sendiri ke NLP.Intents.
        --
        -- Formasi Rantai / bergandengan (HANYA Admin):
        --   formasi rantai / formasi berantai
        --   (Bot 1 gandeng Bot 2, Bot 3 gandeng Bot 4,
        --    Bot 5 gandeng Bot 6, Bot 7 gandeng Bot 8)
        --
        -- Lepas gandengan (HANYA Admin):
        --   unchain
        --
        -- Berhenti (HANYA Admin):
        --   berhenti / stop / bubar
        --
        -- Catatan: kata "formasi" sudah dikenal Perfix.lua
        -- (kata formasi umum), jadi tidak dianggap nama pemain.
        --------------------------------------------------

        local NLP = vars.NLP

        if not NLP then

            warn(
                "[Chain] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            NLP.Intents.chain =
                NLP.Intents.chain
                or {
                    Priority = 1,

                    Words = {
                        formasi = 1,

                        rantai = 2,
                        berantai = 2,
                    },
                }

            NLP.Intents.unchain =
                NLP.Intents.unchain
                or {
                    Threshold = 3,
                    Priority = 1,
                    StrictRemainder = true,

                    Words = {
                        unchain = 3,
                    },
                }

        end

        --------------------------------------------------
        -- PREVENT DUPLICATE EXECUTE
        --------------------------------------------------

        if vars.ChainLoaded then
            warn("[Chain] Chain.lua sudah aktif.")
            return
        end

        vars.ChainLoaded = true

        --------------------------------------------------
        -- FORMASI RANTAI
        --------------------------------------------------
        -- Urutan bot (berdasarkan UserId) sama dengan modul
        -- formasi lain. Bot berpasangan dan saling bergandengan
        -- tangan:
        --
        --   Bot 1 gandeng Bot 2
        --   Bot 3 gandeng Bot 4
        --   Bot 5 gandeng Bot 6
        --   Bot 7 gandeng Bot 8
        --
        -- Bot bernomor ganjil meminta gandengan, bot bernomor
        -- genap menerima. Jika salah satu bot pasangan tidak ada
        -- di server, pasangan itu dilewati.
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

        -- Jeda sebelum bot menerima gandengan setelah diminta (detik).
        local ACCEPT_DELAY = 1.5

        -- Jeda antara PromptAction dan AskCarry (detik).
        local PROMPT_DELAY = 0.3

        -- Jeda setelah membatalkan formasi sebelumnya (Chain atau
        -- Carry) sebelum formasi baru dimulai (detik).
        local SWITCH_DELAY = 1.0

        -- Perintah remote untuk menerima gandengan.
        -- Remote spy yang tersedia hanya PromptAction, AskCarry, dan
        -- CancelAll. Perintah terima di bawah mengikuti pola Carry.lua
        -- (cmd "Carry" + pilihan + firstPlr). Jika remote spy untuk
        -- terima Gandeng Tangan berbeda, ubah nilainya di sini.
        local ACCEPT_CMD = "Carry"

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
                "[Chain] Gagal memuat Admin.lua:",
                Admin
            )

            vars.ChainLoaded = false
            return
        end

        --------------------------------------------------
        -- FIND CARRY REMOTE
        -- ReplicatedStorage.CarryReplic.CarryRemotes.CarryRemote
        -- ReplicatedStorage.CarryReplic.CarryChoices["Gandeng Tangan"]
        --------------------------------------------------

        local CarryReplic =
            ReplicatedStorage:WaitForChild("CarryReplic", 10)

        if not CarryReplic then
            warn("[Chain] ReplicatedStorage.CarryReplic tidak ditemukan.")
            vars.ChainLoaded = false
            return
        end

        local CarryRemotes =
            CarryReplic:WaitForChild("CarryRemotes", 10)

        if not CarryRemotes then
            warn("[Chain] CarryReplic.CarryRemotes tidak ditemukan.")
            vars.ChainLoaded = false
            return
        end

        local CarryRemote =
            CarryRemotes:WaitForChild("CarryRemote", 10)

        if not CarryRemote
            or not CarryRemote:IsA("RemoteEvent") then

            warn(
                "[Chain] CarryRemote tidak tersedia atau bukan RemoteEvent."
            )

            vars.ChainLoaded = false
            return
        end

        local CarryChoices =
            CarryReplic:WaitForChild("CarryChoices", 10)

        if not CarryChoices then
            warn("[Chain] CarryReplic.CarryChoices tidak ditemukan.")
            vars.ChainLoaded = false
            return
        end

        local GandengTangan =
            CarryChoices:WaitForChild("Gandeng Tangan", 10)

        if not GandengTangan then
            warn("[Chain] CarryChoices[\"Gandeng Tangan\"] tidak ditemukan.")
            vars.ChainLoaded = false
            return
        end

        print(
            "[Chain] Remote ditemukan:",
            CarryRemote:GetFullName()
        )

        --------------------------------------------------
        -- REMOTE ACTIONS
        --------------------------------------------------

        local function fireCarry(payload)

            local ok, err = pcall(function()
                CarryRemote:FireServer(payload)
            end)

            if not ok then
                warn(
                    "[Chain] Remote gagal:",
                    payload.cmd,
                    err
                )
            end

            return ok

        end

        -- PromptAction
        local function promptAction()

            return fireCarry({
                cmd = "PromptAction",
            })

        end

        -- Meminta gandengan ke pemain lain
        local function askChain(target)

            return fireCarry({
                cmd = "AskCarry",
                carrychoicesss = GandengTangan,
                targetPlr = target,
            })

        end

        -- Menerima gandengan dari pemain yang meminta
        local function acceptChain(asker)

            return fireCarry({
                cmd = ACCEPT_CMD,
                carrychoicesss = GandengTangan,
                firstPlr = asker,
            })

        end

        -- Melepas semua gandengan / carry
        local function cancelAll()

            return fireCarry({
                cmd = "CancelAll",
            })

        end

        --------------------------------------------------
        -- STATE
        --------------------------------------------------

        local chainGeneration = 0
        local chainActive = false

        --------------------------------------------------
        -- STOP CHAIN
        --------------------------------------------------
        -- Membatalkan langkah yang belum berjalan dan,
        -- jika bot ini ikut formasi rantai, mengirim CancelAll.
        --------------------------------------------------

        local function stopChain(forceCancel)

            chainGeneration =
                chainGeneration + 1

            local wasActive = chainActive

            chainActive = false

            if wasActive or forceCancel == true then

                cancelAll()

                print("[Chain] Gandengan dilepas.")

            end

            return wasActive

        end

        --------------------------------------------------
        -- REGISTER CHAIN CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.chain = stopChain

        --------------------------------------------------
        -- START CHAIN (FORMASI RANTAI)
        --------------------------------------------------
        -- Berpasangan berdasarkan urutan botOrder:
        --
        --   Bot 1 gandeng Bot 2
        --   Bot 3 gandeng Bot 4
        --   Bot 5 gandeng Bot 6
        --   Bot 7 gandeng Bot 8
        --
        -- Bot bernomor ganjil meminta gandengan ke pasangannya:
        --   1. membuka prompt (PromptAction)
        --   2. meminta gandengan (AskCarry, Gandeng Tangan)
        -- Bot bernomor genap menerima gandengan dari pasangannya
        -- setelah ACCEPT_DELAY.
        --
        -- Semua pasangan berjalan bersamaan.
        --------------------------------------------------

        local function startChain(sender)

            --------------------------------------------------
            -- BATALKAN FORMASI SEBELUMNYA OTOMATIS
            -- (Chain sendiri atau Carry.lua), jadi tidak perlu
            -- mengetik stop dulu.
            --------------------------------------------------

            local released = false

            -- Chain sendiri (CancelAll)
            if chainActive then

                stopChain(true)

                released = true

            end

            -- Carry.lua (Declinecarry)
            local carryController =
                vars.ModeControllers.carry

            if type(carryController) == "function" then

                local ok, wasActive =
                    pcall(carryController)

                if ok and wasActive == true then
                    released = true
                end

            end

            -- Beri waktu server memproses pembatalan.
            if released then
                task.wait(SWITCH_DELAY)
            end

            --------------------------------------------------
            -- BATALKAN LANGKAH LAMA
            --------------------------------------------------

            chainGeneration =
                chainGeneration + 1

            local generation =
                chainGeneration

            chainActive = false

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
                    "[Chain] Bot ini tidak ada di botOrder:",
                    LocalPlayer.Name
                )

                return

            end

            --------------------------------------------------
            -- PASANGAN
            --------------------------------------------------

            local isAsker =
                (myIndex % 2 == 1)

            local partnerIndex =
                isAsker
                and (myIndex + 1)
                or (myIndex - 1)

            local partnerUserId =
                botOrder[partnerIndex]

            local partner =
                partnerUserId
                and Players:GetPlayerByUserId(
                    tonumber(partnerUserId)
                )

            if not partner then

                warn(
                    "[Chain] Pasangan Bot",
                    partnerIndex,
                    "tidak ada di server."
                )

                return

            end

            chainActive = true

            print(
                "[Chain] Formasi Rantai dimulai | Bot:",
                LocalPlayer.Name,
                "| Bot",
                myIndex,
                isAsker and "meminta gandengan ke" or "menerima gandengan dari",
                "Bot",
                partnerIndex,
                "(" .. partner.Name .. ")",
                "| Admin:",
                sender and sender.Name or "None"
            )

            --------------------------------------------------
            -- JADWAL BOT INI
            --------------------------------------------------

            task.spawn(function()

                local startTime = os.clock()

                -- Menunggu sampai waktu tertentu.
                -- False jika formasi dibatalkan / diganti.
                local function waitUntil(offset)

                    while os.clock() < startTime + offset do

                        if generation ~= chainGeneration then
                            return false
                        end

                        task.wait(0.05)

                    end

                    return generation == chainGeneration

                end

                ----------------------------------------------
                -- BOT GANJIL: PROMPT, LALU MINTA GANDENGAN
                ----------------------------------------------

                if isAsker then

                    promptAction()

                    if not waitUntil(PROMPT_DELAY) then
                        return
                    end

                    if not partner:IsDescendantOf(Players) then
                        return
                    end

                    askChain(partner)

                    print(
                        "[Chain] Meminta gandengan ke:",
                        partner.Name
                    )

                    return

                end

                ----------------------------------------------
                -- BOT GENAP: TERIMA GANDENGAN
                ----------------------------------------------

                if not waitUntil(ACCEPT_DELAY) then
                    return
                end

                if not partner:IsDescendantOf(Players) then
                    return
                end

                acceptChain(partner)

                print(
                    "[Chain] Menerima gandengan dari:",
                    partner.Name
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
            -- FORMASI RANTAI
            -- HANYA ADMIN
            --------------------------------------------------

            if intent == "chain" and #args == 0 then

                if not senderIsAdmin then

                    print(
                        "[Chain] Perintah ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end

                print(
                    "[Chain] Perintah diterima dari:",
                    sender.Name
                )

                startChain(sender)
                return
            end

            --------------------------------------------------
            -- UNCHAIN
            -- HANYA ADMIN
            --------------------------------------------------

            if intent == "unchain" then

                if not senderIsAdmin then
                    return
                end

                stopChain(true)
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

                -- Perintah berhenti: kirim CancelAll.
                stopChain(true)

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
                    "[Chain] Perintah stop diproses oleh admin."
                )

                return
            end
        end

        --------------------------------------------------
        -- CHAT CONNECTIONS
        --------------------------------------------------

        local connections = {}
        vars.ChainConnections = connections

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
        -- CHARACTER RESPAWN
        --------------------------------------------------
        -- Gandengan hilang saat respawn, jadi langkah yang
        -- belum berjalan dibatalkan.
        --------------------------------------------------

        connections.CharacterAdded =
            LocalPlayer.CharacterAdded:Connect(function()
                chainGeneration = chainGeneration + 1
                chainActive = false
            end)

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print("----------------------------------------")
        print("[Chain] Loaded successfully.")
        print("[Chain] Remote:", CarryRemote:GetFullName())
        print("[Chain] Commands:")
        print("[Chain] formasi rantai / formasi berantai")
        print("[Chain] unchain")
        print("[Chain] stop")
        print("----------------------------------------")

    end
}
