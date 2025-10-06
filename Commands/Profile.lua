-- Debug Profile.lua
return {
  Execute = function(msg, client)
      print("Profile.lua >> Execute dipanggil dengan pesan:", msg.Text)

      local vars = _G.BotVars or {}
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local Players = game:GetService("Players")

      local content = tostring(msg.Text or "")
      local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

      if not channel then
          warn("⚠️ Channel RBXGeneral tidak ditemukan!")
      end

      local _, _, username = string.find(content, "!profile%s+([%w_%-]+)")
      print("DEBUG >> Username arg:", username)

      if not username then
          if channel then channel:SendAsync("Format salah! Gunakan: !profile {username}") end
          return
      end

      local userId
      local ok, res = pcall(function()
          return Players:GetUserIdFromNameAsync(username)
      end)
      if ok then userId = res end
      print("DEBUG >> userId:", userId)

      if not userId then
          if channel then channel:SendAsync("❌ Pengguna tidak ditemukan.") end
          return
      end

      local playerDataProvider = ReplicatedStorage:WaitForChild("Connections"):WaitForChild("dataProviders"):WaitForChild("playerData")
      local stats
      local success, err = pcall(function()
          stats = playerDataProvider:InvokeServer("getPlayerStats", userId)
      end)
      print("DEBUG >> InvokeServer:", success, stats, err)

      if not success or not stats then
          if channel then channel:SendAsync("Gagal mengambil data profil.") end
          return
      end

      local connections = stats.Connections or stats.connections or stats.Friends or 0
      local followers = stats.Followers or stats.followers or 0
      local following = stats.Following or stats.following or 0

      local message = string.format("📊 Profil %s:\n👥 Connections: %d\n📈 Followers: %d\n📉 Following: %d", username, connections, followers, following)
      print("DEBUG >> Final message:", message)

      if channel then
          channel:SendAsync(message)
      end
  end
}
