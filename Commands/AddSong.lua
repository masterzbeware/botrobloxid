-- AddSong.lua
-- !addsongid <id> → Simpan ID lagu
-- !addsong        → Semua bot save + add lagu terakhir
-- !addsong1       → Hanya Bot1 yang save + add
-- Tambahan: Kirim pesan konfirmasi ke chat jika berhasil

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
          warn("[AddSong] Bot ini tidak terdaftar dalam daftar orderedBots.")
          return
      end

      -- 🔹 Command: !addsongid <id>
      if msg:lower():match("!addsongid") then
          local songId = tonumber(msg:match("%d+"))
          if songId then
              _G.LastSongId = songId
              print(string.format("[AddSong] %s menyimpan ID lagu: %s", botName, songId))

              -- Kirim konfirmasi ke chat
              local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
              if channel then
                  channel:SendAsync(string.format("💾 %s menyimpan ID lagu: %s", botName, songId))
              end
          else
              warn("[AddSong] Tidak ada angka valid ditemukan untuk ID lagu.")
          end
          return
      end

      -- 🔹 Command: !addsong / !addsongX
      local targetBot = msg:lower():match("!addsong(%d)")
      local songId = _G.LastSongId

      if not songId then
          warn("[AddSong] Belum ada ID lagu tersimpan. Gunakan !addsongid <id> dulu.")
          local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
          if channel then
              channel:SendAsync("⚠️ Belum ada ID lagu tersimpan. Gunakan !addsongid <id> dulu.")
          end
          return
      end

      -- Jika !addsong1 dst, hanya bot tersebut yang aktif
      if targetBot then
          local targetIndex = tonumber(targetBot)
          local botIndex = tonumber(botName:match("%d+"))
          if botIndex ~= targetIndex then return end
      end

      -- 🔹 Jalankan Save + Add
      local success, err = pcall(function()
          local musicInfo = ReplicatedStorage
              :WaitForChild("Connections")
              :WaitForChild("dataProviders")
              :WaitForChild("musicInfo")

          -- 1️⃣ Simpan lagu dulu
          local saveArgs = { "saveSong", songId }
          musicInfo:InvokeServer(unpack(saveArgs))
          print(string.format("[AddSong] %s menyimpan lagu ID: %s", botName, songId))

          task.wait(0.5)

          -- 2️⃣ Tambahkan ke antrian
          local addArgs = { "addSongToQueue", songId }
          musicInfo:InvokeServer(unpack(addArgs))
          print(string.format("[AddSong] %s menambahkan lagu ke antrian ID: %s", botName, songId))

          -- ✅ Kirim pesan ke chat Roblox
          local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
          if channel then
              channel:SendAsync(string.format("✅ %s berhasil menambahkan lagu ke antrian! (ID: %s)", botName, songId))
          end
      end)

      if not success then
          warn(string.format("[AddSong] %s gagal menyimpan/menambahkan lagu:", botName), err)
          local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
          if channel then
              channel:SendAsync(string.format("❌ %s gagal menambahkan lagu (Error: %s)", botName, tostring(err)))
          end
      end
  end
}
