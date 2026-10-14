
return {
    Execute = function()
        --------------------------------------------------
        -- StaffDetect.lua
        -- Deteksi staff secara otomatis tanpa command.
        --------------------------------------------------

        local vars = _G.BotVars

        if not vars or not vars.Players then
            warn("[StaffDetect] BotVars atau Players tidak ditemukan!")
            return
        end

        local Players = vars.Players

        --------------------------------------------------
        -- DAFTAR STAFF USER ID
        --------------------------------------------------

        local StaffUsers = {
            [10477890967] = true,
            [10977024755] = true,
            [11071417917] = true,
            [11070276511] = true,
            [10925201612] = true,
            [9064034988] = true,
            [9386785659] = true,
            [957153090] = true,
            [9092542128] = true,
        }

        --------------------------------------------------
        -- STATUS DETEKSI
        --------------------------------------------------

        vars.StaffDetected = false
        vars.DetectedStaffUserId = nil

        local function checkPlayer(player)
            if not player then
                return
            end

            if not StaffUsers[player.UserId] then
                return
            end

            -- Jangan memproses staff yang sama berulang kali.
            if vars.StaffDetected
                and vars.DetectedStaffUserId == player.UserId then
                return
            end

            vars.StaffDetected = true
            vars.DetectedStaffUserId = player.UserId

            warn(
                "[StaffDetect] Staff terdeteksi: "
                .. player.Name
                .. " ("
                .. tostring(player.UserId)
                .. ")"
            )

            -- Tempat untuk menghentikan otomatisasi bot
            -- melalui mekanisme kontrol bot yang tersedia.
        end

        --------------------------------------------------
        -- PERIKSA PEMAIN YANG SUDAH ADA
        --------------------------------------------------

        for _, player in ipairs(Players:GetPlayers()) do
            checkPlayer(player)
        end

        --------------------------------------------------
        -- DETEKSI PEMAIN BARU
        --------------------------------------------------

        Players.PlayerAdded:Connect(checkPlayer)

        print("[StaffDetect] Deteksi staff otomatis aktif.")
    end
}
