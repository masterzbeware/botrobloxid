-- Location.lua
-- Command: !location {displayname/username}

return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")
      local Players = game:GetService("Players")

      -- Ambil argumen setelah !location
      local args = string.split(msg, " ")
      local targetName = args[2]

      if not targetName then
          warn("Nama target tidak diberikan!")
          return
      end

      -- Cek player di server
      local foundPlayer = nil
      for _, player in ipairs(Players:GetPlayers()) do
          if string.lower(player.Name) == string.lower(targetName) 
          or string.lower(player.DisplayName) == string.lower(targetName) then
              foundPlayer = player
              break
          end
      end

      -- Kirim ke RBXGeneral
      local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
      if channel then
          pcall(function()
              if foundPlayer then
                  channel:SendAsync("Player " .. foundPlayer.DisplayName .. " (@" .. foundPlayer.Name .. ") ada di server yang sama.")
              else
                  channel:SendAsync("Player " .. targetName .. " tidak ada di server ini.")
              end
          end)
      else
          warn("Channel RBXGeneral tidak ditemukan!")
      end
  end
}
