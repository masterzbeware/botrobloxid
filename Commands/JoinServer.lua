-- JoinServer.lua
-- Command: !joinserver <displayname/username>
-- Bot akan teleport ke server yang sama dengan pemain target

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

      -- Parsing command: !joinserver <name>
      local targetName = msg:match("^!joinserver%s+(.+)")
      if not targetName then
          warn("[JoinServer] Harap masukkan displayname atau username target.")
          return
      end

      -- Cari pemain berdasarkan DisplayName atau Name
      local targetPlayer
      for _, plr in ipairs(Players:GetPlayers()) do
          if plr.DisplayName:lower() == targetName:lower() or plr.Name:lower() == targetName:lower() then
              targetPlayer = plr
              break
          end
      end

      if not targetPlayer then
          warn("[JoinServer] Pemain '"..targetName.."' tidak ditemukan di server ini.")
          return
      end

      -- Cek apakah sudah di server yang sama
      if game.JobId == targetPlayer.JobId then
          print("[JoinServer] Sudah berada di server yang sama dengan "..targetPlayer.Name)
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

      -- Cari server yang sama dengan targetPlayer
      local targetJobId
      for _, s in ipairs(response.data) do
          if s.id == targetPlayer.JobId then
              targetJobId = s.id
              break
          end
      end

      if not targetJobId then
          warn("[JoinServer] Server pemain tidak ditemukan.")
          return
      end

      -- Teleport bot ke server pemain
      print("[JoinServer] Teleportasi ke server "..targetPlayer.Name.." ...")
      TeleportService:TeleportToPlaceInstance(placeId, targetJobId, player)
  end
}
