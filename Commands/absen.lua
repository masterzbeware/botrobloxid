-- Absen.lua
-- ✅ Auto Absen command (!absen)

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local Players = vars.Players
        local TextChatService = vars.TextChatService
        local localPlayer = vars.LocalPlayer

        if not vars.ToggleAktif then
            print("[DEBUG] Bot system tidak aktif, absen dibatalkan")
            return
        end

        -- 🔹 Ambil daftar bot online
        local onlineBots = {}
        for userIdStr, botName in pairs(vars.BotMapping or {}) do
            local player = Players:GetPlayerByUserId(tonumber(userIdStr))
            if player and player.Character then
                table.insert(onlineBots, {Player = player, Name = botName})
                print("[DEBUG] Bot online terdeteksi: " .. botName)
            else
                print("[DEBUG] Bot offline atau karakter tidak ada: " .. botName)
            end
        end

        if #onlineBots == 0 then
            print("[DEBUG] Tidak ada bot online untuk absen")
            return
        end

        -- 🔹 Urutkan berdasarkan UserId (Bot1 → Bot4)
        table.sort(onlineBots, function(a, b)
            return tonumber(a.Player.UserId) < tonumber(b.Player.UserId)
        end)

        -- 🔹 Channel global
        local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral
        if not channel then
            print("[DEBUG] RBXGeneral channel tidak ditemukan")
            return
        end

        -- 🔹 Chat awal
        pcall(function()
            channel:SendAsync("Siap laksanakan! Mulai Berhitung")
            print("[DEBUG] Chat awal dikirim: Siap laksanakan! Mulai Berhitung")
        end)

        -- 🔹 Delay sebentar agar chat awal muncul
        task.wait(1)

        -- 🔹 Kirim chat sesuai urutan bot online
        for i, botInfo in ipairs(onlineBots) do
            local botPlayer = botInfo.Player
            local botName = botInfo.Name

            task.spawn(function()
                local delayTime = (i - 1) * 2
                task.wait(delayTime)
                if botPlayer and botPlayer.Character then
                    pcall(function()
                        channel:SendAsync(tostring(i))
                        print("[DEBUG] Bot " .. botName .. " mengirim chat: " .. i)
                    end)
                else
                    print("[DEBUG] Bot " .. botName .. " tidak online saat hitung")
                end
            end)
        end
    end
}
