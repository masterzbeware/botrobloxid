-- Profile.lua
-- Perintah: !profile {displayname/username}
-- Mengambil jumlah Connections, Followers, dan Following lewat RemoteFunction

return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local Players = game:GetService("Players")

      -- Ambil teks pesan dari berbagai kemungkinan field
      local content = (msg.Text or msg.Message or msg.Body or ""):lower()
      local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

      -- Pastikan mengandung !profile
      if not string.find(content, "!profile") then
          if channel then channel:SendAsync("⚠️ Tidak ada perintah !profile ditemukan.") end
          return
      end

      -- Ambil argumen setelah !profile
      local _, _, arg = string.find(content, "!profile%s+([%w_%-]+)")
      if not arg or arg == "" then
          if channel then
              channel:SendAsync("⚠️ Format salah! Gunakan: !profile {displayname/username}")
          end
          return
      end

      local searchName = arg
      local targetUserId
      local foundPlayer

      -- Coba cari berdasarkan username (offline user)
      pcall(function()
          targetUserId = Players:GetUserIdFromNameAsync(searchName)
      end)

      -- Kalau gagal, coba cari player yang sedang online (display name / username cocok)
      if not targetUserId then
          for _, player in ipairs(Players:GetPlayers()) do
              if string.lower(player.DisplayName) == string.lower(searchName) or string.lower(player.Name) == string.lower(searchName) then
                  targetUserId = player.UserId
                  foundPlayer = player
                  break
              end
          end
      end

      -- Jika tetap tidak ditemukan
      if not targetUserId then
          if channel then
              channel:SendAsync("❌ Pengguna '" .. searchName .. "' tidak ditemukan.")
          end
          return
      end

      -- Ambil RemoteFunction
      local playerDataProvider = ReplicatedStorage:WaitForChild("Connections"):WaitForChild("dataProviders"):WaitForChild("playerData")

      -- Panggil getPlayerStats
      local statsResult
      local success, err = pcall(function()
          local argsStats = {"getPlayerStats", targetUserId}
          statsResult = playerDataProvider:InvokeServer(unpack(argsStats))
      end)

      if not success or not statsResult then
          if channel then
              channel:SendAsync("⚠️ Gagal mengambil data profil untuk " .. searchName .. ".")
          end
          return
      end

      -- Ambil data aman
      local connections = statsResult.Connections or statsResult.connections or statsResult.Friends or 0
      local followers = statsResult.Followers or statsResult.followers or 0
      local following = statsResult.Following or statsResult.following or 0

      -- Kirim hasil ke chat
      if channel then
          local message = string.format(
              "📊 Profil %s:\n👥 Connections: %d\n📈 Followers: %d\n📉 Following: %d",
              foundPlayer and foundPlayer.DisplayName or searchName,
              connections,
              followers,
              following
          )
          pcall(function()
              channel:SendAsync(message)
          end)
      end
  end
}
