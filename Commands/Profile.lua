-- Profile.lua
-- Perintah: !profile {userid}
-- Mengambil jumlah Connections, Followers, dan Following via RemoteFunction

return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")

      -- Ambil isi pesan dari berbagai kemungkinan field
      local content = (msg.Text or msg.Message or msg.Body or ""):lower()
      local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

      -- Pastikan mengandung !profile
      if not string.find(content, "!profile") then
          if channel then channel:SendAsync("⚠️ Tidak ada perintah !profile ditemukan.") end
          return
      end

      -- Ambil angka userId setelah !profile
      local _, _, userIdStr = string.find(content, "!profile%s+(%d+)")
      if not userIdStr then
          if channel then
              channel:SendAsync("⚠️ Format salah! Gunakan: !profile {UserId}\nContoh: !profile 9102461210")
          end
          return
      end

      local userId = tonumber(userIdStr)
      if not userId then
          if channel then
              channel:SendAsync("❌ UserId tidak valid!")
          end
          return
      end

      -- Ambil RemoteFunction
      local playerDataProvider = ReplicatedStorage:WaitForChild("Connections"):WaitForChild("dataProviders"):WaitForChild("playerData")

      -- Panggil getPlayerStats
      local statsResult
      local success, err = pcall(function()
          local argsStats = {"getPlayerStats", userId}
          statsResult = playerDataProvider:InvokeServer(unpack(argsStats))
      end)

      if not success or not statsResult then
          if channel then
              channel:SendAsync("⚠️ Gagal mengambil data profil untuk UserId " .. tostring(userId) .. ".")
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
              "📊 Profil UserId %d:\n👥 Connections: %d\n📈 Followers: %d\n📉 Following: %d",
              userId, connections, followers, following
          )
          pcall(function()
              channel:SendAsync(message)
          end)
      end
  end
}
