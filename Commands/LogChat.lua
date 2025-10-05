-- LogChat.lua
-- Command: !logchat {displayname/username}
-- Fitur: Menyimpan dan menampilkan history chat pemain di server

return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")
      local Players = game:GetService("Players")
      local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

      -- Pastikan _G.ChatLogs ada
      _G.ChatLogs = _G.ChatLogs or {}

      -- Inisialisasi listener global (hanya sekali)
      if not _G.ChatLogListenerSet then
          _G.ChatLogListenerSet = true
          print("[LogChat] Listener chat global aktif")

          -- Gunakan TextChatService jika tersedia
          if TextChatService and TextChatService.TextChannels then
              local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
              if generalChannel then
                  generalChannel.OnIncomingMessage = function(message)
                      local senderUserId = message.TextSource and message.TextSource.UserId
                      local sender = senderUserId and Players:GetPlayerByUserId(senderUserId)
                      if sender then
                          -- Simpan log chat pemain
                          local logs = _G.ChatLogs[sender.UserId] or {}
                          table.insert(logs, {
                              text = message.Text,
                              time = os.date("%H:%M:%S"),
                          })
                          _G.ChatLogs[sender.UserId] = logs
                      end
                  end
              end
          end

          -- Jaga-jaga jika chat system lama
          for _, plr in ipairs(Players:GetPlayers()) do
              plr.Chatted:Connect(function(text)
                  local logs = _G.ChatLogs[plr.UserId] or {}
                  table.insert(logs, {
                      text = text,
                      time = os.date("%H:%M:%S"),
                  })
                  _G.ChatLogs[plr.UserId] = logs
              end)
          end

          Players.PlayerAdded:Connect(function(plr)
              plr.Chatted:Connect(function(text)
                  local logs = _G.ChatLogs[plr.UserId] or {}
                  table.insert(logs, {
                      text = text,
                      time = os.date("%H:%M:%S"),
                  })
                  _G.ChatLogs[plr.UserId] = logs
              end)
          end)
      end

      -- Parsing command
      local args = string.split(msg, " ")
      local targetName = args[2]

      if not targetName then
          warn("Nama target tidak diberikan!")
          if channel then
              channel:SendAsync("⚠️ Gunakan format: !logchat {displayname/username}")
          end
          return
      end

      -- Cari player yang cocok
      local foundPlayer = nil
      for _, player in ipairs(Players:GetPlayers()) do
          if string.lower(player.Name) == string.lower(targetName)
          or string.lower(player.DisplayName) == string.lower(targetName) then
              foundPlayer = player
              break
          end
      end

      if not channel then
          warn("[LogChat] Channel RBXGeneral tidak ditemukan!")
          return
      end

      if not foundPlayer then
          channel:SendAsync("⚠️ Player " .. targetName .. " tidak ditemukan di server ini.")
          return
      end

      -- Ambil log chat player tersebut
      local logs = _G.ChatLogs[foundPlayer.UserId]

      if not logs or #logs == 0 then
          channel:SendAsync("💬 Tidak ada chat history untuk " .. foundPlayer.DisplayName .. " (@" .. foundPlayer.Name .. ").")
          return
      end

      -- Kirimkan hasil log (maks 10 terakhir)
      local maxMessages = 10
      local total = #logs
      local startIndex = math.max(total - maxMessages + 1, 1)

      local summary = {}
      table.insert(summary, "📜 Chat history untuk " .. foundPlayer.DisplayName .. " (@" .. foundPlayer.Name .. "):")

      for i = startIndex, total do
          local entry = logs[i]
          table.insert(summary, "[" .. entry.time .. "] " .. entry.text)
      end

      channel:SendAsync(table.concat(summary, "\n"))
  end
}
