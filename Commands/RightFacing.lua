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

        local facing = false
        local targetPlayer = nil
        local rightFacingConnection = nil
        local followFacingConnection = nil

        ----------------------------------------------------------------
        -- FORMASI HADAP KANAN
        --
        -- Satu kolom lurus di sebelah KIRI Target (T), semua bot
        -- menghadap ke KANAN (ke arah Target). Bot 4 sejajar dengan
        -- Target, Bot 1 paling depan, Bot 8 paling belakang:
        --
        --   B1
        --   B2
        --   B3
        --   B4 ────────────→ T
        --   B5
        --   B6
        --   B7
        --   B8
        --
        -- Bot aktif ke-1 menempati slot 1, bot aktif ke-2 slot 2,
        -- dan seterusnya.
        --
        -- row : jumlah baris ke DEPAN Target (+ depan, - belakang)
        ----------------------------------------------------------------

        local slotOrder = {

            { row =  3 }, -- Slot 1 (B1)
            { row =  2 }, -- Slot 2 (B2)
            { row =  1 }, -- Slot 3 (B3)
            { row =  0 }, -- Slot 4 (B4) sejajar dengan Target
            { row = -1 }, -- Slot 5 (B5)
            { row = -2 }, -- Slot 6 (B6)
            { row = -3 }, -- Slot 7 (B7)
            { row = -4 }, -- Slot 8 (B8)

        }

        ----------------------------------------------------------------
        -- NATURAL LANGUAGE (TANPA PREFIX)
        --
        -- Parser dan kamus perintah berasal dari Perfix.lua
        -- (_G.BotVars.NLP). Perfix.lua belum memiliki intent
        -- rightfacing, jadi modul ini mendaftarkan intent-nya sendiri.
        --
        -- Formasi hadap kanan di sebelah pengirim
        -- (Admin atau CommandTarget):
        --   hadap kanan / hadap kanan grak
        --
        -- Formasi hadap kanan di sebelah pemain lain (HANYA Admin):
        --   hadap kanan trevkaro
        --
        -- Berhenti (HANYA Admin):
        --   berhenti / stop / bubar / unrightfacing
        --
        -- Catatan: kata "grak" juga dipakai intent carrystop
        -- (siap grak / tegak grak), tetapi intent ini memiliki skor
        -- lebih tinggi sehingga "hadap kanan grak" dimenangkan di sini.
        ----------------------------------------------------------------

        local NLP = _G.BotVars.NLP

        if not NLP then

            warn(
                "[RightFacing] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            NLP.Intents.rightfacing =
                NLP.Intents.rightfacing
                or {
                    -- "hadap" + "kanan" = 4. Salah satu saja tidak
                    -- cukup memicu perintah.
                    Threshold = 4,
                    Priority = 1,

                    Words = {
                        hadap = 2,
                        kanan = 2,

                        -- Kata pendamping (bernilai 0): dikenali supaya
                        -- "hadap kanan grak" tidak membawa kata tak
                        -- dikenal, tetapi tidak memicu perintah sendirian.
                        grak = 0,
                    },
                }

            -- "unrightfacing" menghentikan semua mode, sama seperti
            -- untwoline / unfrontline.
            if NLP.Intents.stop
                and NLP.Intents.stop.Words then

                NLP.Intents.stop.Words.unrightfacing =
                    NLP.Intents.stop.Words.unrightfacing
                    or 3

            end

        end

        ----------------------------------------------------------------
        -- JARAK
        ----------------------------------------------------------------

        -- Jarak kolom bot ke samping Target (studs, ke arah kiri).
        local adminSideDistance = 6
        local defaultSideDistance = 6

        -- Jarak antar bot dalam kolom (studs).
        local rowSpacing = 3

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
        -- STOP RIGHT FACING
        ----------------------------------------------------------------

        local function stopFollowFacing()

            if followFacingConnection then

                followFacingConnection:Disconnect()
                followFacingConnection = nil

            end

        end

        local function stopRightFacing()

            stopFollowFacing()

            facing = false
            targetPlayer = nil

            ------------------------------------------------------------
            -- CommandTarget SENGAJA TIDAK DIHAPUS.
            --
            -- Target yang sudah ditentukan Admin tetap mempunyai
            -- hak untuk mengganti mode (follow, frontline, circle, dll).
            --
            -- CommandTarget baru dihapus oleh perintah stop Admin.
            ------------------------------------------------------------

            if rightFacingConnection then

                rightFacingConnection:Disconnect()
                rightFacingConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.rightfacing =
            stopRightFacing

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "rightfacing"
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
        -- START RIGHT FACING
        ----------------------------------------------------------------

        local function startRightFacing(player)

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

                stopRightFacing()

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
                "rightfacing"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if rightFacingConnection then

                rightFacingConnection:Disconnect()
                rightFacingConnection = nil

            end

            ------------------------------------------------------------
            -- SET STATE
            ------------------------------------------------------------

            facing = true
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
            -- RIGHT FACING LOOP
            ------------------------------------------------------------

            rightFacingConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- JIKA MODE SUDAH BERGANTI
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "rightfacing" then

                            stopRightFacing()

                            return

                        end

                        ------------------------------------------------
                        -- VALIDASI
                        ------------------------------------------------

                        if not facing then
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
                        -- JARAK KE SAMPING TARGET
                        ------------------------------------------------

                        local sideDistance =
                            defaultSideDistance

                        if Admin:IsAdmin(
                            targetPlayer
                        ) then

                            sideDistance =
                                adminSideDistance

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

                            sideDistance =
                                specialDistance

                        end

                        ------------------------------------------------
                        -- POSISI BOT
                        --
                        -- Di sebelah KIRI Target (-RightVector),
                        -- bergeser ke depan / belakang sesuai slot.
                        ------------------------------------------------

                        local targetPosition =
                            targetHRP.Position
                            -
                            (
                                targetHRP.CFrame.RightVector
                                *
                                sideDistance
                            )
                            +
                            (
                                targetHRP.CFrame.LookVector
                                *
                                (slot.row * rowSpacing)
                            )

                        -- Samakan ketinggian dengan target.
                        targetPosition = Vector3.new(
                            targetPosition.X,
                            targetHRP.Position.Y,
                            targetPosition.Z
                        )

                        ------------------------------------------------
                        -- JARAK
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
                        -- SUDAH SAMPAI: HADAP KANAN
                        --
                        -- Menghadap ke arah kanan Target (ke arah
                        -- Target dari kolom bot).
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        local rightVector =
                            targetHRP.CFrame.RightVector

                        local faceDirection =
                            Vector3.new(
                                rightVector.X,
                                0,
                                rightVector.Z
                            )

                        if faceDirection.Magnitude < 0.001 then
                            return
                        end

                        myHRP.CFrame =
                            CFrame.lookAt(
                                myHRP.Position,
                                myHRP.Position
                                + faceDirection.Unit
                            )

                    end
                )

        end

        ----------------------------------------------------------------
        -- START RIGHT FACING (SAAT MODE FOLLOW)
        --
        -- Jika bot sedang Follow, formasi TIDAK diubah. Bot tetap
        -- mengikuti Target seperti biasa dan hanya menghadap ke
        -- KANAN Target.
        --
        -- ActiveMode tetap "follow" supaya loop Follow tetap berjalan.
        -- Loop Follow menimpa rotasi bot di setiap Heartbeat, jadi
        -- rotasi di sini ditulis lewat task.defer agar dijalankan
        -- SETELAH semua handler Heartbeat selesai.
        --
        -- Berhenti otomatis jika mode berganti, atau saat perintah
        -- follow dikirim ulang (ikuti saya) yang mengembalikan facing
        -- ke arah Target.
        ----------------------------------------------------------------

        local function startFollowFacing()

            ------------------------------------------------------------
            -- BOT HARUS TERDAFTAR DI botOrder
            ------------------------------------------------------------

            if not table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            ) then

                return

            end

            ------------------------------------------------------------
            -- STOP LOOP FACING LAMA
            ------------------------------------------------------------

            stopFollowFacing()

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            local confirmNow = os.clock()

            if confirmNow - (_G.BotConfirmChatAt or -10) >= 1 then

                _G.BotConfirmChatAt = confirmNow

                sendChat(
                    "Siap!"
                )

            end

            ------------------------------------------------------------
            -- FACING LOOP
            ------------------------------------------------------------

            followFacingConnection =
                RunService.Heartbeat:Connect(
                    function()

                        if _G.BotVars.ActiveMode ~= "follow" then

                            stopFollowFacing()

                            return

                        end

                        task.defer(function()

                            if not followFacingConnection then
                                return
                            end

                            if _G.BotVars.ActiveMode ~= "follow" then
                                return
                            end

                            if not humanoid
                                or not myHRP
                                or not myHRP.Parent then

                                return

                            end

                            -- Target yang sedang di-follow.
                            local followTarget =
                                _G.BotVars.CommandTarget

                            local targetCharacter =
                                followTarget
                                and followTarget.Character

                            local targetHRP =
                                targetCharacter
                                and targetCharacter:FindFirstChild(
                                    "HumanoidRootPart"
                                )

                            if not targetHRP then
                                return
                            end

                            local rightVector =
                                targetHRP.CFrame.RightVector

                            local faceDirection =
                                Vector3.new(
                                    rightVector.X,
                                    0,
                                    rightVector.Z
                                )

                            if faceDirection.Magnitude < 0.001 then
                                return
                            end

                            -- Posisi tidak disentuh, hanya rotasi.
                            humanoid.AutoRotate = false

                            myHRP.CFrame =
                                CFrame.lookAt(
                                    myHRP.Position,
                                    myHRP.Position
                                    + faceDirection.Unit
                                )

                        end)

                    end
                )

        end

        ----------------------------------------------------------------
        -- HADAP KANAN SETELAH FOLLOW LALU BERHENTI
        --
        -- Urutan: Follow -> berhenti -> "hadap kanan grak".
        --
        -- Setelah berhenti, bot tetap di posisi Follow.lua. Perintah
        -- hadap kanan pada kondisi ini TIDAK membuat formasi baru:
        -- bot tidak berjalan, hanya memutar facing sekali ke arah
        -- KANAN pengirim.
        --
        -- Mode terakhir sebelum berhenti dicatat dari ActiveMode.
        -- Handler tiap modul tidak dijamin berurutan saat "berhenti",
        -- jadi ActiveMode dipantau di setiap Heartbeat. Setelah
        -- berhenti (ActiveMode nil), catatan ini masih menyimpan mode
        -- terakhir. Catatan berganti saat mode lain aktif.
        ----------------------------------------------------------------

        local lastActiveMode = nil

        RunService.Heartbeat:Connect(function()

            local currentMode = _G.BotVars.ActiveMode

            if currentMode then

                lastActiveMode = currentMode

            end

        end)

        local function faceRightOnce(player)

            ------------------------------------------------------------
            -- BOT HARUS TERDAFTAR DI botOrder
            ------------------------------------------------------------

            if not table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            ) then

                return

            end

            ------------------------------------------------------------
            -- VALIDASI
            ------------------------------------------------------------

            if not player then
                return
            end

            if not humanoid
                or not myHRP
                or not myHRP.Parent then

                return

            end

            local targetCharacter = player.Character

            local targetHRP =
                targetCharacter
                and targetCharacter:FindFirstChild(
                    "HumanoidRootPart"
                )

            if not targetHRP then
                return
            end

            local rightVector =
                targetHRP.CFrame.RightVector

            local faceDirection =
                Vector3.new(
                    rightVector.X,
                    0,
                    rightVector.Z
                )

            if faceDirection.Magnitude < 0.001 then
                return
            end

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            local confirmNow = os.clock()

            if confirmNow - (_G.BotConfirmChatAt or -10) >= 1 then

                _G.BotConfirmChatAt = confirmNow

                sendChat(
                    "Siap!"
                )

            end

            ------------------------------------------------------------
            -- UBAH FACING SAJA (posisi tidak disentuh)
            --
            -- AutoRotate dikembalikan ke true oleh stopRightFacing
            -- saat mode lain dimulai.
            ------------------------------------------------------------

            humanoid.AutoRotate = false

            myHRP.CFrame =
                CFrame.lookAt(
                    myHRP.Position,
                    myHRP.Position
                    + faceDirection.Unit
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
            -- STOP (berhenti / stop / bubar / unrightfacing)
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
            -- RIGHT FACING
            --
            -- ADA 2 JENIS:
            --
            -- 1. hadap kanan / hadap kanan grak (tanpa nama)
            --    Admin ATAU CommandTarget boleh.
            --
            -- 2. hadap kanan <nama pemain>
            --    HANYA Admin.
            ----------------------------------------------------------------

            if intent == "rightfacing" and #args == 0 then

                ------------------------------------------------------------
                -- ADMIN ATAU COMMAND TARGET
                ------------------------------------------------------------

                if not isAdmin
                    and not isCommandTarget then

                    return

                end

                ------------------------------------------------------------
                -- SEDANG FOLLOW: JANGAN UBAH FORMASI, CUKUP UBAH FACING
                ------------------------------------------------------------

                if _G.BotVars.ActiveMode == "follow" then

                    startFollowFacing()

                    return

                end

                ------------------------------------------------------------
                -- SETELAH FOLLOW LALU BERHENTI: bot tetap di posisinya,
                -- cukup ubah facing ke kanan (tanpa formasi baru).
                ------------------------------------------------------------

                if _G.BotVars.ActiveMode == nil
                    and lastActiveMode == "follow" then

                    faceRightOnce(sender)

                    return

                end

                ------------------------------------------------------------
                -- FORMASI DI SEBELAH SENDER
                ------------------------------------------------------------

                _G.BotVars.CommandTarget =
                    sender

                startRightFacing(
                    sender
                )

                return

            end

            ----------------------------------------------------------------
            -- RIGHT FACING PLAYER
            --
            -- HANYA ADMIN YANG BOLEH MEMILIH TARGET BARU.
            ----------------------------------------------------------------

            local targetName = nil

            if intent == "rightfacing" and #args > 0 then

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
                -- SEDANG FOLLOW: JANGAN UBAH FORMASI, CUKUP UBAH FACING
                ------------------------------------------------------------

                if _G.BotVars.ActiveMode == "follow" then

                    startFollowFacing()

                    return

                end

                ------------------------------------------------------------
                -- SET COMMAND TARGET
                ------------------------------------------------------------

                _G.BotVars.CommandTarget =
                    target

                ------------------------------------------------------------
                -- START RIGHT FACING
                ------------------------------------------------------------

                startRightFacing(
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
                    == "rightfacing"
                    and targetPlayer then

                    startRightFacing(
                        targetPlayer
                    )

                end

            end
        )

    end
}
