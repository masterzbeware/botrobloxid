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

        if not message or message == "" then
            return
        end

        local success, err =
            pcall(function()

                ----------------------------------------------------------------
                -- TEXT CHAT SYSTEM
                ----------------------------------------------------------------

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

                ----------------------------------------------------------------
                -- GENERAL CHANNEL
                ----------------------------------------------------------------

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

                ----------------------------------------------------------------
                -- SEND
                ----------------------------------------------------------------

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

        if not message then
            return
        end

        if not sender then
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

        if not isAdmin then
            return
        end

        ----------------------------------------------------------------
        -- IGNORE PESAN YANG MENGANDUNG
        -- ! ? / \ .
        ----------------------------------------------------------------

        if containsExcludedCharacter(
            message
        ) then

            return

        end

        ----------------------------------------------------------------
        -- KIRIM PESAN YANG SAMA
        ----------------------------------------------------------------

        sendMessage(message)

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
