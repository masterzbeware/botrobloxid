-- VoteSkip.lua
-- Mengirim perintah vote skip musik lewat RemoteFunction di ReplicatedStorage
-- Bisa dijalankan oleh semua bot sekaligus atau bot tertentu (!voteskip1)

return {
  Execute = function(msg, client)
      local vars = _G.BotVars
      local player = vars.LocalPlayer

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
          warn("[VoteSkip] Bot ini tidak terdaftar dalam daftar orderedBots.")
          return
      end

      -- 🔹 Cek apakah command hanya untuk bot tertentu (contoh: !voteskip3)
      local targetBot = msg:lower():match("!voteskip(%d)")
      if targetBot then
          local targetIndex = tonumber(targetBot)
          local botIndex = tonumber(botName:match("%d+"))
          if botIndex ~= targetIndex then
              return -- Bukan bot target → abaikan
          end
      end

      -- 🔹 Jalankan VoteSkip
      local success, err = pcall(function()
          local ReplicatedStorage = game:GetService("ReplicatedStorage")

          local musicInfo = ReplicatedStorage
              :WaitForChild("Connections")
              :WaitForChild("dataProviders")
              :WaitForChild("musicInfo")

          local args = { "voteSkip" }
          musicInfo:InvokeServer(unpack(args))

          print(string.format("[VoteSkip] %s mengirim vote skip musik.", botName))
      end)

      if not success then
          warn(string.format("[VoteSkip] %s gagal mengirim vote skip:", botName), err)
      end
  end
}
