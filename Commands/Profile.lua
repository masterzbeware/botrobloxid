-- Profile.lua
-- Perintah: !profile {displayname/username}
-- Aman dari sensor Roblox (tidak perlu mengetik UserId langsung)
-- Mengambil jumlah Connections, Followers, dan Following via RemoteFunction

return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local Players = game:GetService("Players")

      -- Ambil teks pesan (berbagai kemungkinan field tergantung versi TextChatService)
      local content = (msg.Text or msg.Message or msg.Body or ""):lower()
      local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

      -- Pastikan mengandung perintah !profile
      if not string.find(content, "!profile") then
          if channel then channel:SendAsync("⚠️ Tidak ada perintah !profile ditemukan.") end
          return
      end

      -- Ambil argumen setelah !profile (username atau displayname)
      local _, _, username = string.find(content, "!profile%s+([%w_%-]+)")
      if not username or username == "" then
          if channel then
              channel:SendAsync("⚠️ Format salah! Gunakan: !profile {username/displayname}")
          end
          return
      end

      local targetUserId
      local foundPlayer

      -- Coba cari berdasarkan username (offline / global)
      local successGetId, err = pcall(function()
          targetUserId = Players:GetUserIdFromNameAsync(username)
      end)

      -- Kalau gagal, coba cari player yang sedang online (display name cocok)
      if not successGetId or not targetUserId then
          for _, player in ipairs(Players:GetPlayers()) do
              if string.lower(player.DisplayName) == string.lower(username)
                  or string.lower(player.Name) == string.lower(username) then
                  targetUserId = player.UserId
                  foundPlayer = player
                  break
              end
          end
      end

      -- Jika tidak ditemukan sama sekali
      if not targetUserId then
          if channel then
              channel:SendAsync("❌ Pengguna '" .. username .. "' tidak ditemukan.")
          end
          return
      end

      -- Ambil RemoteFunction
      local playerDataProvider = ReplicatedStorage
          :WaitForChild("Connections")
          :WaitForChild("dataProviders")
          :WaitForChild("playerData")

      -- Panggil fungsi getPlayerStats di server
      local statsResult
      local success, err = pcall(function()
          local argsStats = {"getPlayerStats", targetUserId}
          statsResult = playerDataProvider:InvokeServer(unpack(argsStats))
      end)

      if not success or not statsResult then
          if channel then
              channel:SendAsync("⚠️ Gagal mengambil data profil untuk " .. username .. ".")
          end
          return
      end

      -- Ambil data aman (fallback jika field beda nama)
      local connections = statsResult.Connections or statsResult.connections or statsResult.Friends or 0
      local followers = statsResult.Followers or statsResult.followers or 0
      local following = statsResult.Following or statsResult.following or 0

      -- Kirim hasil ke chat
      if channel then
          local displayName = foundPlayer and foundPlayer.DisplayName or username
          local message = string.format(
              "📊 Profil %s:\n👥 Connections: %d\n📈 Followers: %d\n📉 Following: %d",
              displayName, connections, followers, following
          )
          pcall(function()
              channel:SendAsync(message)
          end)
      end
  end
}
