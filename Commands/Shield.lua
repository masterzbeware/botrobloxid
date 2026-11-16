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
-- yang mendekati target (Admin), dan satu bot (bot aktif
-- pertama) mengirim peringatan:
-- "Harap menjauh. Ring 1 dalam pengamanan."

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

        -- Peringatan siaga (siap siaga / siap sedia):
        -- Player yang berada dalam jarak ini dari target (studs)
        -- dianggap masuk Ring 1. Bot berdiri 6 studs dari target
        -- (sudut sekitar 8,5) dan menghalangi Player secara fisik,
        -- jadi radius dibuat lebih lebar dari ring bot.
        local warningRadius = 15

        -- Seberapa sering Player di sekitar target dicek (detik).
        local warningCheckInterval = 0.5

        -- Jeda sebelum Player yang sama diperingatkan lagi (detik).
        local warningPlayerCooldown = 10

        -- Jeda minimum antar chat peringatan (detik).
        local warningChatGap = 3

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

    "11965361702", -- Bot 7
    "11960770617", -- Bot 8


}

        --------------------------------------------------
        -- VARIABLES
        --------------------------------------------------

        local humanoid
        local myHRP

        local guarding = false
        local targetPlayer = nil
        local shieldConnection = nil

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
        -- Hanya satu bot (bot aktif pertama) yang mengirim chat,
        -- supaya peringatan tidak terkirim berkali-kali oleh
        -- semua bot.
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

                task.wait(warningCheckInterval)

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
                -- HANYA BOT AKTIF PERTAMA YANG BERBICARA
                ----------------------------------------------

                local activeBots = getActiveBots()

                if activeBots[1] ~= tostring(LocalPlayer.UserId) then
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

                    sendChat(warningMessage)

                    print(
                        "[Shield] Peringatan Ring 1 dikirim.",
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
