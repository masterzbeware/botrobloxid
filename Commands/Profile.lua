-- Profile.lua (versi anti-error)
-- Perintah: !profile {displayname/username}

return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local Players = game:GetService("Players")

      local content = tostring(msg.Text or msg.Message or msg.Body or "")
      local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

      -- Cek apakah pesan mengandung perintah !profile
      if not string.find(content:lower(), "!profile") then return end

      -- Ambil nama setelah !profile
      local _, _, nameArg = string.find(content, "!profile%s+([%w_%-]+)")
      if not nameArg or nameArg == "" then
          if channel then channel:SendAsync("⚠️ Format salah! Gunakan: !profile {username/displayname}") end
          return
      end

      local username = nameArg
      local targetUserId = nil
      local foundPlayer = nil

      -- Coba dapatkan UserId via username (global)
      local ok, result = pcall(function()
          return Players:GetUserIdFromNameAsync(username)
      end)

      if ok and result then
          targetUserId = result
      else
          -- Kalau gagal, cari di pemain yang sedang online (cocokkan DisplayName / Name)
          for _, player in ipairs(Players:GetPlayers()) do
              if string.lower(player.DisplayName) == string.lower(username)
              or string.lower(player.Name) == string.lower(username) then
                  targetUserId = player.UserId
                  foundPlayer = player
                  break
              end
          end
      end

      -- Kalau masih belum ketemu
      if not targetUserId then
          if channel then
              channel:SendAsync("❌ Pengguna '" .. username .. "' tidak ditemukan di sistem Roblox.")
          end
          return
      end

      -- Ambil data dari server
      local playerDataProvider = ReplicatedStorage
          :WaitForChild("Connections")
          :WaitForChild("dataProviders")
          :WaitForChild("playerData")

      local statsResult
      local success, err = pcall(function()
          local argsStats = {"getPlayerStats", targetUserId}
          statsResult = playerDataProvider:InvokeServer(unpack(argsStats))
      end)

      if not success or not statsResult then
          if channel then
              channel:SendAsync("⚠️ Gagal mengambil data profil untuk " .. username .. ".")
          end
          warn("InvokeServer error:", err)
          return
      end

      local connections = statsResult.Connections or statsResult.connections or statsResult.Friends or 0
      local followers = statsResult.Followers or statsResult.followers or 0
      local following = statsResult.Following or statsResult.following or 0

      if channel then
          local displayName = foundPlayer and foundPlayer.DisplayName or username
          local message = string.format(
              "📊 Profil %s:\n👥 Connections: %d\n📈 Followers: %d\n📉 Following: %d",
              displayName, connections, followers, following
          )
          pcall(function() channel:SendAsync(message) end)
      end
  end
}
