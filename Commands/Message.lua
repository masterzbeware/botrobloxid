return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Message] LocalPlayer tidak ditemukan.")
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

        local Admin

        do

            local success, result = pcall(function()

                return loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
                ))()

            end)

            if success and result then

                Admin = result

            else

                warn(
                    "[Message] Gagal load Admin.lua."
                )

                return

            end

        end


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local connectedPlayers = {}


        ----------------------------------------------------------------
        -- CHECK EXCLUDED CHARACTER
        ----------------------------------------------------------------

        local function containsExcludedCharacter(message)

            if not message or message == "" then
                return true
            end


            ----------------------------------------------------------------
            -- CHARACTER YANG TIDAK BOLEH DIBALAS
            ----------------------------------------------------------------

            local excludedCharacters = {

                "!",
                "?",
                "/",
                "\\",
                ".",

            }


            for _, character in ipairs(
                excludedCharacters
            ) do

                if message:find(
                    character,
                    1,
                    true
                ) then

                    return true

                end

            end


            return false

        end


        ----------------------------------------------------------------
        -- SEND MESSAGE
        ----------------------------------------------------------------

        local function sendMessage(message)

            if not message
                or message == "" then

                return

            end


            local success, err =
                pcall(function()


                    ----------------------------------------------------
                    -- TEXT CHAT SYSTEM
                    ----------------------------------------------------

                    local textChannels =
                        TextChatService:FindFirstChild(
                            "TextChannels"
                        )


                    if not textChannels then

                        warn(
                            "[Message] TextChannels tidak ditemukan."
                        )

                        return

                    end


                    ----------------------------------------------------
                    -- GENERAL CHANNEL
                    ----------------------------------------------------

                    local generalChannel =
                        textChannels:FindFirstChild(
                            "RBXGeneral"
                        )


                    if not generalChannel then

                        warn(
                            "[Message] RBXGeneral tidak ditemukan."
                        )

                        return

                    end


                    ----------------------------------------------------
                    -- SEND
                    ----------------------------------------------------

                    generalChannel:SendAsync(
                        message
                    )

                end)


            if not success then

                warn(
                    "[Message] Gagal mengirim pesan:",
                    err
                )

            end

        end


        ----------------------------------------------------------------
        -- HANDLE MESSAGE
        ----------------------------------------------------------------

        local function handleMessage(
            message,
            sender
        )

            if not message
                or not sender then

                return

            end


            ----------------------------------------------------------------
            -- JANGAN BALAS CHAT BOT SENDIRI
            ----------------------------------------------------------------

            if sender == LocalPlayer then
                return
            end


            ----------------------------------------------------------------
            -- CHECK ADMIN
            ----------------------------------------------------------------

            local isAdmin = false

            pcall(function()

                isAdmin =
                    Admin:IsAdmin(sender)

            end)


            ----------------------------------------------------------------
            -- CHECK COMMAND TARGET
            ----------------------------------------------------------------

            local isCommandTarget =
                (
                    _G.BotVars.CommandTarget
                    == sender
                )


            ----------------------------------------------------------------
            -- CLEAN MESSAGE
            ----------------------------------------------------------------

            local cleanMessage =
                message
                :gsub("^%s+", "")
                :gsub("%s+$", "")


            if cleanMessage == "" then
                return
            end


            ----------------------------------------------------------------
            -- COMMAND
            ----------------------------------------------------------------

            local lower =
                cleanMessage:lower()


            ----------------------------------------------------------------
            -- !STOP
            --
            -- HANYA ADMIN
            --
            -- Karena Message.lua bukan controller mode,
            -- !stop cukup diabaikan di sini.
            -- Controller lain yang menangani !stop.
            ----------------------------------------------------------------

            if lower == "!stop" then

                return

            end


            ----------------------------------------------------------------
            -- !MESSAGE
            --
            -- ADMIN:
            --     !message
            --
            -- COMMAND TARGET:
            --     !message
            ----------------------------------------------------------------

            if lower == "!message" then

                if not isAdmin
                    and not isCommandTarget then

                    print(
                        "[Message] !message ditolak:",
                        sender.Name
                    )

                    return

                end


                print(
                    "[Message] Mode aktif | Sender:",
                    sender.Name,
                    "| Admin:",
                    isAdmin,
                    "| CommandTarget:",
                    isCommandTarget
                )


                return

            end


            ----------------------------------------------------------------
            -- !MESSAGE PLAYER
            --
            -- HANYA ADMIN
            --
            -- Command ini hanya digunakan untuk memilih
            -- CommandTarget baru.
            ----------------------------------------------------------------

            local targetName =
                cleanMessage:match(
                    "^!message%s+(.+)$"
                )


            if targetName then

                if not isAdmin then

                    print(
                        "[Message] !message PLAYER ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                ----------------------------------------------------------------
                -- FIND TARGET
                ----------------------------------------------------------------

                local target = nil

                local searchName =
                    targetName:lower()


                ------------------------------------------------------------
                -- EXACT USERNAME / DISPLAY NAME
                ------------------------------------------------------------

                for _, player in ipairs(
                    Players:GetPlayers()
                ) do

                    if player.Name:lower()
                        == searchName
                        or player.DisplayName:lower()
                        == searchName then

                        target = player
                        break

                    end

                end


                ------------------------------------------------------------
                -- PREFIX USERNAME
                ------------------------------------------------------------

                if not target then

                    for _, player in ipairs(
                        Players:GetPlayers()
                    ) do

                        if player.Name:lower():sub(
                            1,
                            #searchName
                        ) == searchName then

                            target = player
                            break

                        end

                    end

                end


                ------------------------------------------------------------
                -- TARGET TIDAK DITEMUKAN
                ------------------------------------------------------------

                if not target then

                    warn(
                        "[Message] Player tidak ditemukan:",
                        targetName
                    )

                    return

                end


                ----------------------------------------------------------------
                -- SET COMMAND TARGET
                ----------------------------------------------------------------

                _G.BotVars.CommandTarget =
                    target


                print(
                    "[Message] CommandTarget sekarang:",
                    target.Name,
                    "| Dipilih oleh Admin:",
                    sender.Name
                )


                return

            end


            ----------------------------------------------------------------
            -- HANYA ADMIN / COMMAND TARGET
            ----------------------------------------------------------------

            if not isAdmin
                and not isCommandTarget then

                return

            end


            ----------------------------------------------------------------
            -- IGNORE PESAN YANG MENGANDUNG
            -- ! ? / \ .
            ----------------------------------------------------------------

            if containsExcludedCharacter(
                cleanMessage
            ) then

                return

            end


            ----------------------------------------------------------------
            -- KIRIM PESAN YANG SAMA
            ----------------------------------------------------------------

            print(
                "[Message] Forward:",
                cleanMessage,
                "| Sender:",
                sender.Name
            )


            sendMessage(
                cleanMessage
            )

        end


        ----------------------------------------------------------------
        -- CONNECT PLAYER CHAT
        ----------------------------------------------------------------

        local function connectPlayerChat(
            player
        )

            if connectedPlayers[player] then
                return
            end


            connectedPlayers[player] = true


            player.Chatted:Connect(
                function(message)

                    handleMessage(
                        message,
                        player
                    )

                end
            )

        end


        ----------------------------------------------------------------
        -- EXISTING PLAYERS
        ----------------------------------------------------------------

        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            connectPlayerChat(
                player
            )

        end


        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                connectPlayerChat(
                    player
                )

            end
        )


        ----------------------------------------------------------------
        -- PLAYER REMOVING
        ----------------------------------------------------------------

        Players.PlayerRemoving:Connect(
            function(player)

                connectedPlayers[player] = nil

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Message] Loaded untuk:",
            LocalPlayer.Name
        )

    end
}