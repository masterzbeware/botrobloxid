-- Commands/JoinAlert.lua
-- MasterZ HUB
-- Auto Leave when a listed UserId joins

return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
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

            -- Tambahkan UserId lainnya di sini
            -- [123456789] = true,
        }

        --------------------------------------------------
        -- SETTINGS
        --------------------------------------------------

        -- Jeda sebelum keluar dari permainan.
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
        -- DETECT WATCHED USER
        --------------------------------------------------

        local function checkPlayer(player)

            if triggered or not player then
                return
            end

            -- Abaikan LocalPlayer sendiri.
            if player == LocalPlayer then
                return
            end

            -- Periksa UserId.
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
            -- WAIT, THEN LEAVE
            --------------------------------------------------

            task.wait(LeaveDelay)

            print(
                "[JoinAlert] Keluar dari permainan karena:",
                player.Name,
                player.UserId
            )

            LocalPlayer:Kick(
                "Watched user joined the server."
            )
        end

        --------------------------------------------------
        -- CHECK PLAYERS ALREADY IN SERVER
        --------------------------------------------------

        for _, player in ipairs(Players:GetPlayers()) do

            if triggered then
                break
            end

            checkPlayer(player)

        end

        --------------------------------------------------
        -- DETECT NEW PLAYERS
        --------------------------------------------------

        Players.PlayerAdded:Connect(function(player)
            checkPlayer(player)
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