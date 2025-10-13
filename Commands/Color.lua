-- Color.lua
-- Command dinamis: !color <nama_warna>
-- Contoh: !color Red → ubah tema menjadi Red

return {
  Execute = function(msg, client)
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local themeProvider = ReplicatedStorage
          :WaitForChild("Connections")
          :WaitForChild("dataProviders")
          :WaitForChild("themeProvider")

      -- Ambil warna dari pesan, contoh: "!color red" → "red"
      local colorName = tostring(msg):match("!color%s+(%w+)")
      if not colorName then
          warn("Format salah. Gunakan: !color <nama_warna>")
          return
      end

      -- Ubah huruf pertama jadi kapital agar cocok dengan server-side ("Red", "Pink", dst.)
      colorName = colorName:sub(1,1):upper() .. colorName:sub(2):lower()

      local args = { "saveTheme", colorName }

      local success, err = pcall(function()
          themeProvider:InvokeServer(unpack(args))
      end)

      if not success then
          warn("Gagal mengubah tema ke " .. colorName .. ": " .. tostring(err))
      else
          print("[Color.lua] Tema berhasil diubah ke:", colorName)
      end
  end
}
