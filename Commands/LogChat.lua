-- LogChat.lua
-- Command: !logchat {displayname/username} {angka}
-- Fungsi: Menampilkan riwayat chat pemain dengan format sederhana, bersih dari tag HTML
-- Default: 5 pesan terakhir jika angka tidak diberikan
-- Kompatibel dengan Stop.lua (listener dapat dimatikan dengan !stop)

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")
        local Players = game:GetService("Players")
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

        -- 🔹 Inisialisasi penyimpanan global
        _G.ChatLogs = _G.ChatLogs or {}

        -- 🔹 Listener hanya aktif sekali
        if not _G.ChatLogListenerSet then
            _G.ChatLogListenerSet = true
            print("[LogChat] Chat listener aktif.")

            -- 🔸 Listener TextChatService (baru)
            if TextChatService and TextChatService.TextChannels then
                local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if generalChannel then
                    generalChannel.OnIncomingMessage = function(message)
                        if not _G.ChatLogListenerSet then return end

                        local senderUserId = message.TextSource and message.TextSource.UserId
                        local sender = senderUserId and Players:GetPlayerByUserId(senderUserId)
                        if sender then
                            -- Bersihkan tag HTML dan karakter aneh
                            local cleanText = string.gsub(message.Text, "<[^<>]->", "")
                            cleanText = string.gsub(cleanText, "[^\32-\126]", "")

                            local logs = _G.ChatLogs[sender.UserId] or {}
                            -- 🔹 Cek duplikasi
                            if not (logs[#logs] and logs[#logs].text == cleanText) then
                                table.insert(logs, {
                                    text = cleanText,
                                    time = os.date("%H:%M:%S")
                                })
                                _G.ChatLogs[sender.UserId] = logs
                            end
                        end
                    end
                end
            end

            -- 🔸 Listener Player.Chatted (opsional, untuk pemain lama)
            local function connectPlayerChat(player)
                player.Chatted:Connect(function(text)
                    if not _G.ChatLogListenerSet then return end
                    local cleanText = string.gsub(text, "<[^<>]->", "")
                    cleanText = string.gsub(cleanText, "[^\32-\126]", "")

                    local logs = _G.ChatLogs[player.UserId] or {}
                    -- 🔹 Cek duplikasi
                    if not (logs[#logs] and logs[#logs].text == cleanText) then
                        table.insert(logs, {
                            text = cleanText,
                            time = os.date("%H:%M:%S")
                        })
                        _G.ChatLogs[player.UserId] = logs
                    end
                end)
            end

            for _, player in ipairs(Players:GetPlayers()) do
                connectPlayerChat(player)
            end

            Players.PlayerAdded:Connect(connectPlayerChat)
        end

        -- 🔹 Ambil argumen command (!logchat {nama} {angka})
        local args = string.split(msg, " ")
        local targetName = args[2]
        local jumlahPesan = tonumber(args[3]) or 5 -- default 5 jika tidak diisi

        if not targetName then
            if channel then
                channel:SendAsync("Format salah. Gunakan: !logchat {displayname/username} {jumlah_pesan(optional)}")
            end
            return
        end

        -- 🔹 Cari pemain berdasarkan displayname / username
        local targetPlayer = nil
        for _, player in ipairs(Players:GetPlayers()) do
            if string.lower(player.Name) == string.lower(targetName)
            or string.lower(player.DisplayName) == string.lower(targetName) then
                targetPlayer = player
                break
            end
        end

        if not channel then
            warn("[LogChat] Channel RBXGeneral tidak ditemukan.")
            return
        end

        if not targetPlayer then
            channel:SendAsync("Pemain '" .. targetName .. "' tidak ditemukan di server ini.")
            return
        end

        -- 🔹 Ambil log chat pemain
        local logs = _G.ChatLogs[targetPlayer.UserId]

        if not logs or #logs == 0 then
            channel:SendAsync("Tidak ditemukan riwayat chat untuk " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ").")
            return
        end

        -- 🔹 Batasi jumlah pesan dan kirim satu per satu
        local total = #logs
        local jumlah = math.clamp(jumlahPesan, 1, 50) -- batas maksimal 50
        local startIndex = math.max(total - jumlah + 1, 1)
        local delayPerMessage = 2 -- jeda antar pesan

        task.spawn(function()
            -- Header
            channel:SendAsync("History chat " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. "):")
            task.wait(delayPerMessage)

            -- Kirim satu per satu
            for i = startIndex, total do
                local entry = logs[i]
                local messageText = string.format("[%s] %s", entry.time, entry.text)
                channel:SendAsync(messageText)
                task.wait(delayPerMessage)
            end

            -- Log ke console
            print(string.format("[LogChat] Dikirim %d pesan terakhir dari %s (%s)", jumlah, targetPlayer.DisplayName, targetPlayer.Name))
        end)
    end
}
