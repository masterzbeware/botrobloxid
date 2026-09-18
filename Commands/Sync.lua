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
            warn("[Sync] LocalPlayer tidak ditemukan.")
            return
        end


        ----------------------------------------------------------------
        -- GLOBAL
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}


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
                warn("[Sync] Gagal load Admin.lua.")
                return
            end
        end


        ----------------------------------------------------------------
        -- REQUEST SYNC REMOTE
        ----------------------------------------------------------------

        local RequestSync

        do
            local Events = ReplicatedStorage:FindFirstChild("Events")

            if Events then
                RequestSync = Events:FindFirstChild("RequestSync")
            end

            if not RequestSync then
                warn("[Sync] ReplicatedStorage.Events.RequestSync tidak ditemukan.")
                return
            end
        end


        ----------------------------------------------------------------
        -- FIND PLAYER
        -- Mendukung:
        -- 1. Username exact
        -- 2. DisplayName exact
        -- 3. Username prefix
        -- 4. DisplayName prefix
        ----------------------------------------------------------------

        local function findPlayerByName(name)

            if not name or name == "" then
                return nil
            end

            name = name:gsub("^%s+", ""):gsub("%s+$", "")

            if name == "" then
                return nil
            end

            local lowerName = name:lower()


            ------------------------------------------------------------
            -- EXACT USERNAME / DISPLAY NAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == lowerName
                    or player.DisplayName:lower() == lowerName then

                    return player

                end

            end


            ------------------------------------------------------------
            -- PREFIX USERNAME / DISPLAY NAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower():sub(
                    1,
                    #lowerName
                ) == lowerName then

                    return player

                end

                if player.DisplayName:lower():sub(
                    1,
                    #lowerName
                ) == lowerName then

                    return player

                end

            end


            return nil

        end


        ----------------------------------------------------------------
        -- REQUEST SYNC
        ----------------------------------------------------------------

        local function requestSync(targetPlayer)

            if not targetPlayer then
                warn("[Sync] Target tidak ditemukan.")
                return
            end

            local success, err = pcall(function()

                RequestSync:FireServer(targetPlayer)

            end)

            if success then

                print(
                    "[Sync] RequestSync berhasil | Bot:",
                    LocalPlayer.Name,
                    "| Target:",
                    targetPlayer.Name,
                    "(" .. targetPlayer.DisplayName .. ")"
                )

            else

                warn(
                    "[Sync] RequestSync gagal | Bot:",
                    LocalPlayer.Name,
                    "| Target:",
                    targetPlayer.Name,
                    "| Error:",
                    err
                )

            end

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

            if not isAdmin then
                return
            end


            ------------------------------------------------------------
            -- CLEAN MESSAGE
            ------------------------------------------------------------

            local lower =
                message:lower()
                    :gsub("^%s+", "")
                    :gsub("%s+$", "")


            ------------------------------------------------------------
            -- !SYNC
            --
            -- !sync
            -- = sync ke pengirim command
            ------------------------------------------------------------

            if lower == "!sync" then

                print(
                    "[Sync] Command !sync | Bot:",
                    LocalPlayer.Name,
                    "| Target:",
                    sender.Name
                )

                requestSync(sender)

                return

            end


            ------------------------------------------------------------
            -- !SYNC PLAYER
            --
            -- !sync username
            -- !sync displayname
            ------------------------------------------------------------

            local targetName =
                lower:match("^!sync%s+(.+)$")

            if targetName then

                local target =
                    findPlayerByName(targetName)

                if not target then

                    warn(
                        "[Sync] Player tidak ditemukan:",
                        targetName
                    )

                    return

                end


                print(
                    "[Sync] Command !sync target | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name,
                    "| Target:",
                    target.Name
                )

                requestSync(target)

                return

            end

        end


        ----------------------------------------------------------------
        -- TEXT CHAT
        ----------------------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

            if channel then

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

        local function connectPlayer(player)

            player.Chatted:Connect(
                function(message)

                    handleCommand(
                        message,
                        player
                    )

                end
            )

        end


        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            connectPlayer(player)

        end


        Players.PlayerAdded:Connect(
            connectPlayer
        )


        print(
            "[Sync] Loaded successfully | Bot:",
            LocalPlayer.Name
        )

    end
}
