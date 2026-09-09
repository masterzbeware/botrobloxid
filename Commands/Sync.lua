-- Commands/Sync.lua
-- Admin-only sync system
-- Supports:
-- !sync
-- !sync <username|displayname>
-- !stop
-- !unsync
--
-- Improved:
-- - Safe sync state
-- - Recovery after InvokeServer error
-- - Target leaving detection
-- - Prevent stuck syncing state
-- - Safer OnIncomingMessage handling
-- - Can sync again after stopping/failing

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
            warn("[SYNC] LocalPlayer tidak ditemukan.")
            return
        end


        ----------------------------------------------------------------
        -- LOAD ADMIN MODULE
        ----------------------------------------------------------------

        local Admin

        local adminSuccess, adminResult = pcall(function()
            return loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            ))()
        end)

        if not adminSuccess then
            warn("[SYNC] Gagal load Admin.lua:", adminResult)
            return
        end

        Admin = adminResult


        ----------------------------------------------------------------
        -- REMOTES
        ----------------------------------------------------------------

        local connections = ReplicatedStorage:WaitForChild("Connections")
        local dataProviders = connections:WaitForChild("dataProviders")

        local commandHandler = dataProviders:WaitForChild("commandHandler")
        local animationHandler = dataProviders:WaitForChild("animationHandler")


        ----------------------------------------------------------------
        -- SYNC STATE
        ----------------------------------------------------------------

        local syncing = false
        local currentTarget = nil

        -- Digunakan untuk membedakan sesi sync lama dan baru
        local syncSession = 0


        ----------------------------------------------------------------
        -- DEBUG
        ----------------------------------------------------------------

        local function debugPrint(...)
            print("[SYNC]", ...)
        end


        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayerByName(name)

            if not name then
                return nil
            end

            name = name:lower()

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name then
                    return player
                end

                if player.DisplayName:lower() == name then
                    return player
                end

            end

            return nil
        end


        ----------------------------------------------------------------
        -- CLEAR LOCAL STATE
        ----------------------------------------------------------------

        local function clearState()

            syncing = false
            currentTarget = nil

            syncSession += 1

        end


        ----------------------------------------------------------------
        -- STOP SYNC
        ----------------------------------------------------------------

        local function stopSync()

            if not syncing and not currentTarget then
                debugPrint("Tidak ada sync aktif.")
                return
            end

            local oldTarget = currentTarget

            debugPrint(
                "Menghentikan sync:",
                oldTarget and oldTarget.Name or "Unknown"
            )

            -- Reset state SEBELUM remote
            -- supaya command !sync berikutnya tetap bisa digunakan
            clearState()

            local success, result = pcall(function()
                return animationHandler:InvokeServer("leaveSync")
            end)

            if not success then

                warn(
                    "[SYNC] leaveSync gagal:",
                    result
                )

            else

                debugPrint("leaveSync berhasil.")

            end

        end


        ----------------------------------------------------------------
        -- START SYNC
        ----------------------------------------------------------------

        local function startSync(targetPlayer)

            if not targetPlayer then
                warn("[SYNC] Target tidak ditemukan.")
                return
            end


            ------------------------------------------------------------
            -- TARGET HARUS MASIH ADA
            ------------------------------------------------------------

            if not targetPlayer.Parent then
                warn(
                    "[SYNC] Target sudah tidak berada di game:",
                    targetPlayer.Name
                )

                clearState()
                return
            end


            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            if not Admin:IsAdmin(LocalPlayer) then
                return
            end


            ------------------------------------------------------------
            -- JIKA SUDAH SYNC KE TARGET YANG SAMA
            ------------------------------------------------------------

            if syncing and currentTarget == targetPlayer then

                debugPrint(
                    "Sudah sync ke:",
                    targetPlayer.Name
                )

                return

            end


            ------------------------------------------------------------
            -- JIKA MASIH SYNC KE TARGET LAIN
            ------------------------------------------------------------

            if syncing then

                debugPrint(
                    "Sync sebelumnya masih aktif. Menghentikan terlebih dahulu."
                )

                local success, result = pcall(function()
                    return animationHandler:InvokeServer("leaveSync")
                end)

                if not success then
                    warn(
                        "[SYNC] Gagal menghentikan sync lama:",
                        result
                    )
                end

                syncing = false
                currentTarget = nil

            end


            ------------------------------------------------------------
            -- SESSION BARU
            ------------------------------------------------------------

            syncSession += 1

            local thisSession = syncSession


            ------------------------------------------------------------
            -- INVOKE SERVER
            ------------------------------------------------------------

            debugPrint(
                "Mencoba sync ke:",
                targetPlayer.Name,
                "(" .. targetPlayer.UserId .. ")"
            )


            local success, result = pcall(function()

                return commandHandler:InvokeServer(
                    "sync",
                    targetPlayer.UserId
                )

            end)


            ------------------------------------------------------------
            -- INVOKE GAGAL
            ------------------------------------------------------------

            if not success then

                warn(
                    "[SYNC] commandHandler InvokeServer gagal:",
                    result
                )

                -- Jangan biarkan state terkunci
                if syncSession == thisSession then
                    syncing = false
                    currentTarget = nil
                end

                return

            end


            ------------------------------------------------------------
            -- SESSION SUDAH BERUBAH
            ------------------------------------------------------------

            if syncSession ~= thisSession then

                debugPrint(
                    "Session sync berubah. Membatalkan hasil sync lama."
                )

                return

            end


            ------------------------------------------------------------
            -- SUCCESS
            ------------------------------------------------------------

            syncing = true
            currentTarget = targetPlayer

            debugPrint(
                "SYNC AKTIF ->",
                targetPlayer.Name
            )

        end


        ----------------------------------------------------------------
        -- TARGET PLAYER REMOVING
        ----------------------------------------------------------------

        Players.PlayerRemoving:Connect(function(player)

            if player == currentTarget then

                debugPrint(
                    "Target keluar dari game:",
                    player.Name
                )

                -- Reset state lokal
                clearState()

                -- Beritahu server
                task.spawn(function()

                    local success, result = pcall(function()
                        return animationHandler:InvokeServer("leaveSync")
                    end)

                    if not success then

                        warn(
                            "[SYNC] Gagal leaveSync setelah target keluar:",
                            result
                        )

                    end

                end)

            end

        end)


        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(msg, sender)

            if not msg or not sender then
                return
            end


            ------------------------------------------------------------
            -- ADMIN ONLY
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end


            ------------------------------------------------------------
            -- NORMALIZE
            ------------------------------------------------------------

            local lower = msg:lower():match("^%s*(.-)%s*$")


            ------------------------------------------------------------
            -- !SYNC
            ------------------------------------------------------------

            if lower == "!sync" then

                debugPrint(
                    "!sync diterima dari:",
                    sender.Name
                )

                startSync(sender)

                return

            end


            ------------------------------------------------------------
            -- !SYNC <NAME>
            ------------------------------------------------------------

            local targetName = lower:match("^!sync%s+(.+)$")

            if targetName then

                debugPrint(
                    "!sync target:",
                    targetName
                )

                local target = findPlayerByName(targetName)

                if not target then

                    warn(
                        "[SYNC] Player tidak ditemukan:",
                        targetName
                    )

                    return

                end

                startSync(target)

                return

            end


            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop" then

                debugPrint("!stop diterima.")

                stopSync()

                return

            end


            ------------------------------------------------------------
            -- !UNSYNC
            ------------------------------------------------------------

            if lower == "!unsync" then

                debugPrint("!unsync diterima.")

                stopSync()

                return

            end

        end


        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE
        ----------------------------------------------------------------

        local connectedTextChannel = nil

        if TextChatService and TextChatService.TextChannels then

            local ch = TextChatService.TextChannels:FindFirstChild(
                "RBXGeneral"
            )

            if ch then

                connectedTextChannel = ch


                --------------------------------------------------------
                -- SIMPAN HANDLER LAMA
                --------------------------------------------------------

                local oldOnIncomingMessage = ch.OnIncomingMessage


                --------------------------------------------------------
                -- INSTALL HANDLER SYNC
                --------------------------------------------------------

                ch.OnIncomingMessage = function(message)

                    ----------------------------------------------------
                    -- PROCESS SYNC COMMAND
                    ----------------------------------------------------

                    local success, err = pcall(function()

                        local uid =
                            message.TextSource
                            and message.TextSource.UserId

                        if not uid then
                            return
                        end


                        local sender =
                            Players:GetPlayerByUserId(uid)

                        if not sender then
                            return
                        end


                        handleCommand(
                            message.Text,
                            sender
                        )

                    end)


                    if not success then

                        warn(
                            "[SYNC] Chat handler error:",
                            err
                        )

                    end


                    ----------------------------------------------------
                    -- PANGGIL HANDLER LAMA
                    ----------------------------------------------------

                    if oldOnIncomingMessage then

                        local oldSuccess, oldResult =
                            pcall(
                                oldOnIncomingMessage,
                                message
                            )

                        if not oldSuccess then

                            warn(
                                "[SYNC] Previous chat handler error:",
                                oldResult
                            )

                        end

                    end

                end


                debugPrint(
                    "RBXGeneral chat handler aktif."
                )

            else

                warn(
                    "[SYNC] RBXGeneral tidak ditemukan."
                )

            end

        end


        ----------------------------------------------------------------
        -- FALLBACK CHAT
        ----------------------------------------------------------------

        local chattedConnections = {}


        local function connectPlayerChat(player)

            if not player then
                return
            end


            if chattedConnections[player] then
                return
            end


            local connection = player.Chatted:Connect(function(msg)

                local success, err = pcall(function()

                    handleCommand(
                        msg,
                        player
                    )

                end)


                if not success then

                    warn(
                        "[SYNC] Chatted handler error:",
                        err
                    )

                end

            end)


            chattedConnections[player] = connection

        end


        ---------------------------------------------------------------
        -- EXISTING PLAYERS
        ---------------------------------------------------------------

        for _, player in ipairs(Players:GetPlayers()) do

            connectPlayerChat(player)

        end


        ---------------------------------------------------------------
        -- NEW PLAYERS
        ---------------------------------------------------------------

        Players.PlayerAdded:Connect(function(player)

            connectPlayerChat(player)

        end)


        ----------------------------------------------------------------
        -- CLEANUP CHAT CONNECTION
        ----------------------------------------------------------------

        Players.PlayerRemoving:Connect(function(player)

            local connection = chattedConnections[player]

            if connection then

                connection:Disconnect()
                chattedConnections[player] = nil

            end

        end)


        ----------------------------------------------------------------
        -- FINAL
        ----------------------------------------------------------------

        debugPrint(
            "Loaded successfully."
        )

        debugPrint(
            "Commands: !sync | !sync <name> | !stop | !unsync"
        )

    end
}