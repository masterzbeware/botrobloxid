-- AddSong.lua
-- Format command: !addsongX Y
-- X = jumlah bot (1-5), Y = nomor lagu dari daftar

return {
  Execute = function(msg, client)
      local vars = _G.BotVars
      local player = vars.LocalPlayer
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local TextChatService = game:GetService("TextChatService")

      -- Daftar Bot
      local orderedBots = {
          ["8802945328"] = "Bot1",
          ["8802949363"] = "Bot2",
          ["8802939883"] = "Bot3",
          ["8802998147"] = "Bot4",
          ["8802991722"] = "Bot5",
      }

      local myUserId = tostring(player.UserId)
      local botName = orderedBots[myUserId]
      if not botName then return end

      -- Daftar lagu: {ID, Judul tanpa emoji}
      local songsList = {
        {112560602503664, "DJ RAUL - Trumpets Indo"},
        {89769266566391, "DJ RAUL - American Dream"},
        {137091068460714, "DJ RAUL - An Angel's lv Breakbeat"},
        {132204088943259, "DJ RAUL - Brondong Tua"},
        {115721431142872, "DJ RAUL - Barudak Phonk x Hislerim"},
        {72843718540231, "DJ Raul - Disini Ku Menunggu"},
        {97215362773831, "DJ RAUL - Danza Kuduro Indo"},
        {110528276472565, "DJ RAUL - DJ BreakBeat`1"},
        {127501544144452, "DJ RAUL - Drop Enakeun vol 1"},
        {76598718306969, "DJ RAUL - Gateng Gateng Swag"},
        {116233228464487, "DJ RAUL - Drop Enakeun vol 2"},
        {139911880542681, "DJ RAUL - Gala Gala Cocok Buat Di Mobil"},
        {100095371428503, "DJ RAUL - Mengkane Full Bass Terbaru"},
        {87169339469707, "DJ RAUL - Mengkane Terbaru Yan"},
        {108157298681685, "DJ RAUL - Su Jauh Sa Tanam Tapi"},
        {118542510245362, "DJ RAUL - Timur Ke Barat Selatan Ke Utara"},
        {129315246645478, "DJ RAUL - Goyang Goyang"},
        {86754477838853, "DJ RAUL - Rules BreakBeat x Where Hve You Been"},
        {133979918440315, "DJ RAUL - Jedag Jedug Viral"},
        {114548763254115, "DJ RAUL - Trumpet Vacation Old Remix Mengkane"},
        {72410153799647, "DEAR MANTAN - D'BAGAS (BKB EDIT)"},
        {108765137432514, "DJ CHICA LOCA BREAKBEAT - Jakarta Reborn"},
        {125327829859584, "DJ DANCE FLOOR THAI X TOMATO BRAZIL X MASHUP"},
        {102431434964918, "DJ SYMPHONY X RUTINITAS RADONG"},
        {105907796954899, "MYSTERIOUS GIRL MASHUP TABOLA BALE X CALON MANTU"},
        {77352127934878, "DJ LAMINE YAMAL Y QUE FUE X MUGWANTI"},
        {116079941526097, "DULU PERNAH VIRAL BEAUTIFUL NOW X STYLE PARGOY"},
        {76282745301971, "DJ Bass Freaks Stadium"},
    }
    

      -- Parsing command: !addsongX Y
      local targetBotCount, songIndex = msg:lower():match("!addsong(%d+)%s*(%d+)")
      targetBotCount = tonumber(targetBotCount) or 1
      songIndex = tonumber(songIndex) or 1

      if songIndex < 1 or songIndex > #songsList then return end
      local id, name = table.unpack(songsList[songIndex])

      -- Cek apakah bot termasuk dalam target
      local botNum = tonumber(botName:match("%d+"))
      if botNum > targetBotCount then return end

      -- Jalankan save + add
      local success, err = pcall(function()
          local musicInfo = ReplicatedStorage
              :WaitForChild("Connections")
              :WaitForChild("dataProviders")
              :WaitForChild("musicInfo")

          -- Save lagu
          musicInfo:InvokeServer("saveSong", id)
          task.wait(0.5)

          -- Add ke antrian
          musicInfo:InvokeServer("addSongToQueue", id)
          task.wait(0.3)

          -- Kirim pesan chat simple
          local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
          if channel then
              channel:SendAsync(string.format("Lagu %s telah ditambahkan", name))
          end
      end)

      if not success then
          warn("[AddSong] Gagal menambahkan lagu:", err)
      end
  end
}
