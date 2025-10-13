-- Color.lua
-- Command dinamis: !color <nama_warna>
-- Contoh: !color Red → ubah tema menjadi Red

return {
  Execute = function(msg, client)
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local themeProvider = ReplicatedStorage:WaitForChild("Connections")
          :WaitForChild("dataProviders")
          :WaitForChild("themeProvider")

      -- Ambil warna dari pesan, contoh: "!color Red" → "Red"
      local colorName = tostring(msg):match("!color%s+(%w+)")
      if not colorName then
          warn("Format salah. Gunakan: !color <nama_warna>")
          return
      end

      -- Bentuk argumen sesuai format RemoteSpy
      local args = { "saveTheme", colorName }

      -- Jalankan perubahan warna
      local success, err = pcall(function()
          themeProvider:InvokeServer(unpack(args))
      end)

      if not success then
          warn("Gagal mengubah tema ke " .. colorName .. ": " .. tostring(err))
      end
  end
}
