-- LogChat.lua
-- Command: !logchat {displayname/username}
-- Fungsi: Menyimpan dan menampilkan riwayat chat pemain

return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")
      local Players = game:GetService("Players")
      local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

      -- Pastikan tempat penyimpanan log tersedia
      _G.ChatLogs = _G.ChatLogs or {}

      -- Inisialisasi listener global (hanya sekali)
      if not _G.ChatLogListenerSet then
          _G.ChatLogListenerSet = true
          print("[LogChat] Chat listener aktif.")

          -- Listener untuk TextChatService (sistem chat baru)
          if TextChatService and TextChatService.TextChannels then
              local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
              if generalChannel then
                  generalChannel.OnIncomingMessage = function(message)
                      local senderUserId = message.TextSource and message.TextSource.UserId
                      local sender = senderUserId and Players:GetPlayerByUserId(senderUserId)
                      if sender then
                          local logs = _G.ChatLogs[sender.UserId] or {}
                          table.insert(logs, {
                              text = message.Text,
                              time = os.date("%H:%M:%S")
                          })
                          _G.ChatLogs[sender.UserId] = logs
                      end
                  end
              end
          end

          -- Listener untuk sistem chat lama (Chatted event)
          for _, player in ipairs(Players:GetPlayers()) do
              player.Chatted:Connect(function(text)
                  local logs = _G.ChatLogs[player.UserId] or {}
                  table.insert(logs, {
                      text = text,
                      time = os.date("%H:%M:%S")
                  })
                  _G.ChatLogs[player.UserId] = logs
              end)
          end

          Players.PlayerAdded:Connect(function(player)
              player.Chatted:Connect(function(text)
                  local logs = _G.ChatLogs[player.UserId] or {}
                  table.insert(logs, {
                      text = text,
                      time = os.date("%H:%M:%S")
                  })
                  _G.ChatLogs[player.UserId] = logs
              end)
          end)
      end

      -- Parsing argumen command
      local args = string.split(msg, " ")
      local targetName = args[2]

      if not targetName then
          if channel then
              channel:SendAsync("Format perintah salah. Gunakan: !logchat {displayname/username}")
          end
          return
      end

      -- Cari player berdasarkan username atau displayname
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

      -- Ambil log chat pemain
      local logs = _G.ChatLogs[targetPlayer.UserId]

      if not logs or #logs == 0 then
          channel:SendAsync("Tidak ditemukan riwayat chat untuk " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ").")
          return
      end

      -- Tentukan jumlah pesan yang ingin dikirim (default 10)
      local maxMessages = 10
      local total = #logs
      local startIndex = math.max(total - maxMessages + 1, 1)

      -- Buat daftar ringkasan pesan
      local summary = {}
      table.insert(summary, "Riwayat chat untuk " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. "):")

      for i = startIndex, total do
          local entry = logs[i]
          table.insert(summary, "[" .. entry.time .. "] " .. entry.text)
      end

      channel:SendAsync(table.concat(summary, "\n"))
  end
}
