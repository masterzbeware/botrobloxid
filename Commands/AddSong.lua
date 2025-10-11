-- AddSong.lua
-- !addsong <id>  → Semua bot menyimpan lagu dulu, lalu menambah ke antrian
-- !addsong1 <id> → Hanya Bot1 yang menyimpan dan menambah ke antrian

return {
  Execute = function(msg, client)
      local vars = _G.BotVars
      local player = vars.LocalPlayer
      local ReplicatedStorage = game:GetService("ReplicatedStorage")

      -- 🔹 Daftar Bot
      local orderedBots = {
          ["8802945328"] = "Bot1",
          ["8802949363"] = "Bot2",
          ["8802939883"] = "Bot3",
          ["8802998147"] = "Bot4",
          ["8802991722"] = "Bot5",
      }

      local myUserId = tostring(player.UserId)
      local botName = orderedBots[myUserId]
      if not botName then
          warn("[AddSong] Bot ini tidak terdaftar dalam daftar orderedBots.")
          return
      end

      -- 🔹 Cek perintah (contoh: !addsong1 → targetBot = 1)
      local targetBot = msg:lower():match("!addsong(%d)")
      local songId = tonumber(msg:match("%d+"))

      if not songId then
          warn("[AddSong] Tidak ada ID lagu ditemukan di pesan.")
          return
      end

      -- 🔹 Jika command khusus (seperti !addsong1), hanya bot itu yang jalan
      if targetBot then
          local targetIndex = tonumber(targetBot)
          local botIndex = tonumber(botName:match("%d+"))
          if botIndex ~= targetIndex then
              return -- Bukan bot target → abaikan
          end
      end

      -- 🔹 Jalankan save dulu, baru add
      local success, err = pcall(function()
          local musicInfo = ReplicatedStorage
              :WaitForChild("Connections")
              :WaitForChild("dataProviders")
              :WaitForChild("musicInfo")

          local saveArgs = { "saveSong", songId }
          local addArgs = { "addSongToQueue", songId }

          -- 🔸 1. Simpan lagu dulu
          musicInfo:InvokeServer(unpack(saveArgs))
          print(string.format("[AddSong] %s menyimpan lagu ID: %s", botName, songId))

          task.wait(0.5) -- jeda kecil agar server punya waktu proses

          -- 🔸 2. Tambahkan ke antrian
          musicInfo:InvokeServer(unpack(addArgs))
          print(string.format("[AddSong] %s menambahkan lagu ke antrian ID: %s", botName, songId))
      end)

      if not success then
          warn(string.format("[AddSong] %s gagal menyimpan/menambahkan lagu:", botName), err)
      end
  end
}
