-- Greet.lua (looping chat promosi + /e wave bersamaan dengan chat pertama)
return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local Players = game:GetService("Players")
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")
      local player = vars.LocalPlayer or Players.LocalPlayer

      -- 🔹 Cek command !Greet
      if not msg:lower():match("^!greet") then return end

      -- 🔹 Tandai greeting aktif
      vars.GreetActive = true

      -- 🔹 Ambil channel chat umum
      local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
      local function sendChat(text)
          if channel then
              pcall(function()
                  channel:SendAsync(text)
              end)
          end
      end

      -- 🔹 Daftar opsi chat pertama yang lebih menarik
      local firstMessages = {
          "Halo! sedang mencari bodyguard untuk Konten/seru-seruan?",
          "Hai! Sedang mencari cara efektif untuk promosi clanmu?"
      }

      -- 🔹 Chat kedua dan ketiga tetap persuasif
      local secondMessage = "Kami menyediakan jasa tersebut."
      local thirdMessage = "Hubungi kami di Discord FiestaGuard sekarang untuk info lengkap!"

      -- 🔹 Mulai looping chat
      vars.GreetConnection = task.spawn(function()
          while vars.GreetActive do
              -- Chat pertama: random dari firstMessages + langsung /e wave
              local msgIndex = math.random(1, #firstMessages)
              sendChat(firstMessages[msgIndex])
              sendChat("/e wave")  -- emote bersamaan

              -- Delay 15 detik sebelum chat kedua
              task.wait(15)
              sendChat(secondMessage)

              -- Delay 15 detik sebelum chat ketiga
              task.wait(15)
              sendChat(thirdMessage)
          end
      end)
  end
}
