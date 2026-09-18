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

        local Events = ReplicatedStorage:WaitForChild("Events")
        local RequestSync = Events:WaitForChild("RequestSync")

        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayerByName(name)

            if not name or name == "" then
                return nil
            end

            name = name:lower()

            ------------------------------------------------------------
            -- EXACT USERNAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name then
                    return player
                end

            end

            ------------------------------------------------------------
            -- EXACT DISPLAY NAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.DisplayName:lower() == name then
                    return player
                end

            end

            ------------------------------------------------------------
            -- PARTIAL USERNAME / DISPLAY NAME
            ------------------------------------------------------------

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower():sub(
                    1,
                    #name
                ) == name then

                    return player

                end

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
        -- SEND CHAT
        ----------------------------------------------------------------

        local function sendChat(message)

            local success = false

            pcall(function()

                local channel =
                    TextChatService.TextChannels
                    and TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then
                    channel:SendAsync(message)
                    success = true
                end

            end)

            if not success then

                pcall(function()

                    local chatEvents =
                        ReplicatedStorage:FindFirstChild(
                            "DefaultChatSystemChatEvents"
                        )

                    if not chatEvents then
                        return
                    end

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

                end)

            end

        end

        ----------------------------------------------------------------
        -- REQUEST SYNC
        ----------------------------------------------------------------

        local function requestSync(target)

            if not target then
                return false
            end

            local success, err = pcall(function()
                RequestSync:FireServer(target)
            end)

            if success then
                print(
                    "[Sync] RequestSync berhasil:",
                    target.Name,
                    "(" .. target.DisplayName .. ")"
                )

                return true
            end

            warn(
                "[Sync] RequestSync gagal:",
                err
            )

            return false

        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(message, sender)

            if not sender then
                return
            end

            ------------------------------------------------------------
            -- HANYA ADMIN
            ------------------------------------------------------------

            local isAdmin = false

            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            if not isAdmin then
                return
            end

            local command =
                message:match("^%s*(.-)%s*$")

            local lowerCommand =
                command:lower()

            ------------------------------------------------------------
            -- !SYNC
            -- Sync ke pengirim command sendiri.
            ------------------------------------------------------------

            if lowerCommand == "!sync" then

                requestSync(sender)

                return

            end

            ------------------------------------------------------------
            -- !SYNC <USERNAME / DISPLAYNAME>
            ------------------------------------------------------------

            local targetName =
                command:match(
                    "^!sync%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(targetName)

                if not target then

                    sendChat(
                        "Player tidak ditemukan."
                    )

                    return

                end

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

        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            player.Chatted:Connect(
                function(message)

                    handleCommand(
                        message,
                        player
                    )

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

                        handleCommand(
                            message,
                            player
                        )

                    end
                )

            end
        )

        print("[Sync] Loaded successfully.")

    end
}
