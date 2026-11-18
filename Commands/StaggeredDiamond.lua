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
        local staggeredConnection = nil

        ----------------------------------------------------------------
        -- FORMASI
        --
        -- Staggered diamond (zig-zag) di sekitar Target (A):
        --
        --   B7         B8
        --      B5  B6
        --   B3    A    B4
        --      B1  B2
        --
        -- (atas = depan Target)
        --
        -- right   : - ke kiri Target, + ke kanan Target
        -- forward : + ke depan Target, - ke belakang Target
        --
        -- Satuan slot dikali jarak (spacing).
        --
        -- Bot aktif ke-1 menempati slot 1, bot aktif ke-2 slot 2,
        -- dan seterusnya.
        ----------------------------------------------------------------

        local slotOrder = {

            { right = -1, forward = -1 }, -- Slot 1 (B1) belakang kiri
            { right =  1, forward = -1 }, -- Slot 2 (B2) belakang kanan

            { right = -2, forward =  0 }, -- Slot 3 (B3) kiri
            { right =  2, forward =  0 }, -- Slot 4 (B4) kanan

            { right = -1, forward =  1 }, -- Slot 5 (B5) depan kiri
            { right =  1, forward =  1 }, -- Slot 6 (B6) depan kanan

            { right = -2, forward =  2 }, -- Slot 7 (B7) depan kiri luar
            { right =  2, forward =  2 }, -- Slot 8 (B8) depan kanan luar

        }

        ----------------------------------------------------------------
        -- NATURAL LANGUAGE (TANPA PREFIX)
        --
        -- Parser dan kamus perintah berasal dari Perfix.lua
        -- (_G.BotVars.NLP). Perfix.lua belum memiliki intent
        -- staggereddiamond, jadi modul ini mendaftarkan intent-nya
        -- sendiri.
        --
        -- Formasi di sekitar pengirim (Admin atau CommandTarget):
        --   staggereddiamond / staggered diamond / formasi staggered
        --   formasi delapan / formasi bertingkat
        --
        -- Formasi di sekitar pemain lain (HANYA Admin):
        --   staggered diamond trevkaro
        --
        -- Berhenti (HANYA Admin):
        --   berhenti / stop / bubar / unstaggereddiamond
        ----------------------------------------------------------------

        local NLP = _G.BotVars.NLP

        if not NLP then

            warn(
                "[StaggeredDiamond] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            -- "diamond" bernilai 1 di sini (bernilai 2 di intent
            -- diamond), supaya "staggered diamond" dimenangkan
            -- intent ini, sedangkan "diamond" saja tetap milik
            -- intent diamond.
            NLP.Intents.staggereddiamond =
                NLP.Intents.staggereddiamond
                or {
                    Words = {
                        formasi = 1,
                        bentuk = 1,

                        staggereddiamond = 2,
                        staggered = 2,
                        diamond = 1,

                        -- "formasi delapan" / "formasi bertingkat"
                        delapan = 1,
                        bertingkat = 1,
                    },
                }

            -- Perintah un... menghentikan semua mode, sama seperti
            -- unfrontline / unbackline.
            if NLP.Intents.stop
                and NLP.Intents.stop.Words then

                NLP.Intents.stop.Words.unstaggereddiamond =
                    NLP.Intents.stop.Words.unstaggereddiamond
                    or 3

                NLP.Intents.stop.Words.unstaggered =
                    NLP.Intents.stop.Words.unstaggered
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
        -- STOP STAGGERED DIAMOND
        ----------------------------------------------------------------

        local function stopStaggeredDiamond()

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

            if staggeredConnection then

                staggeredConnection:Disconnect()
                staggeredConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.staggereddiamond =
            stopStaggeredDiamond

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "staggereddiamond"
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
        -- START STAGGERED DIAMOND
        ----------------------------------------------------------------

        local function startStaggeredDiamond(player)

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

                stopStaggeredDiamond()

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
                "staggereddiamond"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if staggeredConnection then

                staggeredConnection:Disconnect()
                staggeredConnection = nil

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
            -- STAGGERED DIAMOND LOOP
            ------------------------------------------------------------

            staggeredConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- JIKA MODE SUDAH BERGANTI
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "staggereddiamond" then

                            stopStaggeredDiamond()

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
            -- STOP (berhenti / stop / bubar / unstaggereddiamond)
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
            -- STAGGERED DIAMOND
            --
            -- ADA 2 JENIS:
            --
            -- 1. staggered diamond (tanpa nama)
            --    Admin ATAU CommandTarget boleh.
            --
            -- 2. staggered diamond <nama pemain>
            --    HANYA Admin.
            ----------------------------------------------------------------

            if intent == "staggereddiamond" and #args == 0 then

                ------------------------------------------------------------
                -- ADMIN ATAU COMMAND TARGET
                ------------------------------------------------------------

                if not isAdmin
                    and not isCommandTarget then

                    return

                end

                ------------------------------------------------------------
                -- FORMASI DI SEKITAR SENDER
                ------------------------------------------------------------

                _G.BotVars.CommandTarget =
                    sender

                startStaggeredDiamond(
                    sender
                )

                return

            end

            ----------------------------------------------------------------
            -- STAGGERED DIAMOND PLAYER
            --
            -- HANYA ADMIN YANG BOLEH MEMILIH TARGET BARU.
            ----------------------------------------------------------------

            local targetName = nil

            if intent == "staggereddiamond" and #args > 0 then

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
                -- START STAGGERED DIAMOND
                ------------------------------------------------------------

                startStaggeredDiamond(
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
                    == "staggereddiamond"
                    and targetPlayer then

                    startStaggeredDiamond(
                        targetPlayer
                    )

                end

            end
        )

    end
}
