-- Commands/JoinAlert.lua
-- MasterZ HUB
-- Auto Message + Auto Leave when a listed UserId joins

return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[JoinAlert] LocalPlayer tidak ditemukan.")
            return
        end

        --------------------------------------------------
        -- USERID WATCHLIST
        --------------------------------------------------

        local WatchedUsers = {
            [10477890967] = true,
            [10977024755] = true,
            [11071417917] = true,
            [11070276511] = true,
            [10925201612] = true,
            [9064034988] = true,
            [9386785659] = true,
            [957153090] = true,
            [9092542128] = true,
            [9410392958] = true,
            [11802903376] = true,

            -- Tambahkan UserId lainnya di sini
            -- [123456789] = true,
        }

        --------------------------------------------------
        -- SETTINGS
        --------------------------------------------------

        local JoinMessage = "We have to go, Sir!"

        -- Jeda setelah mengirim pesan sebelum keluar.
        local LeaveDelay = 1.5

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
        -- STATE
        --------------------------------------------------

        local triggered = false
        local processedUsers = {}

        --------------------------------------------------
        -- SEND MESSAGE AND LEAVE
        --------------------------------------------------

        local function sendJoinMessage(player)

            if triggered then
                return
            end

            if not player then
                return
            end

            -- Abaikan LocalPlayer sendiri.
            if player == LocalPlayer then
                return
            end

            -- Periksa apakah UserId masuk watchlist.
            if WatchedUsers[player.UserId] ~= true then
                return
            end

            -- Cegah pemrosesan ganda.
            if processedUsers[player.UserId] then
                return
            end

            processedUsers[player.UserId] = true
            triggered = true

            print(
                "[JoinAlert] UserId terdeteksi:",
                player.Name,
                player.UserId
            )

            --------------------------------------------------
            -- SEND CHAT MESSAGE
            --------------------------------------------------

            local success, err = pcall(function()

                local channels =
                    TextChatService:FindFirstChild("TextChannels")

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
                    "[JoinAlert] Pesan berhasil dikirim ke sistem chat."
                )

            else

                warn(
                    "[JoinAlert] Gagal mengirim pesan:",
                    tostring(err)
                )

            end

            --------------------------------------------------
            -- WAIT, THEN LEAVE
            --------------------------------------------------

            task.wait(LeaveDelay)

            print(
                "[JoinAlert] Keluar dari permainan karena:",
                player.Name,
                player.UserId
            )

            LocalPlayer:Kick(
                "We have to go, Sir!"
            )

        end

        --------------------------------------------------
        -- CHECK PLAYERS ALREADY IN SERVER
        --------------------------------------------------

        for _, player in ipairs(Players:GetPlayers()) do

            if triggered then
                break
            end

            sendJoinMessage(player)

        end

        --------------------------------------------------
        -- DETECT NEW PLAYERS
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