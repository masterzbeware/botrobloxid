-- JoinServer.lua
-- Command: !joinserver → Bot teleport ke server pemain yang sama

return {
  Execute = function(msg, client)
      local Players = game:GetService("Players")
      local TeleportService = game:GetService("TeleportService")
      local HttpService = game:GetService("HttpService")

      local vars = _G.BotVars or {}
      local player = vars.LocalPlayer
      if not player then
          warn("[JoinServer] LocalPlayer tidak ditemukan!")
          return
      end

      -- Hanya tangani !joinserver
      if msg:lower() ~= "!joinserver" then return end

      -- Pastikan client valid
      if not client or not client.Character then
          warn("[JoinServer] Client/pemain tidak ditemukan!")
          return
      end

      -- Cek apakah sudah di server yang sama
      if game.JobId == client.JobId then
          print("[JoinServer] Sudah berada di server yang sama dengan pemain.")
          return
      end

      -- Ambil PlaceId
      local placeId = game.PlaceId

      -- Ambil daftar server publik
      local success, response = pcall(function()
          return HttpService:JSONDecode(
              HttpService:GetAsync(
                  "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
              )
          )
      end)

      if not success or not response or not response.data then
          warn("[JoinServer] Gagal mendapatkan daftar server.")
          return
      end

      -- Cari server yang sama dengan client
      local targetJobId
      for _, s in ipairs(response.data) do
          if s.id == client.JobId then
              targetJobId = s.id
              break
          end
      end

      if not targetJobId then
          warn("[JoinServer] Server pemain tidak ditemukan.")
          return
      end

      -- Teleport bot ke server pemain
      print("[JoinServer] Teleportasi ke server pemain...")
      TeleportService:TeleportToPlaceInstance(placeId, targetJobId, player)
  end
}
