-- Reporting.lua
-- Command: !reporting {username/displayname}
-- Contoh: !reporting Jshdh

return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")

      -- Ambil argumen setelah !reporting
      local args = string.split(msg, " ")
      local targetName = args[2] or "UnknownPlayer"

      -- Kirim chat berulang tiap 10 detik
      local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
      if channel then
          task.spawn(function()
              while true do
                  pcall(function()
                      channel:SendAsync("⚠️ Melakukan Reporting dengan akun @" .. targetName .. " ke sistem moderasi Roblox...")
                      channel:SendAsync("⚠️ Data @" .. targetName .. " sudah terkirim.")
                  end)
                  task.wait(15) -- cooldown 10 detik
              end
          end)
      else
          warn("Channel RBXGeneral tidak ditemukan!")
      end
  end
}
