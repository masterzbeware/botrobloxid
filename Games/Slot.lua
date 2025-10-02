local lastSlot = 0
local pendingBattle = {} -- key = target.UserId

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        if vars.ToggleGames ~= true then
            return
        end

        local now = os.time()
        if now - lastSlot < 2 then
            return
        end
        lastSlot = now

        -- 🔡 Ambil argumen
        local args = {}
        for word in msg:gmatch("%S+") do
            table.insert(args, word)
        end

        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if not channel then
            warn("Channel RBXGeneral tidak ditemukan!")
            return
        end

        -- 🎰 Fungsi roll slot
        local function rollSlot()
            local symbols = { "🍒", "🍋", "🍉", "⭐", "💎" }
            return { symbols[math.random(#symbols)], symbols[math.random(#symbols)], symbols[math.random(#symbols)] }
        end

        local function slotResult(playerName)
            local roll = rollSlot()
            local text = table.concat(roll, " | ")
            local win = (roll[1] == roll[2] and roll[2] == roll[3])
            local hasil = win and "JACKPOT 🎉" or "Coba lagi..."
            return string.format("%s: | %s | → %s", playerName, text, hasil), win
        end

        -- 🟢 Mode 1: Battle (!slot [nama])
        if #args >= 2 then
            local targetName = args[2]
            local Players = game:GetService("Players")
            local targetPlayer = Players:FindFirstChild(targetName)

            if not targetPlayer then
                channel:SendAsync("Pemain " .. targetName .. " tidak ditemukan!")
                return
            end

            -- Cek apakah client atau target sudah dalam battle lain
            for _, battle in pairs(pendingBattle) do
                if battle.challenger == client or battle.target == client or battle.challenger == targetPlayer or battle.target == targetPlayer then
                    channel:SendAsync("❌ Salah satu pemain sudah ada di slot battle lain!")
                    return
                end
            end

            -- Simpan battle dengan timeout 5 detik
            pendingBattle[targetPlayer.UserId] = {
                challenger = client,
                target = targetPlayer,
                expire = os.time() + 5
            }

            channel:SendAsync(client.Name .. " menantang " .. targetPlayer.Name .. " ke SLOT BATTLE! 🎰")
            channel:SendAsync(targetPlayer.Name .. ", ketik !joinslot dalam 5 detik untuk ikut!")

            return
        end

        -- 🟢 Mode 2: Konfirmasi (!joinslot)
        if args[1] == "!joinslot" then
            local battle = pendingBattle[client.UserId]
            if not battle then
                channel:SendAsync("⚠️ Tidak ada slot battle yang menunggu untukmu!")
                return
            end

            if os.time() > battle.expire then
                channel:SendAsync("⏰ Waktu konfirmasi habis! Battle dibatalkan.")
                pendingBattle[client.UserId] = nil
                return
            end

            -- Jalankan slot untuk kedua player
            channel:SendAsync("🎰 SLOT BATTLE DIMULAI: " .. battle.challenger.Name .. " VS " .. battle.target.Name)

            local result1, win1 = slotResult(battle.challenger.Name)
            local result2, win2 = slotResult(battle.target.Name)

            channel:SendAsync(result1)
            channel:SendAsync(result2)

            local winner
            if win1 and not win2 then
                winner = battle.challenger.Name
            elseif win2 and not win1 then
                winner = battle.target.Name
            elseif win1 and win2 then
                winner = "Keduanya! Seri JACKPOT! 🎉"
            else
                winner = "Tidak ada pemenang, seri!"
            end

            channel:SendAsync("🏆 Pemenang: " .. winner)

            pendingBattle[client.UserId] = nil
            return
        end

        -- 🟢 Mode 3: Solo (!slot)
        if #args == 1 and args[1] == "!slot" then
            local result = slotResult(client.Name)
            channel:SendAsync(result)
        end
    end
}
