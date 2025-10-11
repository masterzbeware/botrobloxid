-- Vote.lua
-- Mengirim vote skip musik lewat RemoteFunction di ReplicatedStorage

return {
  Execute = function(msg, client)
      local success, err = pcall(function()
          local ReplicatedStorage = game:GetService("ReplicatedStorage")

          local musicInfo = ReplicatedStorage
              :WaitForChild("Connections")
              :WaitForChild("dataProviders")
              :WaitForChild("musicInfo")

          local args = { "voteSkip" }
          musicInfo:InvokeServer(unpack(args))

          print("[Vote] Vote skip berhasil dikirim.")
      end)

      if not success then
          warn("[Vote] Gagal mengirim vote skip:", err)
      end
  end
}
