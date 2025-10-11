-- AddSong.lua
-- Format command: !addsongX Y
-- X = jumlah bot (1-5), Y = nomor lagu dari daftar
-- Contoh:
-- !addsong1 3 → Bot1 mainkan lagu ke-3
-- !addsong3 5 → Bot1,2,3 mainkan lagu ke-5

return {
  Execute = function(msg, client)
      local vars = _G.BotVars
      local player = vars.LocalPlayer
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local TextChatService = game:GetService("TextChatService")

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
          warn("[AddSong] Bot ini tidak terdaftar.")
          return
      end

      -- 🔹 Daftar lagu: {ID, Nama}
      local songsList = {
          {112560602503664, "DJ RAUL - Trumpets Indo❤️🤍"},
          {89769266566391, "DJ RAUL - American Dream❤️🤍"},
          {137091068460714, "DJ RAUL - An Angel's lv Breakbeat❤️🤍"},
          {132204088943259, "DJ RAUL - Brondong Tua❤️🤍"},
          {115721431142872, "DJ RAUL - Barudak Phonk x Hislerim❤️🤍"},
          {72843718540231, "DJ Raul - Disini Ku Menunggu❤️🤍"},
          {97215362773831, "DJ RAUL - Danza Kuduro Indo❤️🤍"},
          {110528276472565, "DJ RAUL - DJ BreakBeat`1❤️🤍"},
          {127501544144452, "DJ RAUL - Drop Enakeun vol 1❤️🤍"},
          {76598718306969, "DJ RAUL - Gateng Gateng Swag❤️🤍"},
          {116233228464487, "DJ RAUL - Drop Enakeun vol 2❤️🤍"},
          {139911880542681, "DJ RAUL - Gala Gala Cocok Buat Di Mobil❤️🤍"},
          {100095371428503, "DJ RAUL - Mengkane Full Bass Terbaru❤️🤍"},
          {87169339469707, "DJ RAUL - Mengkane Terbaru Yan❤️🤍"},
          {108157298681685, "DJ RAUL - Su Jauh Sa Tanam Tapi❤️🤍"},
          {118542510245362, "DJ RAUL - Timur Ke Barat Selatan Ke Utara❤️🤍"},
          {129315246645478, "DJ RAUL - Goyang Goyang❤️🤍"},
          {86754477838853, "DJ RAUL - Rules BreakBeat x Where Hve You Been❤️🤍"},
          {133979918440315, "DJ RAUL - Jedag Jedug Viral❤️🤍"},
          {114548763254115, "DJ RAUL - Trumpet Vacation Old Remix Mengkane❤️🤍"},
      }

      -- 🔹 Parsing command: !addsongX Y
      local targetBotCount, songIndex = msg:lower():match("!addsong(%d+)%s*(%d+)")
      targetBotCount = tonumber(targetBotCount) or 1
      songIndex = tonumber(songIndex) or 1

      if songIndex > #songsList or songIndex < 1 then
          warn("[AddSong] Nomor lagu tidak valid.")
          return
      end

      local id, name = table.unpack(songsList[songIndex])

      -- 🔹 Cek apakah bot termasuk dalam target
      local botNum = tonumber(botName:match("%d+"))
      if botNum > targetBotCount then return end

      -- 🔹 Jalankan save + add
      local success, err = pcall(function()
          local musicInfo = ReplicatedStorage
              :WaitForChild("Connections")
              :WaitForChild("dataProviders")
              :WaitForChild("musicInfo")

          -- Simpan lagu
          musicInfo:InvokeServer("saveSong", id)
          print(string.format("[AddSong] %s menyimpan: %s (ID: %s)", botName, name, id))
          task.wait(0.5)

          -- Tambahkan ke antrian
          musicInfo:InvokeServer("addSongToQueue", id)
          print(string.format("[AddSong] %s menambahkan ke antrian: %s (ID: %s)", botName, name, id))

          -- Kirim pesan ke chat
          local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
          if channel then
              channel:SendAsync(string.format("✅ %s menambahkan lagu: %s", botName, name))
          end
      end)

      if not success then
          warn("[AddSong] Gagal menambahkan lagu:", err)
      end
  end
}
