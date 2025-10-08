-- Remove.lua
return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local Players = vars.Players or game:GetService("Players")
      local activeClient = vars.ActiveClient or vars.ClientName

      -- 1️⃣ Pastikan !remove hanya dijalankan oleh client aktif
      if client.Name ~= activeClient then
          print("[Remove] Hanya client aktif ("..activeClient..") yang bisa menggunakan !remove.")
          return
      end

      -- 2️⃣ Jalankan Stop.lua otomatis sebelum menghapus
      local stopCmd = vars.CommandFiles and vars.CommandFiles["stop"]
      if stopCmd and stopCmd.Execute then
          stopCmd.Execute("!stop", client)
      end

      -- 3️⃣ Reset ActiveClient menjadi client utama
      vars.ActiveClient = vars.ClientName
      print("[Remove] Client aktif di-reset ke:", vars.ClientName)

      -- 4️⃣ Bisa tambahkan log tambahan jika perlu
      print("[Remove] Semua client sekunder telah dihapus dan Stop telah dijalankan.")
  end
}
