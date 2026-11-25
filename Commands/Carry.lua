return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Carry] LocalPlayer tidak ditemukan.")
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
        -- Perfix.lua belum memiliki intent carry, jadi modul ini
        -- mendaftarkan intent-nya sendiri ke NLP.Intents.
        --
        -- Formasi Ganda / berpasangan (Admin atau CommandTarget):
        --   formasi ganda
        --   (Bot 1 carry Bot 2, Bot 3 carry Bot 4,
        --    Bot 5 carry Bot 6, Bot 7 carry Bot 8)
        --
        -- Batalkan carry (HANYA Admin):
        --   uncarry / siap grak / tegak grak
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
                "[Carry] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            NLP.Intents.uncarry =
                NLP.Intents.uncarry
                or {
                    Threshold = 3,
                    Priority = 1,
                    StrictRemainder = true,

                    Words = {
                        uncarry = 3,
                    },
                }

            -- Formasi Ganda: berpasangan (Bot 1-2, 3-4, 5-6, 7-8).
            NLP.Intents.carrypair =
                NLP.Intents.carrypair
                or {
                    Priority = 1,

                    Words = {
                        formasi = 1,

                        ganda = 2,
                    },
                }

            -- Batalkan carry: "siap grak" / "tegak grak".
            -- Kata "siap" adalah kata pengisi di Perfix.lua, jadi
            -- "siap grak" dikenali lewat kata "grak" saja.
            --
            -- Priority -1 supaya "hormat grak" (Salute.lua) tetap
            -- dimenangkan intent salute saat skornya seri.
            NLP.Intents.carrystop =
                NLP.Intents.carrystop
                or {
                    Threshold = 2,
                    Priority = -1,
                    StrictRemainder = true,

                    Words = {
                        grak = 2,
                        tegak = 0,
                    },
                }

        end

        --------------------------------------------------
        -- PREVENT DUPLICATE EXECUTE
        --------------------------------------------------

        if vars.CarryLoaded then
            warn("[Carry] Carry.lua sudah aktif.")
            return
        end

        vars.CarryLoaded = true

        --------------------------------------------------
        -- URUTAN BOT
        --------------------------------------------------
        -- Urutan bot (berdasarkan UserId) sama dengan modul
        -- formasi lain. Formasi Ganda memasangkan bot secara
        -- berurutan: Bot 1-2, Bot 3-4, dan seterusnya.
        --------------------------------------------------

        local botOrder = {

            "11960661126", -- Bot 1
            "11960702834", -- Bot 2

            "11957234942", -- Bot 3
            "11954814620", -- Bot 4

            "11954816098", -- Bot 5
            "11960711816", -- Bot 6

            "11960770617", -- Bot 7
            "11965361702", -- Bot 8
            "11954797420", -- Bot 9
            "12033761173", -- Bot 10
            "12053266712", -- Bot 11
            "12054957255", -- Bot 12
            "12054957308", -- Bot 13

        }

        --------------------------------------------------
        -- SETTINGS
        --------------------------------------------------

        -- Jeda sebelum bot menerima carry setelah diminta (detik).
        local ACCEPT_DELAY = 1.5

        -- Jeda antara PromptAction dan AskCarry (detik).
        local PROMPT_DELAY = 0.3

        -- Jeda setelah berhenti (membatalkan formasi sebelumnya)
        -- sebelum formasi baru dimulai (detik).
        local SWITCH_DELAY = 1.5

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
                "[Carry] Gagal memuat Admin.lua:",
                Admin
            )

            vars.CarryLoaded = false
            return
        end

        --------------------------------------------------
        -- FIND CARRY REMOTE
        -- ReplicatedStorage.CarryReplic.CarryRemotes.CarryRemote
        -- ReplicatedStorage.CarryReplic.CarryChoices.Carry
        --------------------------------------------------

        local CarryReplic =
            ReplicatedStorage:WaitForChild("CarryReplic", 10)

        if not CarryReplic then
            warn("[Carry] ReplicatedStorage.CarryReplic tidak ditemukan.")
            vars.CarryLoaded = false
            return
        end

        local CarryRemotes =
            CarryReplic:WaitForChild("CarryRemotes", 10)

        if not CarryRemotes then
            warn("[Carry] CarryReplic.CarryRemotes tidak ditemukan.")
            vars.CarryLoaded = false
            return
        end

        local CarryRemote =
            CarryRemotes:WaitForChild("CarryRemote", 10)

        if not CarryRemote
            or not CarryRemote:IsA("RemoteEvent") then

            warn(
                "[Carry] CarryRemote tidak tersedia atau bukan RemoteEvent."
            )

            vars.CarryLoaded = false
            return
        end

        local CarryChoices =
            CarryReplic:WaitForChild("CarryChoices", 10)

        if not CarryChoices then
            warn("[Carry] CarryReplic.CarryChoices tidak ditemukan.")
            vars.CarryLoaded = false
            return
        end

        local CarryChoice =
            CarryChoices:WaitForChild("Carry", 10)

        if not CarryChoice then
            warn("[Carry] CarryChoices.Carry tidak ditemukan.")
            vars.CarryLoaded = false
            return
        end

        print(
            "[Carry] Remote ditemukan:",
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
                    "[Carry] Remote gagal:",
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

        -- Meminta carry ke pemain lain
        local function askCarry(target)

            return fireCarry({
                cmd = "AskCarry",
                carrychoicesss = CarryChoice,
                targetPlr = target,
            })

        end

        -- Menerima carry dari pemain yang meminta
        local function acceptCarry(asker)

            return fireCarry({
                cmd = "Carry",
                carrychoicesss = CarryChoice,
                firstPlr = asker,
            })

        end

        -- Membatalkan carry
        local function declineCarry()

            return fireCarry({
                cmd = "Declinecarry",
            })

        end

        -- Melepas semua gandengan (dipakai Chain.lua)
        local function cancelAll()

            return fireCarry({
                cmd = "CancelAll",
            })

        end

        --------------------------------------------------
        -- STATE
        --------------------------------------------------

        local carryGeneration = 0
        local carryActive = false

        --------------------------------------------------
        -- STOP CARRY
        --------------------------------------------------
        -- Membatalkan langkah rantai yang belum berjalan dan,
        -- jika bot ini ikut rantai, mengirim Declinecarry.
        --------------------------------------------------

        local function stopCarry(forceDecline, useCancelAll)

            carryGeneration =
                carryGeneration + 1

            -- Tidak ada formasi carry/rantai yang aktif lagi.
            vars.LinkMode = nil

            local wasActive = carryActive

            carryActive = false

            if useCancelAll == true
                and (wasActive or forceDecline == true) then

                -- Sama seperti Chain.lua: lepas dengan CancelAll.
                cancelAll()

                print("[Carry] Carry dibatalkan.")

            elseif wasActive or forceDecline == true then

                declineCarry()

                print("[Carry] Carry dibatalkan.")

            end

            return wasActive

        end

        --------------------------------------------------
        -- REGISTER CARRY CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.carry = stopCarry

        --------------------------------------------------
        -- RELEASE BEFORE START
        --------------------------------------------------
        -- Sebelum formasi baru dimulai, formasi sebelumnya (Carry
        -- atau Chain.lua) dihentikan dulu, sama seperti perintah
        -- stop, jadi tidak perlu mengetik stop dulu.
        --
        -- vars.LinkMode (dibagi dengan Chain.lua) mencatat formasi
        -- terakhir yang dimulai: nil / "carry" / "chain". Nilainya
        -- sama di semua bot karena berasal dari chat yang sama.
        --------------------------------------------------

        local function releaseBeforeStart()

            local released = false

            -- Carry sendiri (Declinecarry)
            if carryActive then

                stopCarry(true, true)

                released = true

            end

            -- Chain.lua (CancelAll)
            local chainController =
                vars.ModeControllers.chain

            if type(chainController) == "function" then

                local ok, wasActive =
                    pcall(chainController)

                if ok and wasActive == true then
                    released = true
                end

            end

            -- Beri waktu server memproses pembatalan.
            if released then
                task.wait(SWITCH_DELAY)
            end

        end

        --------------------------------------------------
        -- START PAIRS (FORMASI GANDA)
        --------------------------------------------------
        -- Berpasangan berdasarkan urutan botOrder:
        --
        --   Bot 1 carry Bot 2
        --   Bot 3 carry Bot 4
        --   Bot 5 carry Bot 6
        --   Bot 7 carry Bot 8
        --
        -- Bot bernomor ganjil meminta carry ke pasangannya:
        --   1. membuka prompt carry (PromptAction)
        --   2. meminta carry (AskCarry)
        -- Bot bernomor genap menerima carry dari pasangannya (Carry)
        -- setelah ACCEPT_DELAY.
        --
        -- Semua pasangan berjalan bersamaan. Jika salah satu bot
        -- pasangan tidak ada di server, pasangan itu dilewati.
        --------------------------------------------------

        local function startPairs(sender)

            releaseBeforeStart()

            --------------------------------------------------
            -- BATALKAN LANGKAH LAMA
            --------------------------------------------------

            carryGeneration =
                carryGeneration + 1

            local generation =
                carryGeneration

            carryActive = false

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
                    "[Carry] Bot ini tidak ada di botOrder:",
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
                    "[Carry] Pasangan Bot",
                    partnerIndex,
                    "tidak ada di server."
                )

                return

            end

            carryActive = true

            print(
                "[Carry] Formasi Ganda dimulai | Bot:",
                LocalPlayer.Name,
                "| Bot",
                myIndex,
                isAsker and "meminta carry ke" or "menerima carry dari",
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

                local function waitUntil(offset)

                    while os.clock() < startTime + offset do

                        if generation ~= carryGeneration then
                            return false
                        end

                        task.wait(0.05)

                    end

                    return generation == carryGeneration

                end

                ----------------------------------------------
                -- BOT GANJIL: PROMPT, LALU MINTA CARRY
                ----------------------------------------------

                if isAsker then

                    promptAction()

                    if not waitUntil(PROMPT_DELAY) then
                        return
                    end

                    if not partner:IsDescendantOf(Players) then
                        return
                    end

                    askCarry(partner)

                    print(
                        "[Carry] Meminta carry ke:",
                        partner.Name
                    )

                    return

                end

                ----------------------------------------------
                -- BOT GENAP: TERIMA CARRY
                ----------------------------------------------

                if not waitUntil(ACCEPT_DELAY) then
                    return
                end

                if not partner:IsDescendantOf(Players) then
                    return
                end

                acceptCarry(partner)

                print(
                    "[Carry] Menerima carry dari:",
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
            -- PERINTAH TIDAK BOLEH MENGANDUNG SIMBOL
            --
            -- / \ @ ! # $ % ^ & * ( ) |
            --
            -- Perintah ditulis dengan kata biasa. Pesan yang memuat
            -- salah satu simbol di atas (di mana pun posisinya)
            -- diabaikan.
            --------------------------------------------------

            if type(message) ~= "string"
                or message:find("[/\\@!#$%%^&*()|]") then

                return

            end

            --------------------------------------------------
            -- PERMISSIONS
            --------------------------------------------------

            local senderIsAdmin = isAdmin(sender)

            -- Pemain yang sedang diikuti bot (CommandTarget) juga boleh
            -- memulai formasi, walau bukan Admin.
            local isCommandTarget =
                vars.CommandTarget == sender

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
            -- FORMASI GANDA (BERPASANGAN)
            -- ADMIN ATAU COMMAND TARGET
            --------------------------------------------------

            if intent == "carrypair" and #args == 0 then

                if not senderIsAdmin and not isCommandTarget then

                    print(
                        "[Carry] Perintah ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end

                print(
                    "[Carry] Formasi Ganda diterima dari:",
                    sender.Name
                )

                startPairs(sender)
                return
            end

            --------------------------------------------------
            -- SIAP GRAK / TEGAK GRAK
            -- Membatalkan carry (Declinecarry), sama seperti uncarry.
            -- HANYA ADMIN
            --------------------------------------------------

            if intent == "carrystop" then

                if not senderIsAdmin then
                    return
                end

                stopCarry(true)
                return
            end

            --------------------------------------------------
            -- UNCARRY
            -- HANYA ADMIN
            --------------------------------------------------

            if intent == "uncarry" then

                if not senderIsAdmin then
                    return
                end

                stopCarry(true)
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

                -- Perintah berhenti: kirim Declinecarry.
                stopCarry(true)

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
                    "[Carry] Perintah stop diproses oleh admin."
                )

                return
            end
        end

        --------------------------------------------------
        -- CHAT CONNECTIONS
        --------------------------------------------------

        local connections = {}
        vars.CarryConnections = connections

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

        vars.CarryRemote = CarryRemote

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------
        -- Carry hilang saat respawn, jadi langkah rantai yang
        -- belum berjalan dibatalkan.
        --------------------------------------------------

        connections.CharacterAdded =
            LocalPlayer.CharacterAdded:Connect(function()
                carryGeneration = carryGeneration + 1
                carryActive = false
            end)

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print("----------------------------------------")
        print("[Carry] Loaded successfully.")
        print("[Carry] Remote:", CarryRemote:GetFullName())
        print("[Carry] Commands:")
        print("[Carry] formasi ganda")
        print("[Carry] uncarry / siap grak / tegak grak")
        print("[Carry] stop")
        print("----------------------------------------")

    end
}
