-- Horseshoes.lua
-- MasterZ HUB
-- Formasi tapal kuda (lingkaran terbuka) di sekitar Admin/Player.
--
-- Bot membentuk huruf U terbalik di depan dan di kedua sisi target,
-- sedangkan bagian belakang target terbuka.
--
--          B1  B2
--   B3  B8  A  B7  B4
--   B5                B6
--
--   A = Admin / Player (target)
--   B = Bot
--
-- (atas = depan target)
--
-- Formasi menyesuaikan bot aktif: bot aktif ke-1 menempati slot B1,
-- bot aktif ke-2 slot B2, dan seterusnya.
--
-- Jarak antar posisi: 6 studs
--
-- Commands (bahasa natural, tanpa prefix):
-- formasi tapal kuda / tapal kuda / lingkaran terbuka
-- formasi tapal kuda <player>   (hanya Admin)
-- berhenti / stop / bubar / unhorseshoes   (hanya Admin)

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

        local horseshoeing = false
        local targetPlayer = nil
        local horseshoeConnection = nil

        ----------------------------------------------------------------
        -- NATURAL LANGUAGE (TANPA PREFIX)
        --
        -- Parser dan kamus perintah berasal dari Perfix.lua
        -- (_G.BotVars.NLP). Perfix.lua belum memiliki intent
        -- horseshoes, jadi modul ini mendaftarkan intent-nya sendiri.
        --
        -- Formasi di sekitar pengirim (Admin atau CommandTarget):
        --   formasi tapal kuda / tapal kuda / lingkaran terbuka
        --
        -- Formasi di sekitar pemain lain (HANYA Admin):
        --   formasi tapal kuda trevkaro / lingkaran terbuka trevkaro
        --
        -- Berhenti (HANYA Admin):
        --   berhenti / stop / bubar / unhorseshoes
        ----------------------------------------------------------------

        local NLP = _G.BotVars.NLP

        if not NLP then

            warn(
                "[Horseshoes] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            -- Kata "tapal", "kuda", "lingkaran", dan "terbuka" dibuat
            -- kata pendamping (bernilai 0): dikenali parser, tetapi
            -- hanya frasa lengkapnya yang memicu perintah. Dengan
            -- begitu "formasi lingkaran" tetap milik Circle, dan
            -- "formasi terbuka" saja tidak ikut terbaca.
            NLP.Intents.horseshoes =
                NLP.Intents.horseshoes
                or {
                    Words = {
                        formasi = 1,

                        tapalkuda = 2,
                        horseshoe = 2,
                        horseshoes = 2,

                        tapal = 0,
                        kuda = 0,
                        lingkaran = 0,
                        terbuka = 0,
                    },

                    Phrases = {
                        ["tapal kuda"] = 2,
                        ["lingkaran terbuka"] = 2,
                    },
                }

            -- "unhorseshoes" menghentikan semua mode, sama seperti
            -- unfrontline / unbackline.
            if NLP.Intents.stop
                and NLP.Intents.stop.Words then

                NLP.Intents.stop.Words.unhorseshoes =
                    NLP.Intents.stop.Words.unhorseshoes
                    or 3

                NLP.Intents.stop.Words.unhorseshoe =
                    NLP.Intents.stop.Words.unhorseshoe
                    or 3

            end

        end

        ----------------------------------------------------------------
        -- FORMATION DISTANCE
        ----------------------------------------------------------------

        -- Jarak satu satuan slot (studs), dipakai untuk baris dan kolom.
        local adminHorseshoeDistance = 6
        local defaultBotHorseshoeDistance = 6

        -- Toleransi kedatangan.
        local arrivalTolerance = 1.5

        ----------------------------------------------------------------
        -- FORMASI
        --
        --          B1  B2
        --   B3  B8  A  B7  B4
        --   B5                B6
        --
        -- right   : - ke kiri Target, + ke kanan Target
        -- forward : + ke depan Target, - ke belakang Target
        --
        -- Satuan slot dikali jarak. B1 dan B2 berada di depan target,
        -- masing-masing setengah satuan dari tengah, sehingga jarak
        -- antar keduanya satu satuan penuh.
        ----------------------------------------------------------------

        local slotOrder = {

            { right = -0.5, forward =  1 }, -- Slot 1 (B1) depan kiri
            { right =  0.5, forward =  1 }, -- Slot 2 (B2) depan kanan

            { right = -2,   forward =  0 }, -- Slot 3 (B3) kiri luar
            { right =  2,   forward =  0 }, -- Slot 4 (B4) kanan luar

            { right = -2,   forward = -1 }, -- Slot 5 (B5) ujung kiri
            { right =  2,   forward = -1 }, -- Slot 6 (B6) ujung kanan

            { right =  1,   forward =  0 }, -- Slot 7 (B7) kanan target
            { right = -1,   forward =  0 }, -- Slot 8 (B8) kiri target

            { right = -2,   forward = -2 }, -- Slot 9 (B9) ujung kiri belakang
            { right =  2,   forward = -2 }, -- Slot 10 (B10) ujung kanan belakang

            { right =  0,   forward =  2 }, -- Slot 11 (B11) depan tengah

        }

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
        -- STOP HORSESHOES
        ----------------------------------------------------------------

        local function stopHorseshoes()

            horseshoeing = false
            targetPlayer = nil

            if horseshoeConnection then
                horseshoeConnection:Disconnect()
                horseshoeConnection = nil
            end

            if humanoid then
                humanoid.AutoRotate = true
            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.horseshoes =
            stopHorseshoes

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "horseshoes"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

            end

        end

        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayerByName(name)

            if not name or name == "" then
                return nil
            end

            name = name:lower()

            -- Exact username atau display name.
            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            -- Username prefix.
            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower():sub(
                    1,
                    #name
                ) == name then

                    return player

                end

            end

            -- Display name prefix.
            for _, player in ipairs(Players:GetPlayers()) do

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
        -- MENGAMBIL DAFTAR BOT AKTIF
        --
        -- Hanya bot yang benar-benar berada di server, sesuai urutan
        -- botOrder.
        ----------------------------------------------------------------

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

        ----------------------------------------------------------------
        -- START HORSESHOES
        ----------------------------------------------------------------

        local function startHorseshoes(player)

            if not player then
                return
            end

            if not player:IsDescendantOf(Players) then

                warn(
                    "[Horseshoes] Target tidak tersedia."
                )

                return

            end

            ------------------------------------------------------------
            -- VALIDASI BOT
            ------------------------------------------------------------

            local activeBots = getActiveBots()

            local activeIndex = table.find(
                activeBots,
                tostring(LocalPlayer.UserId)
            )

            if not activeIndex then

                warn(
                    "[Horseshoes] Bot tidak aktif atau tidak terdaftar:",
                    LocalPlayer.UserId
                )

                stopHorseshoes()

                return

            end

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "horseshoes"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if horseshoeConnection then
                horseshoeConnection:Disconnect()
                horseshoeConnection = nil
            end

            ------------------------------------------------------------
            -- SET STATE
            ------------------------------------------------------------

            horseshoeing = true
            targetPlayer = player

            _G.BotVars.CommandTarget = player

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
            -- HORSESHOES LOOP
            ------------------------------------------------------------

            horseshoeConnection =
                RunService.Heartbeat:Connect(function()

                    ----------------------------------------------------
                    -- JIKA MODE SUDAH BERGANTI
                    ----------------------------------------------------

                    if _G.BotVars.ActiveMode ~= "horseshoes" then
                        stopHorseshoes()
                        return
                    end

                    ----------------------------------------------------
                    -- VALIDASI
                    ----------------------------------------------------

                    if not horseshoeing then
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

                    ----------------------------------------------------
                    -- TARGET CHARACTER
                    ----------------------------------------------------

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

                    ----------------------------------------------------
                    -- PERBARUI DAFTAR BOT AKTIF
                    --
                    -- Dihitung ulang agar formasi menyesuaikan saat
                    -- bot masuk atau keluar server.
                    ----------------------------------------------------

                    activeBots = getActiveBots()

                    activeIndex = table.find(
                        activeBots,
                        tostring(LocalPlayer.UserId)
                    )

                    if not activeIndex then
                        return
                    end

                    local slot = slotOrder[activeIndex]

                    -- Bot di luar jumlah slot tidak mendapat posisi.
                    if not slot then
                        return
                    end

                    ----------------------------------------------------
                    -- DISTANCE
                    ----------------------------------------------------

                    local distance =
                        defaultBotHorseshoeDistance

                    if Admin:IsAdmin(targetPlayer) then

                        distance =
                            adminHorseshoeDistance

                    end

                    local specialDistance =
                        Distance:GetDistance(
                            tostring(LocalPlayer.UserId),
                            tostring(targetPlayer.UserId)
                        )

                    if specialDistance then
                        distance = specialDistance
                    end

                    ----------------------------------------------------
                    -- POSISI HORSESHOES
                    ----------------------------------------------------

                    local targetPosition =
                        targetHRP.Position
                        + (
                            targetHRP.CFrame.RightVector
                            * (slot.right * distance)
                        )
                        + (
                            targetHRP.CFrame.LookVector
                            * (slot.forward * distance)
                        )

                    -- Samakan ketinggian dengan target.
                    targetPosition = Vector3.new(
                        targetPosition.X,
                        targetHRP.Position.Y,
                        targetPosition.Z
                    )

                    ----------------------------------------------------
                    -- JARAK KE POSISI TUJUAN
                    ----------------------------------------------------

                    local distanceToTarget =
                        (
                            myHRP.Position
                            - targetPosition
                        ).Magnitude

                    ----------------------------------------------------
                    -- JALAN KE POSISI
                    ----------------------------------------------------

                    if distanceToTarget > arrivalTolerance then

                        humanoid.AutoRotate = true

                        humanoid:MoveTo(
                            targetPosition
                        )

                        return

                    end

                    ----------------------------------------------------
                    -- SUDAH SAMPAI
                    -- MENGHADAP ARAH YANG SAMA DENGAN TARGET
                    ----------------------------------------------------

                    humanoid.AutoRotate = false

                    local targetRotation =
                        targetHRP.CFrame
                        - targetHRP.Position

                    myHRP.CFrame =
                        CFrame.new(myHRP.Position)
                        * targetRotation

                end)

        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(message, sender)

            if not message or not sender then
                return
            end

            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            local isAdmin = false

            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            local isCommandTarget =
                (_G.BotVars.CommandTarget == sender)

            ------------------------------------------------------------
            -- ANALISA PESAN (BAHASA NATURAL)
            ------------------------------------------------------------

            local intent, args

            if NLP then
                intent, args = NLP.Classify(message, NLP.Intents)
            end

            if not intent then
                return
            end

            ------------------------------------------------------------
            -- HORSESHOES (tanpa nama)
            -- ADMIN ATAU COMMAND TARGET
            ------------------------------------------------------------

            if intent == "horseshoes" and #args == 0 then

                if not isAdmin and not isCommandTarget then
                    return
                end

                startHorseshoes(sender)

                return
            end

            ------------------------------------------------------------
            -- HORSESHOES <nama pemain>
            -- HANYA ADMIN
            ------------------------------------------------------------

            local targetName = nil

            if intent == "horseshoes" and #args > 0 then
                targetName = NLP.ResolveTarget(args, findPlayerByName)
            end

            if targetName then

                if not isAdmin then
                    return
                end

                local target =
                    findPlayerByName(targetName)

                if target then
                    startHorseshoes(target)
                end

                return
            end

            ------------------------------------------------------------
            -- STOP (berhenti / stop / bubar / unhorseshoes)
            -- HANYA ADMIN
            ------------------------------------------------------------

            if intent == "stop" then

                if not isAdmin then
                    return
                end

                _G.BotVars.ActiveMode = nil
                _G.BotVars.CommandTarget = nil

                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction) == "function" then
                        pcall(stopFunction)
                    end

                end

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
                            and Players:GetPlayerByUserId(userId)

                        if sender then
                            handleCommand(message.Text, sender)
                        end

                    end
                )

            end

        end

        ----------------------------------------------------------------
        -- FALLBACK CHAT
        ----------------------------------------------------------------

        for _, player in ipairs(Players:GetPlayers()) do

            player.Chatted:Connect(function(message)

                if not textChatConnected then
                    handleCommand(message, player)
                end

            end)

        end

        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(function(player)

            player.Chatted:Connect(function(message)

                if not textChatConnected then
                    handleCommand(message, player)
                end

            end)

        end)

        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(function()

            task.wait(1)

            updateCharacter()

            if _G.BotVars.ActiveMode == "horseshoes"
                and targetPlayer then

                startHorseshoes(targetPlayer)

            end

        end)

        ----------------------------------------------------------------
        -- DONE
        ----------------------------------------------------------------

        print(
            "[Horseshoes] Loaded successfully."
        )

    end
}
