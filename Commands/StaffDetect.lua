```lua
return {
    Execute = function()
        --------------------------------------------------
        -- StaffDetect.lua
        -- Deteksi staff secara otomatis.
        -- Menghentikan otomatisasi saat staff terdeteksi.
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

            -- Test
            [11802903376] = true,
        }

        --------------------------------------------------
        -- STATUS DETEKSI
        --------------------------------------------------

        vars.StaffDetected = false
        vars.DetectedStaffUserId = nil
        vars.DetectedStaffName = nil

        -- Mencegah proses penghentian berjalan berulang.
        local detectionProcessed = {}

        --------------------------------------------------
        -- HENTIKAN OTOMATISASI
        --------------------------------------------------

        local function stopAutomation()
            local controllers = vars.ModeControllers

            if type(controllers) ~= "table" then
                warn(
                    "[StaffDetect] ModeControllers tidak ditemukan."
                )
                return
            end

            for modeName, stopFunction in pairs(controllers) do
                if type(stopFunction) == "function" then
                    local success, err = pcall(stopFunction)

                    if success then
                        print(
                            "[StaffDetect] Mode dihentikan: "
                            .. tostring(modeName)
                        )
                    else
                        warn(
                            "[StaffDetect] Gagal menghentikan mode "
                            .. tostring(modeName)
                            .. ": "
                            .. tostring(err)
                        )
                    end
                end
            end

            -- Reset status mode aktif jika variabel tersedia.
            vars.ActiveMode = nil
        end

        --------------------------------------------------
        -- PERIKSA PEMAIN
        --------------------------------------------------

        local function checkPlayer(player)
            if not player then
                return
            end

            local userId = player.UserId

            if not StaffUsers[userId] then
                return
            end

            -- Jangan proses staff yang sama berulang kali.
            if detectionProcessed[userId] then
                return
            end

            detectionProcessed[userId] = true

            vars.StaffDetected = true
            vars.DetectedStaffUserId = userId
            vars.DetectedStaffName = player.Name

            warn(
                "[StaffDetect] STAFF TERDETEKSI: "
                .. player.Name
                .. " ("
                .. tostring(userId)
                .. ")"
            )

            --------------------------------------------------
            -- HENTIKAN MODE OTOMATISASI
            --------------------------------------------------

            stopAutomation()

            print(
                "[StaffDetect] Deteksi selesai. "
                .. "Otomatisasi telah dihentikan."
            )
        end

        --------------------------------------------------
        -- PERIKSA PEMAIN YANG SUDAH ADA
        --------------------------------------------------

        for _, player in ipairs(Players:GetPlayers()) do
            checkPlayer(player)

            if vars.StaffDetected then
                break
            end
        end

        --------------------------------------------------
        -- DETEKSI PEMAIN BARU
        --------------------------------------------------

        Players.PlayerAdded:Connect(function(player)
            checkPlayer(player)
        end)

        --------------------------------------------------
        -- STATUS
        --------------------------------------------------

        print("[StaffDetect] Deteksi staff otomatis aktif.")
    end
}