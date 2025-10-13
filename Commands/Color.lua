-- Color.lua
-- Command dinamis: !color <nama_warna>
-- Contoh: !color Pink → akan ubah tema menjadi Pink

return {
  Execute = function(msg, client)
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local themeProvider = ReplicatedStorage:WaitForChild("Connections"):WaitForChild("dataProviders"):WaitForChild("themeProvider")

      -- Ambil warna dari pesan, contoh: "!color Pink" → "Pink"
      local colorName = msg:match("!color%s+(%w+)")
      if not colorName then
          warn("Perintah warna tidak ditemukan. Gunakan format: !color <nama_warna>")
          return
      end

      -- Jalankan perintah ubah warna
      local args = { "saveTheme", colorName }
      pcall(function()
          themeProvider:InvokeServer(unpack(args))
      end)
  end
}
