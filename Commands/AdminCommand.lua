-- AdminCommand.lua
-- Menambahkan admin melalui command chat.
--
-- Command:
-- !addadmin <username>
-- !removeadmin <username>
--
-- Admin baru hanya mendapatkan akses command:
-- !follow
-- !follow <player>
-- !stop
--
-- Admin utama tetap ditentukan oleh Admin.lua.

return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")

        --------------------------------------------------
        -- GLOBAL
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        -- Shared runtime admin list.
        -- UserId = true
        _G.BotVars.AdditionalAdmins =
            _G.BotVars.AdditionalAdmins or {}

        --------------------------------------------------
        -- LOAD ADMIN
        --------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        --------------------------------------------------
        -- HELPER
        --------------------------------------------------

        local function isMainAdmin(player)

            if not player then
                return false
            end

            return Admin.AllowedUsers[player.UserId] == true
        end

        local function isAdmin(player)

            if not player then
                return false
            end

            if isMainAdmin(player) then
                return true
            end

            return _G.BotVars.AdditionalAdmins[player.UserId] == true
        end

        local function findPlayer(name)

            if not name or name == "" then
                return nil
            end

            local lowerName = name:lower()

            -- Exact username
            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == lowerName then
                    return player
                end

            end

            -- Username/display-name prefix
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

        local function sendChat(message)

            pcall(function()

                local channel =
                    TextChatService.TextChannels
                    and TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then
                    channel:SendAsync(message)
                end

            end)

        end

        --------------------------------------------------
        -- COMMAND HANDLER
        --------------------------------------------------

        local function handleCommand(message, sender)

            if not isMainAdmin(sender) then
                return
            end

            local command =
                message:match("^%s*(.-)%s*$")

            local targetName =
                command:match(
                    "^!addadmin%s+(.+)$"
                )

            --------------------------------------------------
            -- !ADDADMIN
            --------------------------------------------------

            if targetName then

                local target =
                    findPlayer(targetName)

                if not target then

                    sendChat(
                        "Player tidak ditemukan."
                    )

                    return

                end

                if isMainAdmin(target) then

                    sendChat(
                        target.Name
                        .. " sudah menjadi admin utama."
                    )

                    return

                end

                _G.BotVars.AdditionalAdmins[
                    target.UserId
                ] = true

                sendChat(
                    target.Name
                    .. " sekarang menjadi admin."
                )

                print(
                    "[AdminCommand] Added admin:",
                    target.Name,
                    target.UserId
                )

                return

            end

            --------------------------------------------------
            -- !REMOVEADMIN
            --------------------------------------------------

            local removeName =
                command:match(
                    "^!removeadmin%s+(.+)$"
                )

            if removeName then

                local target =
                    findPlayer(removeName)

                if not target then

                    sendChat(
                        "Player tidak ditemukan."
                    )

                    return

                end

                if isMainAdmin(target) then

                    sendChat(
                        "Admin utama tidak dapat dihapus."
                    )

                    return

                end

                _G.BotVars.AdditionalAdmins[
                    target.UserId
                ] = nil

                sendChat(
                    target.Name
                    .. " sudah bukan admin."
                )

                print(
                    "[AdminCommand] Removed admin:",
                    target.Name,
                    target.UserId
                )

                return

            end

        end

        --------------------------------------------------
        -- TEXT CHAT
        --------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

            if channel then

                channel.OnIncomingMessage =
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

            end

        end

        --------------------------------------------------
        -- FALLBACK CHAT
        --------------------------------------------------

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
            "[AdminCommand] Loaded successfully"
        )

    end
}
