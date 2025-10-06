-- Profile.lua
-- Ambil data Connections, Followers, dan Following via RemoteFunction

return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local Players = game:GetService("Players")

      local content = msg.Text or ""
      local args = string.split(content, " ")

      -- Format: !profile {username}
      if #args < 2 then
          local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
          if channel then
              channel:SendAsync("⚠️ Format salah! Gunakan: !profile {username}")
          end
          return
      end

      local targetName = args[2]
      local targetUserId

      pcall(function()
          targetUserId = Players:GetUserIdFromNameAsync(targetName)
      end)

      if not targetUserId then
          local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
          if channel then
              channel:SendAsync("❌ Pengguna '" .. targetName .. "' tidak ditemukan.")
          end
          return
      end

      local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
      local playerDataProvider = ReplicatedStorage:WaitForChild("Connections"):WaitForChild("dataProviders"):WaitForChild("playerData")

      -- Ambil data dari server
      local statsResult
      local success, err = pcall(function()
          local argsStats = {"getPlayerStats", targetUserId}
          statsResult = playerDataProvider:InvokeServer(unpack(argsStats))
      end)

      if not success or not statsResult then
          if channel then
              channel:SendAsync("⚠️ Gagal mengambil data untuk " .. targetName .. ".")
          end
          return
      end

      -- Ambil info yang diperlukan
      local connections = statsResult.Connections or statsResult.connections or 0
      local followers = statsResult.Followers or statsResult.followers or 0
      local following = statsResult.Following or statsResult.following or 0

      -- Kirim hasil ke chat
      if channel then
          local message = string.format("📊 Profil %s:\n👥 Connections: %d\n📈 Followers: %d\n📉 Following: %d", targetName, connections, followers, following)
          pcall(function()
              channel:SendAsync(message)
          end)
      end
  end
}
