
return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            return
        end

        ----------------------------------------------------------------
        -- GLOBAL VARIABLES
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}

        local vars = _G.BotVars

        ----------------------------------------------------------------
        -- LOAD ADMIN MODULE
        ----------------------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- REMOTES
        ----------------------------------------------------------------

        local connections =
            ReplicatedStorage:WaitForChild("Connections")

        local dataProviders =
            connections:WaitForChild("dataProviders")

        local commandHandler =
            dataProviders:WaitForChild("commandHandler")

        local animationHandler =
            dataProviders:WaitForChild("animationHandler")

        ----------------------------------------------------------------
        -- STATE
        ----------------------------------------------------------------

        local syncing = false
        local currentTarget = nil

        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayerByName(name)

            if not name or name == "" then
                return nil
            end

            name = name:lower()

            ------------------------------------------------------------
            -- EXACT MATCH
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            ------------------------------------------------------------
            -- PARTIAL MATCH
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower():find(
                    name,
                    1,
                    true
                )
                    or player.DisplayName:lower():find(
                        name,
                        1,
                        true
                    ) then

                    return player

                end

            end

            return nil

        end

        ----------------------------------------------------------------
        -- STOP SYNC
        ----------------------------------------------------------------
        --
        -- Fungsi ini sengaja dibuat sebagai controller global
        -- agar Frontline / FrontlineLeft / FrontlineRight
        -- bisa menghentikan Sync sebelum mengambil alih.
        --
        ----------------------------------------------------------------

        local function stopSync()

            ------------------------------------------------------------
            -- Tidak sedang sync
            ------------------------------------------------------------

            if not syncing then

                currentTarget = nil

                return

            end

            ------------------------------------------------------------
            -- Simpan state sebelum dibersihkan
            ------------------------------------------------------------

            syncing = false
            currentTarget = nil

            ------------------------------------------------------------
            -- REAL STOP SYNC
            ------------------------------------------------------------

            pcall(function()

                animationHandler:InvokeServer(
                    "leaveSync"
                )

            end)

            print(
                "[SYNC] Sync stopped."
            )

        end

        ----------------------------------------------------------------
        -- REGISTER SYNC CONTROLLER
        ----------------------------------------------------------------
        --
        -- Ini bagian penting.
        --
        -- Frontline akan menjalankan:
        --
        -- vars.ModeControllers.sync()
        --
        -- ketika mode Frontline mulai.
        --
        ----------------------------------------------------------------

        vars.ModeControllers.sync =
            stopSync

        ----------------------------------------------------------------
        -- START SYNC
        ----------------------------------------------------------------

        local function startSync(targetPlayer)

            if not targetPlayer then
                return
            end

            ------------------------------------------------------------
            -- Jika sudah sync ke target yang sama
            ------------------------------------------------------------

            if syncing
                and currentTarget == targetPlayer then

                print(
                    "[SYNC] Already syncing:",
                    targetPlayer.Name
                )

                return

            end

            ------------------------------------------------------------
            -- Jika sedang sync ke target lain
            ------------------------------------------------------------

            if syncing
                and currentTarget ~= targetPlayer then

                stopSync()

                -- Beri sedikit waktu agar server menerima
                -- leaveSync sebelum sync baru.

                task.wait(0.05)

            end

            ------------------------------------------------------------
            -- SET STATE
            ------------------------------------------------------------

            syncing = true
            currentTarget = targetPlayer

            ------------------------------------------------------------
            -- ACTIVE MODE
            ------------------------------------------------------------

            vars.ActiveMode = "sync"

            ------------------------------------------------------------
            -- START SERVER SYNC
            ------------------------------------------------------------

            local success, result = pcall(function()

                return commandHandler:InvokeServer(
                    "sync",
                    targetPlayer.UserId
                )

            end)

            ------------------------------------------------------------
            -- HANDLE FAILURE
            ------------------------------------------------------------

            if not success then

                warn(
                    "[SYNC] Failed to start sync:",
                    result
                )

                syncing = false
                currentTarget = nil

                return

            end

            print(
                "[SYNC] Sync started:",
                targetPlayer.Name
            )

        end

        ----------------------------------------------------------------
        -- HANDLE COMMAND
        ----------------------------------------------------------------

        local function handleCommand(
            msg,
            sender
        )

            ------------------------------------------------------------
            -- ADMIN ONLY
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            if not msg then
                return
            end

            local lower =
                msg:lower()

            ------------------------------------------------------------
            -- !SYNC
            ------------------------------------------------------------

            if lower == "!sync" then

                startSync(sender)

                return

            end

            ------------------------------------------------------------
            -- !SYNC <PLAYER>
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!sync%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startSync(
                        target
                    )

                else

                    warn(
                        "[SYNC] Player tidak ditemukan:",
                        targetName
                    )

                end

                return

            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unsync" then

                --------------------------------------------------------
                -- Hanya reset ActiveMode jika memang Sync aktif
                --------------------------------------------------------

                if vars.ActiveMode == "sync" then
                    vars.ActiveMode = nil
                end

                stopSync()

                return

            end

        end

        ----------------------------------------------------------------
        -- TEXT CHAT
        ----------------------------------------------------------------
        --
        -- Gunakan MessageReceived.
        --
        -- Jangan menggunakan RBXGeneral.OnIncomingMessage di sini,
        -- karena module lain juga bisa menggunakannya dan saling
        -- menimpa callback.
        --
        ----------------------------------------------------------------

        TextChatService.MessageReceived:Connect(
            function(message)

                if not message then
                    return
                end

                if not message.TextSource then
                    return
                end

                local userId =
                    message.TextSource.UserId

                local sender =
                    Players:GetPlayerByUserId(
                        userId
                    )

                if not sender then
                    return
                end

                handleCommand(
                    message.Text,
                    sender
                )

            end
        )

        ----------------------------------------------------------------
        -- PLAYER CHAT FALLBACK
        ----------------------------------------------------------------
        --
        -- Dipertahankan untuk kompatibilitas.
        --
        ----------------------------------------------------------------

        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            player.Chatted:Connect(
                function(msg)

                    handleCommand(
                        msg,
                        player
                    )

                end
            )

        end

        ----------------------------------------------------------------
        -- NEW PLAYER FALLBACK
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                player.Chatted:Connect(
                    function(msg)

                        handleCommand(
                            msg,
                            player
                        )

                    end
                )

            end
        )

        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------
        --
        -- Jangan otomatis memanggil sync ulang di sini.
        --
        -- Server animationHandler seharusnya menangani keadaan
        -- sync sesuai sistemnya sendiri.
        --
        -- Kita hanya membersihkan referensi target apabila
        -- karakter melakukan reset dan mode sudah tidak valid.
        --
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                if not LocalPlayer.Character then
                    return
                end

                --------------------------------------------------------
                -- Jika mode sudah bukan Sync, pastikan state bersih.
                --------------------------------------------------------

                if vars.ActiveMode ~= "sync" then

                    syncing = false
                    currentTarget = nil

                end

            end
        )

        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[SYNC] Sync.lua aktif!"
        )

    end
}