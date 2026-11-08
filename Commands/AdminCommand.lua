-- AdminCommand.lua
-- Menambahkan admin melalui command chat.
--
-- Command (tanpa prefix, cukup kata biasa):
-- tambah admin <username> / add admin <username>
-- hapus admin <username> / remove admin <username>
--
-- Admin baru hanya mendapatkan akses command:
-- follow
-- follow <player>
-- stop
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
        -- NATURAL LANGUAGE (TANPA PREFIX)
        --------------------------------------------------
        -- Parser berasal dari Perfix.lua (_G.BotVars.NLP).
        -- Perfix.lua belum memiliki intent addadmin/removeadmin,
        -- jadi modul ini mendaftarkan intent-nya sendiri ke
        -- NLP.Intents.
        --
        -- Tambah admin (HANYA Admin utama):
        --   tambah admin trevkaro / add admin trevkaro
        --
        -- Hapus admin (HANYA Admin utama):
        --   hapus admin trevkaro / remove admin trevkaro
        --------------------------------------------------

        local NLP = _G.BotVars.NLP

        if not NLP then

            warn(
                "[AdminCommand] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            NLP.Intents.addadmin =
                NLP.Intents.addadmin
                or {
                    Threshold = 3,

                    Words = {
                        addadmin = 3,
                        tambahadmin = 3,
                        tambahkanadmin = 3,

                        add = 1,
                        tambah = 1,
                        tambahkan = 1,
                    },

                    Phrases = {
                        ["add admin"] = 2,
                        ["tambah admin"] = 2,
                        ["tambahkan admin"] = 2,
                    },
                }

            NLP.Intents.removeadmin =
                NLP.Intents.removeadmin
                or {
                    Threshold = 3,

                    Words = {
                        removeadmin = 3,
                        hapusadmin = 3,
                        unadmin = 3,

                        remove = 1,
                        hapus = 1,
                        copot = 1,
                        cabut = 1,
                    },

                    Phrases = {
                        ["remove admin"] = 2,
                        ["hapus admin"] = 2,
                        ["copot admin"] = 2,
                        ["cabut admin"] = 2,
                    },
                }

        end

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

            local intent, args

            if NLP then
                intent, args = NLP.Classify(message, NLP.Intents)
            end

            if intent ~= "addadmin"
                and intent ~= "removeadmin" then

                return
            end

            --------------------------------------------------
            -- NAMA PEMAIN
            --------------------------------------------------
            -- Kata "admin" pada "tambah admin <nama>" ikut
            -- terbaca sebagai sisa kata, jadi kemunculan
            -- pertamanya dibuang. Pemain yang bernama "admin"
            -- ditulis: tambah admin admin.
            --------------------------------------------------

            local nameArgs = {}
            local skippedAdminWord = false

            for _, word in ipairs(args) do
                if not skippedAdminWord
                    and word:lower() == "admin" then

                    skippedAdminWord = true
                else
                    table.insert(nameArgs, word)
                end
            end

            local targetName = nil

            if #nameArgs > 0 then
                targetName =
                    NLP.ResolveTarget(nameArgs, findPlayer)
                    or table.concat(nameArgs, " ")
            end

            --------------------------------------------------
            -- ADDADMIN
            --------------------------------------------------

            if intent == "addadmin" and targetName then

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
            -- REMOVEADMIN
            --------------------------------------------------

            if intent == "removeadmin" and targetName then

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
