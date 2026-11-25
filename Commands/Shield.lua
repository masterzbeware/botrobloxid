-- Shield.lua
-- MasterZ HUB
-- Formasi pengamanan / formasi berjaga:
-- bot mengelilingi Admin/Player yang berada di tengah.
--
--   B  B  B
--   B  A  B
--   B  B  B
--
--   A = Admin / Player (target)
--   B = Bot
--
-- Formasi menyesuaikan jumlah bot aktif. Posisi diisi mengikuti
-- urutan slotOrder (lihat CONFIGURATION), sehingga sisi depan,
-- belakang, kiri, dan kanan terisi lebih dulu:
-- 2 bot : depan, belakang
-- 4 bot : depan, belakang, kiri, kanan
-- 8 bot : seluruh sisi dan sudut terisi (formasi penuh)
--
-- Jarak antar posisi: 6 studs
--
-- Commands (bahasa natural, tanpa prefix):
-- shield / formasi pengamanan / formasi berjaga
-- shield <player>   (hanya Admin)
-- berhenti / stop / bubar / unshield   (hanya Admin)
--
-- Siaga (bersama Standby.lua):
-- Setelah formasi berjaga terbentuk, Admin mengetik
-- "siap siaga" atau "siap sedia". Bot lalu memantau Player
-- yang mendekati target (Admin), dan semua bot aktif
-- mengirim peringatan:
-- "Harap menjauh. Ring 1 dalam pengamanan."
--
-- Animasi siaga (Standby.lua): saat Target bergerak, animasi
-- dihentikan dulu, bot ikut bergerak, lalu animasi dimainkan
-- lagi setelah Target berhenti. Perintah stop membatalkan semuanya.

return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Shield] LocalPlayer tidak ditemukan.")
            return
        end

        --------------------------------------------------
        -- GLOBAL MODE SYSTEM
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        local vars = _G.BotVars

        vars.ModeControllers = vars.ModeControllers or {}

        --------------------------------------------------
        -- NATURAL LANGUAGE (TANPA PREFIX)
        --------------------------------------------------
        -- Parser dan kamus perintah berasal dari Perfix.lua
        -- (_G.BotVars.NLP), jadi perintah cukup ditulis dengan
        -- kata biasa.
        --
        -- Perfix.lua belum memiliki intent shield, jadi modul ini
        -- mendaftarkan intent-nya sendiri ke NLP.Intents.
        --
        -- Formasi di sekeliling pengirim (Admin atau CommandTarget):
        --   shield / formasi pengamanan / formasi berjaga
        --
        -- Formasi di sekeliling pemain lain (HANYA Admin):
        --   shield trevkaro / formasi pengamanan trevkaro
        --
        -- Berhenti (HANYA Admin):
        --   berhenti / stop / bubar / unshield
        --------------------------------------------------

        local NLP = vars.NLP

        if not NLP then

            warn(
                "[Shield] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            -- Kata umum formasi (lemah, bernilai 1) dipasangkan
            -- dengan kata penentu (bernilai 2), sama seperti
            -- intent formasi lain di Perfix.lua.
            NLP.Intents.shield =
                NLP.Intents.shield
                or {
                    Words = {
                        formasi = 1,
                        bentuk = 1,
                        barisan = 1,
                        baris = 1,
                        line = 1,

                        shield = 2,
                        pengamanan = 2,
                        pengaman = 2,
                        berjaga = 2,
                        jaga = 2,
                        jagain = 2,
                        kawal = 2,
                        mengawal = 2,
                        guard = 2,
                    },
                }

            -- "unshield" menghentikan semua mode, sama seperti
            -- unbackline / uncenterline.
            if NLP.Intents.stop
                and NLP.Intents.stop.Words then

                NLP.Intents.stop.Words.unshield =
                    NLP.Intents.stop.Words.unshield
                    or 3

            end

        end

        --------------------------------------------------
        -- LOAD ADMIN
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
                "[Shield] Gagal memuat Admin.lua:",
                Admin
            )
            return
        end

        --------------------------------------------------
        -- CONFIGURATION
        --------------------------------------------------

        -- Jarak antar posisi yang bersebelahan.
        local formationSpacing = 6

        -- Toleransi kedatangan.
        local arrivalTolerance = 1.5

        -- Gerak Target (untuk menghentikan animasi siaga):
        -- Target dianggap bergerak jika berpindah lebih dari jarak
        -- ini (studs) di bidang datar.
        local targetMoveThreshold = 0.5

        -- Target dianggap sudah berhenti setelah tidak berpindah
        -- selama waktu ini (detik). Setelah itu animasi dimainkan lagi.
        local targetStopDelay = 0.6

        -- Peringatan siaga (siap siaga / siap sedia):
        -- Player yang berada dalam jarak ini dari target (studs)
        -- dianggap masuk Ring 1. Bot berdiri 6 studs dari target,
        -- jadi 8 studs sedikit di luar jarak ring bot.
        local warningRadius = 10

        -- Seberapa sering Player di sekitar target dicek (detik).
        local warningCheckInterval = 0.8

        -- Jeda sebelum Player yang sama diperingatkan lagi (detik).
        local warningPlayerCooldown = 12

        -- Jeda minimum antar chat peringatan (detik).
        local warningChatGap = 3

        -- Jeda antar bot saat mengirim peringatan (detik). 0 = semua
        -- bot mengirim serentak. Jika lebih dari 0: Bot 1 langsung,
        -- Bot 2 setelah 1 jeda, Bot 3 setelah 2 jeda, dan seterusnya.
        local warningChatStagger = 0

        local warningMessage =
            "Harap menjauh. Ring 1 dalam pengamanan."

        --------------------------------------------------
        -- SLOT ORDER
        --------------------------------------------------
        -- Posisi bot di sekeliling target, dalam satuan
        -- formationSpacing:
        -- right   : + ke kanan target, - ke kiri target
        -- forward : + ke depan target, - ke belakang target
        --
        -- Bot aktif ke-1 menempati slot 1, bot aktif ke-2 slot 2,
        -- dan seterusnya. Urutan ini membuat sisi depan, belakang,
        -- kiri, dan kanan terisi lebih dulu sebelum sudut.
        --
        --   Slot 5   Slot 1   Slot 6
        --   Slot 3   TARGET   Slot 4
        --   Slot 7   Slot 2   Slot 8
        --------------------------------------------------

        local slotOrder = {

            { right =  0, forward =  1 }, -- Slot 1: depan
            { right =  0, forward = -1 }, -- Slot 2: belakang

            { right = -1, forward =  0 }, -- Slot 3: kiri
            { right =  1, forward =  0 }, -- Slot 4: kanan

            { right = -1, forward =  1 }, -- Slot 5: depan kiri
            { right =  1, forward =  1 }, -- Slot 6: depan kanan

            { right = -1, forward = -1 }, -- Slot 7: belakang kiri
            { right =  1, forward = -1 }, -- Slot 8: belakang kanan

            { right =  0, forward =  2 }, -- Slot 9: depan luar
            { right =  0, forward = -2 }, -- Slot 10: belakang luar

            { right = -2, forward =  0 }, -- Slot 11: kiri luar

        }

        --------------------------------------------------
        -- BOT ORDER
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


}

        --------------------------------------------------
        -- VARIABLES
        --------------------------------------------------

        local humanoid
        local myHRP

        local guarding = false
        local targetPlayer = nil
        local shieldConnection = nil

        -- Pelacak gerak Target (dipakai untuk menahan animasi siaga).
        local referencePosition = nil
        local targetMovedAt = -math.huge

        -- Menahan / melepas animasi siaga di Standby.lua lewat
        -- vars.StandbyHold. Saat mulai menahan, animasi yang sedang
        -- dimainkan langsung dihentikan lewat vars.StandbyHalt.
        local function setStandbyHold(hold)

            if vars.StandbyHold == hold then
                return
            end

            vars.StandbyHold = hold

            if hold and type(vars.StandbyHalt) == "function" then
                pcall(vars.StandbyHalt)
            end

        end

        --------------------------------------------------
        -- UPDATE CHARACTER
        --------------------------------------------------

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

        --------------------------------------------------
        -- SEND CHAT
        --------------------------------------------------

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

                    local sayMessageRequest =
                        chatEvents
                        and chatEvents:FindFirstChild(
                            "SayMessageRequest"
                        )

                    if sayMessageRequest then

                        sayMessageRequest:FireServer(
                            message,
                            "All"
                        )

                    end

                end)

            end

        end

        --------------------------------------------------
        -- STOP SHIELD
        --------------------------------------------------

        local function stopShield()

            guarding = false
            targetPlayer = nil
            referencePosition = nil
            targetMovedAt = -math.huge

            -- Lepaskan tahanan animasi siaga.
            vars.StandbyHold = false

            if shieldConnection then

                shieldConnection:Disconnect()
                shieldConnection = nil

            end

            if humanoid then
                humanoid.AutoRotate = true
            end

        end

        --------------------------------------------------
        -- REGISTER CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.shield = stopShield

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
            ) do

                if name ~= "shield"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

            end

        end

        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayerByName(name)

            if not name or name == "" then
                return nil
            end

            name = name:lower()

            -- Exact username atau display name.
            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            -- Username prefix.
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

            -- Display name prefix.
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

        --------------------------------------------------
        -- GET ACTIVE BOTS
        --------------------------------------------------
        -- Hanya bot yang benar-benar berada di server.
        -- Urutan mengikuti botOrder.
        --------------------------------------------------

        local function getActiveBots()

            local activeBots = {}

            for _, botUserId in ipairs(botOrder) do

                local botPlayer =
                    Players:GetPlayerByUserId(
                        tonumber(botUserId)
                    )

                if botPlayer then

                    table.insert(
                        activeBots,
                        tostring(botUserId)
                    )

                end

            end

            return activeBots

        end

        --------------------------------------------------
        -- START SHIELD
        --------------------------------------------------

        local function startShield(player)

            if not player then
                return
            end

            if not player:IsDescendantOf(Players) then

                warn(
                    "[Shield] Target tidak tersedia."
                )

                return

            end

            --------------------------------------------------
            -- VALIDATE ACTIVE BOT
            --------------------------------------------------

            local activeBots = getActiveBots()

            local activeIndex = table.find(
                activeBots,
                tostring(LocalPlayer.UserId)
            )

            if not activeIndex then

                warn(
                    "[Shield] Bot tidak aktif atau tidak terdaftar:",
                    LocalPlayer.UserId
                )

                return

            end

            --------------------------------------------------
            -- STOP OTHER MODES
            --------------------------------------------------

            stopOtherModes()

            --------------------------------------------------
            -- SET MODE
            --------------------------------------------------

            vars.ActiveMode = "shield"

            --------------------------------------------------
            -- STOP OLD CONNECTION
            --------------------------------------------------

            if shieldConnection then

                shieldConnection:Disconnect()
                shieldConnection = nil

            end

            --------------------------------------------------
            -- SET TARGET
            --------------------------------------------------

            guarding = true
            targetPlayer = player

            vars.CommandTarget = player

            --------------------------------------------------
            -- LOG FORMATION
            --------------------------------------------------

            print(
                "[Shield] Target:",
                player.Name
            )

            print(
                "[Shield] Active bots:",
                #activeBots
            )

            print(
                "[Shield] Bot index (slot):",
                activeIndex
            )

            --------------------------------------------------
            -- CHAT CONFIRMATION
            --------------------------------------------------

            -- Kirim konfirmasi hanya sekali per perintah, walaupun
            -- perintah yang sama terproses lebih dari sekali.
            local confirmNow = os.clock()

            if confirmNow - (_G.BotConfirmChatAt or -10) >= 1 then

                _G.BotConfirmChatAt = confirmNow

                sendChat(
                    ({ "Siap!", "Siap, laksanakan!" })[math.random(2)]
                )

            end

            --------------------------------------------------
            -- SHIELD LOOP
            --------------------------------------------------

            shieldConnection =
                RunService.Heartbeat:Connect(function()

                    --------------------------------------------------
                    -- CHECK ACTIVE MODE
                    --------------------------------------------------

                    if vars.ActiveMode ~= "shield" then

                        stopShield()
                        return

                    end

                    --------------------------------------------------
                    -- VALIDATE STATE
                    --------------------------------------------------

                    if not guarding
                        or not humanoid
                        or not myHRP
                        or not myHRP.Parent
                        or humanoid.Health <= 0
                        or not targetPlayer then

                        return

                    end

                    --------------------------------------------------
                    -- TARGET CHARACTER
                    --------------------------------------------------

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

                    --------------------------------------------------
                    -- GERAK TARGET
                    --------------------------------------------------
                    -- Target dianggap bergerak jika berpindah lebih dari
                    -- targetMoveThreshold di bidang datar, dan dianggap
                    -- berhenti setelah targetStopDelay tanpa berpindah.
                    --------------------------------------------------

                    local now = os.clock()

                    local targetFlatPosition =
                        Vector3.new(
                            targetHRP.Position.X,
                            0,
                            targetHRP.Position.Z
                        )

                    if not referencePosition
                        or (
                            targetFlatPosition
                            - referencePosition
                        ).Magnitude > targetMoveThreshold then

                        -- Posisi awal tidak dihitung sebagai gerakan.
                        if referencePosition then
                            targetMovedAt = now
                        end

                        referencePosition = targetFlatPosition

                    end

                    local targetMoving =
                        now - targetMovedAt < targetStopDelay

                    --------------------------------------------------
                    -- REFRESH ACTIVE BOTS
                    --------------------------------------------------
                    -- Dihitung ulang agar formasi menyesuaikan
                    -- saat bot masuk atau keluar server.
                    --------------------------------------------------

                    activeBots = getActiveBots()

                    activeIndex = table.find(
                        activeBots,
                        tostring(LocalPlayer.UserId)
                    )

                    if not activeIndex then
                        return
                    end

                    --------------------------------------------------
                    -- SLOT BOT INI
                    --------------------------------------------------
                    -- Bot di luar jumlah slot tidak mendapat posisi.
                    --------------------------------------------------

                    local slot = slotOrder[activeIndex]

                    if not slot then
                        return
                    end

                    --------------------------------------------------
                    -- CALCULATE POSITION
                    --------------------------------------------------

                    local targetPosition =
                        targetHRP.Position
                        + (
                            targetHRP.CFrame.RightVector
                            * (slot.right * formationSpacing)
                        )
                        + (
                            targetHRP.CFrame.LookVector
                            * (slot.forward * formationSpacing)
                        )

                    -- Samakan ketinggian dengan target.
                    targetPosition = Vector3.new(
                        targetPosition.X,
                        targetHRP.Position.Y,
                        targetPosition.Z
                    )

                    --------------------------------------------------
                    -- DISTANCE TO DESTINATION
                    --------------------------------------------------

                    local distanceToTarget =
                        (
                            myHRP.Position
                            - targetPosition
                        ).Magnitude

                    --------------------------------------------------
                    -- MOVE TO POSITION
                    --------------------------------------------------

                    -- Tahan animasi siaga selama Target bergerak atau bot
                    -- belum sampai. Saat mulai menahan, animasi dihentikan
                    -- dulu sebelum bot bergerak. Setelah Target berhenti
                    -- dan bot sampai, animasi dimainkan lagi oleh Standby.lua.
                    setStandbyHold(
                        targetMoving
                        or distanceToTarget > arrivalTolerance
                    )

                    if distanceToTarget > arrivalTolerance then

                        humanoid.AutoRotate = true

                        humanoid:MoveTo(
                            targetPosition
                        )

                        return

                    end

                    --------------------------------------------------
                    -- ARRIVED
                    -- FACE SAME DIRECTION AS TARGET
                    --------------------------------------------------

                    humanoid.AutoRotate = false

                    local targetRotation =
                        targetHRP.CFrame
                        - targetHRP.Position

                    myHRP.CFrame =
                        CFrame.new(myHRP.Position)
                        * targetRotation

                end)

        end

        --------------------------------------------------
        -- COMMAND HANDLER
        --------------------------------------------------

        local function handleCommand(message, sender)

            if not message or not sender then
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
            -- ADMIN CHECK
            --------------------------------------------------

            local isAdmin = false

            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            local isCommandTarget =
                vars.CommandTarget == sender

            --------------------------------------------------
            -- ANALYZE MESSAGE (NATURAL LANGUAGE)
            --------------------------------------------------

            local intent, args

            if NLP then
                intent, args = NLP.Classify(message, NLP.Intents)
            end

            if not intent then
                return
            end

            --------------------------------------------------
            -- STOP (berhenti / stop / bubar / unshield)
            -- HANYA ADMIN
            --------------------------------------------------

            if intent == "stop" then

                if not isAdmin then
                    return
                end

                vars.ActiveMode = nil
                vars.CommandTarget = nil

                for _, stopFunction in pairs(
                    vars.ModeControllers
                ) do

                    if type(stopFunction) == "function" then

                        pcall(stopFunction)

                    end

                end

                print(
                    "[Shield] Formasi dihentikan."
                )

                return

            end

            --------------------------------------------------
            -- SHIELD (tanpa nama)
            -- ADMIN ATAU COMMAND TARGET
            --------------------------------------------------

            if intent == "shield" and #args == 0 then

                if not isAdmin and not isCommandTarget then
                    return
                end

                startShield(sender)

                return

            end

            --------------------------------------------------
            -- SHIELD <nama pemain>
            -- HANYA ADMIN
            --------------------------------------------------

            local targetName = nil

            if intent == "shield" and #args > 0 then
                targetName = NLP.ResolveTarget(args, findPlayerByName)
            end

            if targetName then

                if not isAdmin then
                    return
                end

                local target =
                    findPlayerByName(targetName)

                if not target then

                    warn(
                        "[Shield] Player tidak ditemukan:",
                        targetName
                    )

                    return

                end

                startShield(target)

                return

            end

        end

        --------------------------------------------------
        -- CHAT CONNECTIONS
        --------------------------------------------------

        local channel

        if TextChatService
            and TextChatService.TextChannels then

            channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

        end

        if channel then

            channel.MessageReceived:Connect(function(message)

                local textSource = message.TextSource

                if not textSource then
                    return
                end

                local sender =
                    Players:GetPlayerByUserId(
                        textSource.UserId
                    )

                if sender then

                    handleCommand(
                        message.Text,
                        sender
                    )

                end

            end)

        else

            local function connectPlayer(player)

                player.Chatted:Connect(function(message)

                    handleCommand(
                        message,
                        player
                    )

                end)

            end

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                connectPlayer(player)

            end

            Players.PlayerAdded:Connect(connectPlayer)

        end

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function()

            task.wait(1)

            updateCharacter()

            if vars.ActiveMode == "shield"
                and targetPlayer then

                startShield(targetPlayer)

            end

        end)

        --------------------------------------------------
        -- PERINGATAN SIAGA (RING 1)
        --------------------------------------------------
        -- Aktif hanya jika formasi shield berjalan DAN Admin sudah
        -- mengetik "siap siaga" / "siap sedia" (Standby.lua
        -- menandainya lewat vars.StandbyEnabled).
        --
        -- Player yang masuk radius warningRadius dari target
        -- diperingatkan lewat chat. Target, Admin, dan bot tidak
        -- diperingatkan.
        --
        -- Semua bot aktif ikut mengirim chat peringatan secara serentak
        -- (warningChatStagger = 0).
        --------------------------------------------------

        local botUserIds = {}

        for _, botUserId in ipairs(botOrder) do
            botUserIds[tonumber(botUserId)] = true
        end

        local warnedAt = {}
        local lastWarningAt = -math.huge
        local wasWatching = false

        -- Mencegah monitor ganda jika module dijalankan ulang.
        local shieldRunId =
            (vars.ShieldRunId or 0) + 1

        vars.ShieldRunId = shieldRunId

        task.spawn(function()

            while true do

                -- Pengecekan diselaraskan ke waktu server supaya semua bot
                -- mendeteksi dan mengirim peringatan di saat yang sama.
                task.wait(
                    warningCheckInterval
                    - (workspace:GetServerTimeNow() % warningCheckInterval)
                )

                -- Module dijalankan ulang: monitor lama berhenti.
                if shieldRunId ~= vars.ShieldRunId then
                    return
                end

                ----------------------------------------------
                -- HANYA SAAT SHIELD AKTIF DAN SIAGA DIAKTIFKAN
                ----------------------------------------------

                local watching =
                    vars.ActiveMode == "shield"
                    and vars.StandbyEnabled == true
                    and guarding
                    and targetPlayer ~= nil

                if watching ~= wasWatching then

                    wasWatching = watching

                    print(
                        "[Shield] Pemantauan siaga:",
                        watching and "AKTIF" or "NONAKTIF",
                        "| Mode:",
                        tostring(vars.ActiveMode),
                        "| Standby:",
                        tostring(vars.StandbyEnabled),
                        "| Bot:",
                        LocalPlayer.Name
                    )

                end

                if not watching then

                    if next(warnedAt) then
                        warnedAt = {}
                    end

                    continue

                end

                ----------------------------------------------
                -- SEMUA BOT AKTIF IKUT BERBICARA
                ----------------------------------------------

                local activeBots = getActiveBots()

                local botIndex = table.find(
                    activeBots,
                    tostring(LocalPlayer.UserId)
                )

                if not botIndex then
                    continue
                end

                ----------------------------------------------
                -- POSISI TARGET
                ----------------------------------------------

                local targetCharacter =
                    targetPlayer.Character

                local targetHRP =
                    targetCharacter
                    and targetCharacter:FindFirstChild(
                        "HumanoidRootPart"
                    )

                if not targetHRP then
                    continue
                end

                ----------------------------------------------
                -- CARI PLAYER YANG MENDEKAT
                ----------------------------------------------

                local now = os.clock()
                local pending = {}

                for _, player in ipairs(Players:GetPlayers()) do

                    local trusted =
                        player == LocalPlayer
                        or player == targetPlayer
                        or botUserIds[player.UserId] == true

                    if not trusted then

                        pcall(function()
                            trusted = Admin:IsAdmin(player)
                        end)

                    end

                    if not trusted then

                        local character = player.Character

                        local rootPart =
                            character
                            and character:FindFirstChild(
                                "HumanoidRootPart"
                            )

                        local inRing =
                            rootPart
                            and (
                                rootPart.Position
                                - targetHRP.Position
                            ).Magnitude <= warningRadius

                        if inRing then

                            local lastWarned =
                                warnedAt[player.UserId]
                                or -math.huge

                            if now - lastWarned
                                >= warningPlayerCooldown then

                                table.insert(
                                    pending,
                                    player.UserId
                                )

                            end

                        else

                            -- Sudah keluar dari Ring 1: jika mendekat
                            -- lagi, langsung diperingatkan.
                            warnedAt[player.UserId] = nil

                        end

                    end

                end

                ----------------------------------------------
                -- KIRIM PERINGATAN
                ----------------------------------------------

                if #pending > 0
                    and now - lastWarningAt >= warningChatGap then

                    lastWarningAt = now

                    for _, userId in ipairs(pending) do
                        warnedAt[userId] = now
                    end

                    -- Bot ke-N bicara setelah (N - 1) * warningChatStagger detik;
                    -- dengan nilai 0 semua bot bicara bersamaan.
                    task.delay(
                        (botIndex - 1) * warningChatStagger,
                        function()

                            -- Batal jika siaga atau shield sudah berakhir.
                            if vars.ActiveMode == "shield"
                                and vars.StandbyEnabled == true then

                                sendChat(warningMessage)

                            end

                        end
                    )

                    print(
                        "[Shield] Peringatan Ring 1 dijadwalkan.",
                        "| Jumlah Player:",
                        #pending
                    )

                end

            end

        end)

        --------------------------------------------------
        -- DONE
        --------------------------------------------------

        print(
            "[Shield] Loaded successfully."
        )

        print(
            "[Shield] Jarak antar posisi:",
            formationSpacing
        )

        print(
            "[Shield] Formasi menyesuaikan bot aktif."
        )

        print(
            "[Shield] Ketik shield atau formasi pengamanan untuk memulai."
        )

    end
}
