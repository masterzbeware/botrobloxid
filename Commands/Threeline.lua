-- Threeline.lua
-- MasterZ HUB
-- Formasi tiga baris dengan Admin/Player di baris pertama.
--
-- Baris pertama: empat bot sejajar target (dua di kiri, dua di
-- kanan). Baris kedua: lima bot tepat di belakangnya. Baris ketiga:
-- dua bot. Seluruh bot menghadap ke arah yang sama dengan target.
--
--   B1    B2    A     B3    B4
--   B5    B6    B7    B8    B9
--   B10   B11
--
--   A = Admin / Player (target)
--   B = Bot
--
-- Jarak antarbot (kolom maupun baris): 6 studs, sama seperti
-- Centerline.
--
-- Formasi menyesuaikan bot aktif: bot aktif ke-1 menempati slot B1,
-- bot aktif ke-2 slot B2, dan seterusnya.
--
-- Commands (bahasa natural, tanpa prefix):
-- threeline / formasi tiga baris / tiga baris / barisan tiga
-- threeline <player>   (hanya Admin)
-- berhenti / stop / bubar / unthreeline   (hanya Admin)

return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
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

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- LOAD DISTANCE
        ----------------------------------------------------------------

        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        local threelining = false
        local targetPlayer = nil
        local threelineConnection = nil

        ----------------------------------------------------------------
        -- NATURAL LANGUAGE (TANPA PREFIX)
        --
        -- Parser dan kamus perintah berasal dari Perfix.lua
        -- (_G.BotVars.NLP). Perfix.lua belum memiliki intent
        -- threeline, jadi modul ini mendaftarkan intent-nya sendiri.
        --
        -- Formasi di sekitar pengirim (Admin atau CommandTarget):
        --   threeline / formasi tiga baris / tiga baris /
        --   barisan tiga / formasi tiga banjar
        --
        -- Formasi di sekitar pemain lain (HANYA Admin):
        --   threeline trevkaro / formasi tiga baris trevkaro
        --
        -- Berhenti (HANYA Admin):
        --   berhenti / stop / bubar / unthreeline
        ----------------------------------------------------------------

        local NLP = _G.BotVars.NLP

        if not NLP then

            warn(
                "[Threeline] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            -- Kata umum (formasi, baris, banjar, dll) dibuat kata
            -- pendamping (bernilai 0): dikenali parser supaya tidak
            -- dianggap nama pemain, tetapi tidak ikut menambah skor.
            -- Dengan begitu "formasi baris" tetap milik Twoline dan
            -- tidak jadi ambigu. Hanya frasa lengkapnya ("tiga baris",
            -- dst) atau kata "threeline" yang memicu perintah.
            NLP.Intents.threeline =
                NLP.Intents.threeline
                or {
                    Words = {
                        threeline = 2,

                        three = 1,
                        tiga = 1,

                        formasi = 0,
                        bentuk = 0,
                        barisan = 0,
                        baris = 0,
                        banjar = 0,
                        line = 0,
                    },

                    Phrases = {
                        ["tiga baris"] = 2,
                        ["baris tiga"] = 2,
                        ["barisan tiga"] = 2,
                        ["tiga banjar"] = 2,
                        ["banjar tiga"] = 2,
                        ["three line"] = 2,
                    },
                }

            -- "unthreeline" menghentikan semua mode, sama seperti
            -- untwoline / unfrontline / unbackline.
            if NLP.Intents.stop
                and NLP.Intents.stop.Words then

                NLP.Intents.stop.Words.unthreeline =
                    NLP.Intents.stop.Words.unthreeline
                    or 3

            end

        end

        ----------------------------------------------------------------
        -- FORMASI
        --
        -- Tiga baris dengan Target (A) di baris pertama:
        --
        --   B1    B2    A     B3    B4
        --   B5    B6    B7    B8    B9
        --   B10   B11
        --
        -- col : kolom dari kiri ke kanan (1 - 5), dilihat dari sisi
        --       Target yang menghadap ke depan. Kolom 3 adalah kolom
        --       Target.
        -- row : jumlah baris ke belakang Target (0 = sejajar Target)
        --
        -- Baris pertama melewati kolom 3 (tempat Target). Baris
        -- ketiga hanya berisi dua bot (B10 - B11) dan mengisi dua
        -- kolom pertama dari kiri, sesuai bentuk formasinya.
        ----------------------------------------------------------------

        local slotOrder = {

            { col = 1, row = 0 }, -- Slot 1 (B1)
            { col = 2, row = 0 }, -- Slot 2 (B2)
            { col = 4, row = 0 }, -- Slot 3 (B3)
            { col = 5, row = 0 }, -- Slot 4 (B4)

            { col = 1, row = 1 }, -- Slot 5 (B5)
            { col = 2, row = 1 }, -- Slot 6 (B6)
            { col = 3, row = 1 }, -- Slot 7 (B7)
            { col = 4, row = 1 }, -- Slot 8 (B8)
            { col = 5, row = 1 }, -- Slot 9 (B9)

            { col = 1, row = 2 }, -- Slot 10 (B10)
            { col = 2, row = 2 }, -- Slot 11 (B11)

        }

        -- Jumlah kolom pada baris terpanjang (dipakai untuk menengahkan
        -- seluruh blok terhadap Target).
        local columnCount = 5

        ----------------------------------------------------------------
        -- JARAK
        ----------------------------------------------------------------

        -- Jarak antar baris (studs), sama seperti Centerline.
        local adminRowDistance = 6
        local defaultRowDistance = 6

        -- Jarak antar kolom (studs), sama seperti Centerline.
        local columnSpacing = 6

        -- Toleransi kedatangan.
        local arrivalTolerance = 1.5

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

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

        ----------------------------------------------------------------
        -- UPDATE CHARACTER
        ----------------------------------------------------------------

        local function updateCharacter()

            local character =
                LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

            humanoid =
                character:WaitForChild("Humanoid")

            myHRP =
                character:WaitForChild("HumanoidRootPart")

            humanoid.AutoRotate = true

        end

        updateCharacter()

        ----------------------------------------------------------------
        -- SEND CHAT
        ----------------------------------------------------------------

        local function sendChat(message)

            local success = false

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then

                    success = pcall(function()

                        channel:SendAsync(message)

                    end)

                end

            end

            if not success then

                pcall(function()

                    local chatEvents =
                        ReplicatedStorage:FindFirstChild(
                            "DefaultChatSystemChatEvents"
                        )

                    if chatEvents then

                        local sayMessageRequest =
                            chatEvents:FindFirstChild(
                                "SayMessageRequest"
                            )

                        if sayMessageRequest then

                            sayMessageRequest:FireServer(
                                message,
                                "All"
                            )

                        end

                    end

                end)

            end

        end

        ----------------------------------------------------------------
        -- STOP THREELINE
        ----------------------------------------------------------------

        local function stopThreeline()

            threelining = false
            targetPlayer = nil

            ------------------------------------------------------------
            -- CommandTarget SENGAJA TIDAK DIHAPUS.
            --
            -- Target yang sudah ditentukan Admin tetap mempunyai
            -- hak untuk mengganti mode (follow, frontline, circle, dll).
            --
            -- CommandTarget baru dihapus oleh perintah stop Admin.
            ------------------------------------------------------------

            if threelineConnection then

                threelineConnection:Disconnect()
                threelineConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.threeline =
            stopThreeline

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "threeline"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

            end

        end

        ----------------------------------------------------------------
        -- GET ACTIVE BOTS
        --
        -- Hanya bot yang benar-benar berada di server, sesuai urutan
        -- botOrder, supaya formasi tidak berlubang jika ada bot yang
        -- belum masuk.
        ----------------------------------------------------------------

        local function getActiveBots()

            local activeBots = {}

            for _, botUserId in ipairs(botOrder) do

                if Players:GetPlayerByUserId(
                    tonumber(botUserId)
                ) then

                    table.insert(
                        activeBots,
                        tostring(botUserId)
                    )

                end

            end

            return activeBots

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

            ------------------------------------------------------------
            -- DISPLAY NAME PREFIX
            ------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.DisplayName:lower():sub(
                    1,
                    #name
                ) == name then

                    return player

                end

            end

            return nil

        end

        ----------------------------------------------------------------
        -- START THREELINE
        ----------------------------------------------------------------

        local function startThreeline(player)

            if not player then
                return
            end

            if not player:IsDescendantOf(Players) then

                warn(
                    "[Threeline] Target tidak tersedia."
                )

                return

            end

            ------------------------------------------------------------
            -- BOT HARUS TERDAFTAR DI botOrder
            ------------------------------------------------------------

            local activeBots = getActiveBots()

            local activeIndex = table.find(
                activeBots,
                tostring(LocalPlayer.UserId)
            )

            if not activeIndex then

                warn(
                    "[Threeline] Bot tidak aktif atau tidak terdaftar:",
                    LocalPlayer.UserId
                )

                stopThreeline()

                return

            end

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode =
                "threeline"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if threelineConnection then

                threelineConnection:Disconnect()
                threelineConnection = nil

            end

            ------------------------------------------------------------
            -- SET STATE
            ------------------------------------------------------------

            threelining = true
            targetPlayer = player

            ------------------------------------------------------------
            -- PENTING:
            --
            -- Set CommandTarget ke target formasi, supaya target
            -- tetap bisa mengganti mode (follow, frontline, circle, dll).
            ------------------------------------------------------------

            _G.BotVars.CommandTarget =
                player

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            -- Kirim konfirmasi hanya sekali per perintah, walaupun
            -- perintah yang sama terproses lebih dari sekali.
            local confirmNow = os.clock()

            if confirmNow - (_G.BotConfirmChatAt or -10) >= 1 then

                _G.BotConfirmChatAt = confirmNow

                sendChat(
                    "Siap!"
                )

            end

            ------------------------------------------------------------
            -- THREELINE LOOP
            ------------------------------------------------------------

            threelineConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- JIKA MODE SUDAH BERGANTI
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "threeline" then

                            stopThreeline()

                            return

                        end

                        ------------------------------------------------
                        -- VALIDASI
                        ------------------------------------------------

                        if not threelining then
                            return
                        end

                        if not humanoid
                            or not myHRP
                            or not myHRP.Parent
                            or humanoid.Health <= 0 then

                            return

                        end

                        if not targetPlayer then
                            return
                        end

                        ------------------------------------------------
                        -- TARGET CHARACTER
                        ------------------------------------------------

                        local targetCharacter =
                            targetPlayer.Character

                        if not targetCharacter then
                            return
                        end

                        local targetHRP =
                            targetCharacter:FindFirstChild(
                                "HumanoidRootPart"
                            )

                        if not targetHRP then
                            return
                        end

                        ------------------------------------------------
                        -- SLOT BOT INI
                        --
                        -- Dihitung ulang agar formasi menyesuaikan
                        -- saat bot masuk atau keluar server.
                        ------------------------------------------------

                        local currentBots = getActiveBots()

                        local currentIndex =
                            table.find(
                                currentBots,
                                tostring(LocalPlayer.UserId)
                            )

                        if not currentIndex then
                            return
                        end

                        local slot = slotOrder[currentIndex]

                        -- Bot di luar jumlah slot tidak mendapat posisi.
                        if not slot then
                            return
                        end

                        ------------------------------------------------
                        -- JARAK ANTAR BARIS
                        ------------------------------------------------

                        local rowDistance =
                            defaultRowDistance

                        if Admin:IsAdmin(
                            targetPlayer
                        ) then

                            rowDistance =
                                adminRowDistance

                        end

                        local specialDistance =
                            Distance:GetDistance(
                                tostring(
                                    LocalPlayer.UserId
                                ),
                                tostring(
                                    targetPlayer.UserId
                                )
                            )

                        if specialDistance then

                            rowDistance =
                                specialDistance

                        end

                        ------------------------------------------------
                        -- POSISI BOT
                        --
                        -- Blok ditengahkan terhadap Target: kolom 3
                        -- sejajar Target, kolom 1 di kiri dan kolom 5
                        -- di kanan.
                        ------------------------------------------------

                        local right =
                            (slot.col - ((columnCount + 1) / 2))
                            * columnSpacing

                        local targetPosition =
                            targetHRP.Position
                            +
                            (
                                targetHRP.CFrame.RightVector
                                *
                                right
                            )
                            -
                            (
                                targetHRP.CFrame.LookVector
                                *
                                (slot.row * rowDistance)
                            )

                        -- Samakan ketinggian dengan target.
                        targetPosition = Vector3.new(
                            targetPosition.X,
                            targetHRP.Position.Y,
                            targetPosition.Z
                        )

                        ------------------------------------------------
                        -- JARAK KE POSISI TUJUAN
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- JALAN KE POSISI
                        ------------------------------------------------

                        if distanceToTarget > arrivalTolerance then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ------------------------------------------------
                        -- SUDAH SAMPAI
                        -- MENGHADAP ARAH YANG SAMA DENGAN TARGET
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        local targetRotation =
                            targetHRP.CFrame
                            -
                            targetHRP.Position

                        myHRP.CFrame =
                            CFrame.new(
                                myHRP.Position
                            )
                            *
                            targetRotation

                    end
                )

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

            ------------------------------------------------------------
            -- PERINTAH TIDAK BOLEH MENGANDUNG SIMBOL
            --
            -- / \ @ ! # $ % ^ & * ( ) |
            --
            -- Perintah ditulis dengan kata biasa. Pesan yang memuat
            -- salah satu simbol di atas (di mana pun posisinya)
            -- diabaikan.
            ------------------------------------------------------------

            if type(message) ~= "string"
                or message:find("[/\\@!#$%%^&*()|]") then

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
            -- COMMAND TARGET CHECK
            ------------------------------------------------------------

            local isCommandTarget =
                (
                    _G.BotVars.CommandTarget
                    == sender
                )

            ------------------------------------------------------------
            -- ANALISA PESAN (BAHASA NATURAL)
            ------------------------------------------------------------

            local intent, args

            if NLP then

                intent, args = NLP.Classify(
                    message,
                    NLP.Intents
                )

            end

            if not intent then
                return
            end

            ------------------------------------------------------------
            -- STOP (berhenti / stop / bubar / unthreeline)
            --
            -- HANYA ADMIN.
            --
            -- CommandTarget TIDAK boleh menggunakan perintah stop.
            ------------------------------------------------------------

            if intent == "stop" then

                if not isAdmin then
                    return
                end

                --------------------------------------------------------
                -- CLEAR GLOBAL STATE
                --------------------------------------------------------

                _G.BotVars.ActiveMode =
                    nil

                _G.BotVars.CommandTarget =
                    nil

                --------------------------------------------------------
                -- STOP SEMUA MODE
                --------------------------------------------------------

                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction) ==
                        "function" then

                        pcall(
                            stopFunction
                        )

                    end

                end

                return

            end

            ----------------------------------------------------------------
            -- THREELINE
            --
            -- ADA 2 JENIS:
            --
            -- 1. threeline / formasi tiga baris (tanpa nama)
            --    Admin ATAU CommandTarget boleh.
            --
            -- 2. threeline <nama pemain>
            --    HANYA Admin.
            ----------------------------------------------------------------

            if intent == "threeline" and #args == 0 then

                ------------------------------------------------------------
                -- ADMIN ATAU COMMAND TARGET
                ------------------------------------------------------------

                if not isAdmin
                    and not isCommandTarget then

                    return

                end

                ------------------------------------------------------------
                -- FORMASI DI BELAKANG SENDER
                ------------------------------------------------------------

                _G.BotVars.CommandTarget =
                    sender

                startThreeline(
                    sender
                )

                return

            end

            ----------------------------------------------------------------
            -- THREELINE PLAYER
            --
            -- HANYA ADMIN YANG BOLEH MEMILIH TARGET BARU.
            ----------------------------------------------------------------

            local targetName = nil

            if intent == "threeline" and #args > 0 then

                for _, candidate in ipairs({
                    table.concat(args, " "),
                    args[1],
                    args[#args],
                }) do

                    if findPlayerByName(candidate) then

                        targetName = candidate
                        break

                    end

                end

            end

            if targetName then

                ------------------------------------------------------------
                -- TARGET BARU HANYA ADMIN
                ------------------------------------------------------------

                if not isAdmin then
                    return
                end

                ------------------------------------------------------------
                -- FIND PLAYER
                ------------------------------------------------------------

                local target =
                    findPlayerByName(
                        targetName
                    )

                if not target then
                    return
                end

                ------------------------------------------------------------
                -- SET COMMAND TARGET
                ------------------------------------------------------------

                _G.BotVars.CommandTarget =
                    target

                ------------------------------------------------------------
                -- START THREELINE
                ------------------------------------------------------------

                startThreeline(
                    target
                )

                return

            end

        end

        ----------------------------------------------------------------
        -- TEXT CHAT
        ----------------------------------------------------------------

        -- True jika chat modern (RBXGeneral) dipakai, supaya jalur
        -- Chatted di bawah tidak memproses pesan yang sama lagi.
        local textChatConnected = false

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

            if channel then

                textChatConnected = true

                channel.MessageReceived:Connect(
                    function(message)

                        local userId =
                            message.TextSource
                            and message.TextSource.UserId

                        local sender =
                            userId
                            and Players:GetPlayerByUserId(
                                userId
                            )

                        if sender then

                            handleCommand(
                                message.Text,
                                sender
                            )

                        end

                    end
                )

            end

        end

        ----------------------------------------------------------------
        -- FALLBACK CHAT
        ----------------------------------------------------------------

        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            player.Chatted:Connect(
                function(message)

                    if not textChatConnected then

                        handleCommand(
                            message,
                            player
                        )

                    end

                end
            )

        end

        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                player.Chatted:Connect(
                    function(message)

                        if not textChatConnected then

                            handleCommand(
                                message,
                                player
                            )

                        end

                    end
                )

            end
        )

        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()

                if _G.BotVars.ActiveMode
                    == "threeline"
                    and targetPlayer then

                    startThreeline(
                        targetPlayer
                    )

                end

            end
        )

        ----------------------------------------------------------------
        -- DONE
        ----------------------------------------------------------------

        print(
            "[Threeline] Loaded successfully."
        )

    end
}
