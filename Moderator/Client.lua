-- 📁 Moderator/Client.lua
-- Sistem Multi-Client dengan Prioritas FiestaGuardVip
-- Dibuat untuk bekerja bersama Bot.lua (MasterZ System)
-- Saat dijalankan, kirim chat “Client system aktif!”

return {
  Execute = function(msg, client)
      -- Ambil variabel global dari Bot.lua
      local vars = _G.BotVars or {}
      local Players = vars.Players or game:GetService("Players")
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")

      -- 🧩 Konfigurasi client utama & sekunder
      local mainClientName = "FiestaGuardVip" -- Client utama
      local secondaryClientName = "Client2"   -- Client kedua (opsional)

      -- Ambil client aktif saat ini
      local activeClient = vars.ActiveClient or mainClientName

      -- Ambil daftar perintah dari Bot.lua (VIP commands)
      local commandFiles = vars.CommandFiles or {}

      -- 🗨️ Fungsi untuk mengirim chat
      local function sendChat(text)
          local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
          if channel then
              pcall(function()
                  channel:SendAsync(text)
              end)
          else
              warn("Channel RBXGeneral tidak ditemukan!")
          end
      end

      --------------------------------------------------------------------
      -- 🟢 Inisialisasi: kirim pesan saat sistem client aktif
      --------------------------------------------------------------------
      sendChat("Client system aktif!")

      --------------------------------------------------------------------
      -- 💬 Deteksi perintah: !Client {username/displayname}
      --------------------------------------------------------------------
      if msg:lower():match("^!client%s+") then
          -- Hanya client utama yang bisa mengganti client aktif
          if client.Name == mainClientName then
              local targetName = msg:match("^!client%s+(.+)")
              if targetName then
                  local targetPlayer = nil

                  -- Cari player berdasarkan DisplayName atau Username
                  for _, plr in ipairs(Players:GetPlayers()) do
                      if plr.DisplayName:lower() == targetName:lower() or plr.Name:lower() == targetName:lower() then
                          targetPlayer = plr
                          break
                      end
                  end

                  if targetPlayer then
                      _G.BotVars.ActiveClient = targetPlayer.Name
                      sendChat("✅ " .. targetPlayer.Name .. " sekarang menjadi Client aktif.")
                  else
                      sendChat("⚠️ Player " .. targetName .. " tidak ditemukan.")
                  end
              else
                  sendChat("Gunakan format: !Client {displayname/username}")
              end
          else
              sendChat("❌ Hanya " .. mainClientName .. " yang dapat mengganti Client aktif.")
          end
          return
      end

      --------------------------------------------------------------------
      -- ⚙️ Jalankan command dari commandFiles jika client sesuai ActiveClient
      --------------------------------------------------------------------
      if client.Name == activeClient then
          local lowerMsg = msg:lower()

          for name, cmd in pairs(commandFiles) do
              if lowerMsg:match("^!" .. name) and cmd.Execute then
                  -- Kirim notifikasi di chat bahwa command sedang dijalankan
                  sendChat("🟢 Menjalankan perintah: " .. name .. " oleh " .. client.Name)

                  -- Eksekusi command
                  local success, err = pcall(function()
                      cmd.Execute(msg, client)
                  end)

                  if not success then
                      warn("Gagal menjalankan command " .. name .. ": " .. tostring(err))
                  end
              end
          end
      else
          -- Jika bukan client aktif, abaikan perintah
          -- Bisa aktifkan log di bawah ini untuk debug:
          -- warn(client.Name .. " bukan client aktif, abaikan pesan.")
      end
  end
}
