-- AutoJoinClient.lua
-- Bot otomatis pindah server ke tempat ActiveClient tanpa command

return {
  Execute = function()
      local vars = _G.BotVars
      local Players = game:GetService("Players")
      local LocalPlayer = Players.LocalPlayer
      local TeleportService = game:GetService("TeleportService")
      local HttpService = game:GetService("HttpService")
      local RunService = game:GetService("RunService")

      local checkInterval = 10 -- detik
      local lastCheck = 0

      print("[AutoJoinClient] Sistem auto teleport aktif.")

      local function findClientServer(clientName)
          -- Panggil API Roblox untuk dapat daftar server public
          local placeId = game.PlaceId
          local url = ("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100"):format(placeId)

          local success, data = pcall(function()
              return HttpService:JSONDecode(game:HttpGet(url))
          end)
          if not success or not data or not data.data then
              warn("[AutoJoinClient] Tidak dapat mengambil daftar server publik.")
              return nil
          end

          -- Coba cari client di daftar server publik
          for _, server in ipairs(data.data) do
              if server.playing > 0 then
                  for _, player in ipairs(server.playerIds or {}) do
                      local nameSuccess, playerName = pcall(function()
                          return Players:GetNameFromUserIdAsync(player)
                      end)
                      if nameSuccess and playerName:lower() == clientName:lower() then
                          return server.id -- return JobId server tempat client berada
                      end
                  end
              end
          end
          return nil
      end

      -- Loop pengecekan otomatis
      RunService.Heartbeat:Connect(function()
          if tick() - lastCheck < checkInterval then return end
          lastCheck = tick()

          local clientName = vars.ActiveClient
          if not clientName or clientName == "" then return end

          -- Cek apakah client ada di server
          local client = Players:FindFirstChild(clientName)
          if client then
              -- Client ada di server yang sama
              return
          end

          print("[AutoJoinClient] Client tidak ditemukan di server ini. Mencari server client...")

          -- Cari server client
          local jobId = findClientServer(clientName)
          if jobId then
              print("[AutoJoinClient] Menemukan client di server JobId:", jobId)
              local success, err = pcall(function()
                  TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
              end)
              if success then
                  print("[AutoJoinClient] Teleportasi dikirim ke server client.")
              else
                  warn("[AutoJoinClient] Gagal teleport:", err)
              end
          else
              warn("[AutoJoinClient] Gagal menemukan server client.")
          end
      end)
  end
}
