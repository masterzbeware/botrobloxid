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

        local following = false
        local targetPlayer = nil
        local diamondConnection = nil

        ----------------------------------------------------------------
        -- FORMASI
        --
        -- Belah ketupat (diamond) mengelilingi Target (A):
        --
        --          B1
        --      B8      B2
        --   B7     A      B3
        --      B6      B4
        --          B5
        --
        -- (atas = depan Target)
        --
        -- right   : - ke kiri Target, + ke kanan Target
        -- forward : + ke depan Target, - ke belakang Target
        --
        -- Satuan slot dikali jarak (spacing), sehingga bentuknya
        -- tetap belah ketupat berapa pun jaraknya.
        --
        -- Urutan slot searah jarum jam dimulai dari depan.
        -- Bot aktif ke-1 menempati slot 1, bot aktif ke-2 slot 2,
        -- dan seterusnya.
        ----------------------------------------------------------------

        local slotOrder = {

            { right =  0, forward =  2 }, -- Slot 1 (B1) depan
            { right =  1, forward =  1 }, -- Slot 2 (B2) depan kanan

            { right =  2, forward =  0 }, -- Slot 3 (B3) kanan
            { right =  1, forward = -1 }, -- Slot 4 (B4) belakang kanan

            { right =  0, forward = -2 }, -- Slot 5 (B5) belakang
            { right = -1, forward = -1 }, -- Slot 6 (B6) belakang kiri

            { right = -2, forward =  0 }, -- Slot 7 (B7) kiri
            { right = -1, forward =  1 }, -- Slot 8 (B8) depan kiri

        }

        ----------------------------------------------------------------
        -- NATURAL LANGUAGE (TANPA PREFIX)
        --
        -- Parser dan kamus perintah berasal dari Perfix.lua
        -- (_G.BotVars.NLP). Perfix.lua belum memiliki intent diamond,
        -- jadi modul ini mendaftarkan intent-nya sendiri.
        --
        -- Formasi mengelilingi pengirim (Admin atau CommandTarget):
        --   berlian / formasi berlian
        --
        -- Formasi mengelilingi pemain lain (HANYA Admin):
        --   berlian trevkaro / formasi berlian trevkaro
        --
        -- Berhenti (HANYA Admin):
        --   berhenti / stop / bubar / undiamond
        ----------------------------------------------------------------

        local NLP = _G.BotVars.NLP

        if not NLP then

            warn(
                "[Diamond] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            -- Kata umum formasi (lemah, bernilai 1) dipasangkan dengan
            -- kata penentu, sama seperti intent formasi lain.
            NLP.Intents.diamond =
                NLP.Intents.diamond
                or {
                    Words = {
                        formasi = 1,
                        bentuk = 1,

                        berlian = 2,
                    },
                }

            -- "undiamond" menghentikan semua mode, sama seperti
            -- unfrontline / unbackline.
            if NLP.Intents.stop
                and NLP.Intents.stop.Words then

                NLP.Intents.stop.Words.undiamond =
                    NLP.Intents.stop.Words.undiamond
                    or 3

            end

        end

        ----------------------------------------------------------------
        -- JARAK
        ----------------------------------------------------------------

        -- Jarak satu satuan slot (studs), dipakai untuk baris dan kolom.
        local adminSpacing = 3
        local defaultSpacing = 3

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

    "11965361702", -- Bot 7
    "11960770617", -- Bot 8
    "11954797420", -- Bot 9
    "12033761173", -- Bot 10
    "12033761173", -- Bot 11
    "7480415785", -- Bot 12

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

                    pcall(function()

                        channel:SendAsync(message)

                    end)

                    success = true

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
        -- STOP DIAMOND
        ----------------------------------------------------------------

        local function stopDiamond()

            following = false
            targetPlayer = nil

            ------------------------------------------------------------
            -- CommandTarget SENGAJA TIDAK DIHAPUS.
            --
            -- Target yang sudah ditentukan Admin tetap mempunyai
            -- hak untuk mengganti mode (follow, frontline, circle, dll).
            --
            -- CommandTarget baru dihapus oleh perintah stop Admin.
            ------------------------------------------------------------

            if diamondConnection then

                diamondConnection:Disconnect()
                diamondConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.diamond =
            stopDiamond

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "diamond"
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
        -- START DIAMOND
        ----------------------------------------------------------------

        local function startDiamond(player)

            if not player then
                return
            end

            ------------------------------------------------------------
            -- BOT HARUS TERDAFTAR DI botOrder
            ------------------------------------------------------------

            if not table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            ) then

                stopDiamond()

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
                "diamond"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if diamondConnection then

                diamondConnection:Disconnect()
                diamondConnection = nil

            end

            ------------------------------------------------------------
            -- SET STATE
            ------------------------------------------------------------

            following = true
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
            -- DIAMOND LOOP
            ------------------------------------------------------------

            diamondConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- JIKA MODE SUDAH BERGANTI
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "diamond" then

                            stopDiamond()

                            return

                        end

                        ------------------------------------------------
                        -- VALIDASI
                        ------------------------------------------------

                        if not following then
                            return
                        end

                        if not humanoid
                            or not myHRP
                            or not myHRP.Parent then

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

                        local activeBots = getActiveBots()

                        local activeIndex =
                            table.find(
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

                        ------------------------------------------------
                        -- JARAK
                        ------------------------------------------------

                        local spacing =
                            defaultSpacing

                        if Admin:IsAdmin(
                            targetPlayer
                        ) then

                            spacing =
                                adminSpacing

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

                            spacing =
                                specialDistance

                        end

                        ------------------------------------------------
                        -- POSISI BOT
                        ------------------------------------------------

                        local targetPosition =
                            targetHRP.Position
                            +
                            (
                                targetHRP.CFrame.RightVector
                                *
                                (slot.right * spacing)
                            )
                            +
                            (
                                targetHRP.CFrame.LookVector
                                *
                                (slot.forward * spacing)
                            )

                        -- Samakan ketinggian dengan target.
                        targetPosition = Vector3.new(
                            targetPosition.X,
                            targetHRP.Position.Y,
                            targetPosition.Z
                        )

                        ------------------------------------------------
                        -- JARAK KE POSISI
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- JALAN
                        ------------------------------------------------

                        if distanceToTarget > 1.5 then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ------------------------------------------------
                        -- SUDAH SAMPAI
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

            if not sender then
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
            -- STOP (berhenti / stop / bubar / undiamond)
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
            -- DIAMOND
            --
            -- ADA 2 JENIS:
            --
            -- 1. berlian / formasi berlian (tanpa nama)
            --    Admin ATAU CommandTarget boleh.
            --
            -- 2. berlian <nama pemain>
            --    HANYA Admin.
            ----------------------------------------------------------------

            if intent == "diamond" and #args == 0 then

                ------------------------------------------------------------
                -- ADMIN ATAU COMMAND TARGET
                ------------------------------------------------------------

                if not isAdmin
                    and not isCommandTarget then

                    return

                end

                ------------------------------------------------------------
                -- FORMASI MENGELILINGI SENDER
                ------------------------------------------------------------

                _G.BotVars.CommandTarget =
                    sender

                startDiamond(
                    sender
                )

                return

            end

            ----------------------------------------------------------------
            -- DIAMOND PLAYER
            --
            -- HANYA ADMIN YANG BOLEH MEMILIH TARGET BARU.
            ----------------------------------------------------------------

            local targetName = nil

            if intent == "diamond" and #args > 0 then

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
                -- START DIAMOND
                ------------------------------------------------------------

                startDiamond(
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
                    == "diamond"
                    and targetPlayer then

                    startDiamond(
                        targetPlayer
                    )

                end

            end
        )

    end
}
