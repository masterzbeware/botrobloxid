-- JoinServer.lua (Fixed)
-- Command: !joinserver <displayname/username>
-- Bot akan teleport ke server yang sama dengan pemain target

return {
    Execute = function(msg, client)
        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        local vars = _G.BotVars or {}
        local player = vars.LocalPlayer

        if not player then
            warn("[JoinServer] LocalPlayer tidak ditemukan!")
            return
        end

        -- Ambil nama target dari command
        local targetName = msg:match("^!joinserver%s+(.+)")
        if not targetName then
            warn("[JoinServer] Format salah. Gunakan: !joinserver <nama>")
            return
        end

        print("[JoinServer] Mencoba teleport ke server target: " .. targetName)

        -- Cek apakah target adalah client (VIP) yang sudah ada di daftar bot
        local targetPlayer
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == targetName:lower() or p.DisplayName:lower() == targetName:lower() then
                targetPlayer = p
                break
            end
        end

        -- Jika target tidak ditemukan di server saat ini
        if not targetPlayer then
            -- Gunakan Global Table jika tersedia (bot mapping antar server)
            local knownJobIds = vars.KnownJobIds or {}
            local knownPlaceId = vars.KnownPlaceId or game.PlaceId
            local targetJobId = knownJobIds[targetName:lower()]

            if targetJobId then
                print("[JoinServer] Ditemukan JobId target di cache: " .. targetJobId)
                TeleportService:TeleportToPlaceInstance(knownPlaceId, targetJobId, player)
                return
            else
                warn("[JoinServer] Tidak dapat menemukan pemain atau JobId target.")
                return
            end
        end

        -- Jika target ada di server yang sama
        if game.JobId == targetPlayer.JobId then
            print("[JoinServer] Sudah berada di server yang sama dengan " .. targetPlayer.Name)
            return
        end

        -- Teleport langsung ke server target
        print("[JoinServer] Teleport ke server target " .. targetPlayer.Name .. " ...")
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, targetPlayer.JobId, player)
        end)

        if not success then
            warn("[JoinServer] Gagal teleport: " .. tostring(err))
        end
    end
}
