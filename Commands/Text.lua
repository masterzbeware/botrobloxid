return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local TextChatService = game:GetService("TextChatService")
      local channel

      if TextChatService.TextChannels then
          channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
      end

      if not channel then
          warn("[Text] Channel RBXGeneral tidak ditemukan!")
          return
      end

      -- Tandai loop aktif
      vars.TextLoopActive = true

      -- Pasangan teks (setiap set = 2 pesan)
      local textSets = {
          {
              "Kamu butuh jasa promosi? kami siap membantu!",
              "Silakan dm kami di dc 'FiestaGuard'"
          },
          {
              "Ingin server kamu makin ramai?",
              "Hubungi FiestaGuard sekarang juga!"
          }
      }

      -- Jalankan loop kirim teks berulang secara acak
      task.spawn(function()
          while vars.TextLoopActive and channel do
              -- Pilih set acak (1 atau 2)
              local selectedSet = textSets[math.random(1, #textSets)]

              -- Kirim pesan dalam urutan (teks1 -> teks2)
              for _, text in ipairs(selectedSet) do
                  if not vars.TextLoopActive then return end
                  pcall(function()
                      channel:SendAsync(text)
                  end)
                  task.wait(4) -- delay antar pesan
              end

              -- Tunggu sebelum mulai set baru
              task.wait(15)
          end
      end)
  end
}
