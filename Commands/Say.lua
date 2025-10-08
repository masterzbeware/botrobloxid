-- Say.lua
-- Penggunaan: !say {teks}
-- Contoh: !say Halo semuanya!

return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")

      -- Ambil teks setelah "!say "
      local content = msg.Content or ""
      local args = string.match(content, "^!say%s+(.+)$")

      if not args or args == "" then
          warn("Tidak ada teks yang dimasukkan untuk !say")
          return
      end

      -- Kirim chat ke RBXGeneral
      local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
      if channel then
          pcall(function()
              channel:SendAsync(args)
          end)
      else
          warn("Channel RBXGeneral tidak ditemukan!")
      end
  end
}
