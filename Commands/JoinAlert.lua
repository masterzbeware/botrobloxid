-- Commands/JoinAlert.lua
-- MasterZ HUB
-- Auto Message when a listed UserId joins

return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService =
            game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[JoinAlert] LocalPlayer tidak ditemukan.")
            return
        end

        --------------------------------------------------
        -- USERID WATCHLIST
        --------------------------------------------------

        local WatchedUsers = {
            [11802903376] = true, -- Contoh UserId
            -- [123456789] = true,
            -- Tambahkan UserId lainnya di sini
        }

        --------------------------------------------------
        -- MESSAGE
        --------------------------------------------------

        local JoinMessage = "We have to go, Sir!"

        --------------------------------------------------
        -- PREVENT DUPLICATE INITIALIZATION
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        if _G.BotVars.JoinAlertLoaded then
            warn("[JoinAlert] Module sudah aktif.")
            return
        end

        _G.BotVars.JoinAlertLoaded = true

        --------------------------------------------------
        -- SEND MESSAGE
        --------------------------------------------------

        local function sendJoinMessage(player)

            if not player then
                return
            end

            if player == LocalPlayer then
                return
            end

            if WatchedUsers[player.UserId] ~= true then
                return
            end

            print(
                "[JoinAlert] UserId terdeteksi:",
                player.Name,
                player.UserId
            )

            local success, err = pcall(function()

                local channels =
                    TextChatService:FindFirstChild(
                        "TextChannels"
                    )

                if not channels then
                    error("TextChannels tidak ditemukan.")
                end

                local general =
                    channels:FindFirstChild("RBXGeneral")

                if not general then
                    error("RBXGeneral tidak ditemukan.")
                end

                general:SendAsync(JoinMessage)

            end)

            if success then
                print(
                    "[JoinAlert] Pesan join dikirim untuk:",
                    player.Name
                )
            else
                warn(
                    "[JoinAlert] Gagal mengirim pesan:",
                    tostring(err)
                )
            end
        end

        --------------------------------------------------
        -- PLAYER ADDED
        --------------------------------------------------

        Players.PlayerAdded:Connect(function(player)
            sendJoinMessage(player)
        end)

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print(
            "[JoinAlert] Aktif untuk:",
            LocalPlayer.Name
        )

    end
}