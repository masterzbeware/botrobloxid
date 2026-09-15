return {
Execute = function()
    ----------------------------------------------------------------
    -- SERVICES
    ----------------------------------------------------------------

    local Players = game:GetService("Players")

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
    -- CHECK COMMAND PREFIX
    ----------------------------------------------------------------

    local function isCommand(message)

        if not message or message == "" then
            return false
        end

        local firstCharacter =
            message:sub(1, 1)

        return firstCharacter == "!"
            or firstCharacter == "?"
            or firstCharacter == "/"
            or firstCharacter == "\\"
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

                if _G.BotVars
                    and _G.BotVars.TextChatService then

                    local TextChatService =
                        _G.BotVars.TextChatService

                    local textChannels =
                        TextChatService:FindFirstChild(
                            "TextChannels"
                        )

                    if textChannels then

                        local generalChannel =
                            textChannels:FindFirstChild(
                                "RBXGeneral"
                            )

                        if generalChannel then

                            generalChannel:SendAsync(
                                message
                            )

                            return
                        end

                    end

                end

                ----------------------------------------------------------------
                -- FALLBACK
                ----------------------------------------------------------------

                local TextChatService =
                    game:GetService(
                        "TextChatService"
                    )

                local textChannels =
                    TextChatService:FindFirstChild(
                        "TextChannels"
                    )

                if not textChannels then
                    return
                end

                local generalChannel =
                    textChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if generalChannel then

                    generalChannel:SendAsync(
                        message
                    )

                end

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
        -- JANGAN PROSES CHAT BOT SENDIRI
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
        -- IGNORE COMMAND
        ----------------------------------------------------------------

        if isCommand(message) then

            return
        end

        ----------------------------------------------------------------
        -- SEND EXACT SAME MESSAGE
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
