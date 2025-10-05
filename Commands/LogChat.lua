-- LogChat.lua
-- Command: !logchat {displayname/username}
-- Fungsi: Menampilkan riwayat chat pemain dengan format sederhana, bersih dari tag HTML

return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")
      local Players = game:GetService("Players")
      local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

      -- Penyimpanan log chat global
      _G.ChatLogs = _G.ChatLogs or {}

      -- Listener chat global hanya sekali
      if not _G.ChatLogListenerSet then
          _G.ChatLogListenerSet = true
          print("[LogChat] Chat listener aktif.")

          -- Listener untuk sistem TextChatService
          if TextChatService and TextChatService.TextChannels then
              local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
              if generalChannel then
                  generalChannel.OnIncomingMessage = function(message)
                      local senderUserId = message.TextSource and message.TextSource.UserId
                      local sender = senderUserId and Players:GetPlayerByUserId(senderUserId)
                      if sender then
                          -- Bersihkan tag HTML (<font>, <b>, dll)
                          local cleanText = string.gsub(message.Text, "<.->", "")

                          local logs = _G.ChatLogs[sender.UserId] or {}
                          table.insert(logs, {
                              text = cleanText,
                              time = os.date("%H:%M:%S")
                          })
                          _G.ChatLogs[sender.UserId] = logs
                      end
                  end
              end
          end

          -- Listener untuk sistem chat lama (Player.Chatted)
          for _, player in ipairs(Players:GetPlayers()) do
              player.Chatted:Connect(function(text)
                  local cleanText = string.gsub(text, "<.->", "")
                  local logs = _G.ChatLogs[player.UserId] or {}
                  table.insert(logs, {
                      text = cleanText,
                      time = os.date("%H:%M:%S")
                  })
                  _G.ChatLogs[player.UserId] = logs
              end)
          end

          Players.PlayerAdded:Connect(function(player)
              player.Chatted:Connect(function(text)
                  local cleanText = string.gsub(text, "<.->", "")
                  local logs = _G.ChatLogs[player.UserId] or {}
                  table.insert(logs, {
                      text = cleanText,
                      time = os.date("%H:%M:%S")
                  })
                  _G.ChatLogs[player.UserId] = logs
              end)
          end)
      end

      -- Ambil argumen command (!logchat {nama})
      local args = string.split(msg, " ")
      local targetName = args[2]

      if not targetName then
          if channel then
              channel:SendAsync("Format salah. Gunakan: !logchat {displayname/username}")
          end
          return
      end

      -- Cari pemain berdasarkan displayname / username
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

      -- Ambil log chat
      local logs = _G.ChatLogs[targetPlayer.UserId]

      if not logs or #logs == 0 then
          channel:SendAsync("Tidak ditemukan riwayat chat untuk " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ").")
          return
      end

      -- Kirim header + isi log satu per satu
      local delayPerMessage = 10 -- detik antar kirim
      local maxMessages = 10 -- batas pesan
      local total = #logs
      local startIndex = math.max(total - maxMessages + 1, 1)

      task.spawn(function()
          -- Header dulu
          channel:SendAsync("History chat " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. "):")
          task.wait(delayPerMessage)

          -- Kirim satu per satu
          for i = startIndex, total do
              local entry = logs[i]
              local messageText = string.format("[%s] %s", entry.time, entry.text)
              channel:SendAsync(messageText)
              task.wait(delayPerMessage)
          end
      end)
  end
}
