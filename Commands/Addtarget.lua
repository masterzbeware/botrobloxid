-- Addtarget.lua
-- Command !addtarget {DisplayName/Username}: Menambahkan pemain ke whitelist agar Shield.lua tidak memberi peringatan
return {
  Execute = function(msg, client)
      local Players = game:GetService("Players")
      local vars = _G.BotVars or {}
      vars.WhitelistTargets = vars.WhitelistTargets or {} -- pastikan selalu ada

      -- Ambil argumen dari perintah !addtarget
      local args = {}
      for word in msg:gmatch("%S+") do table.insert(args, word) end
      local targetNameOrUsername = args[2] -- !addtarget {name}

      if not targetNameOrUsername then
          warn("[Addtarget] Mohon masukkan DisplayName atau Username target.")
          return
      end

      -- Cari pemain target berdasarkan DisplayName atau Username
      local targetPlayer = nil
      for _, plr in ipairs(Players:GetPlayers()) do
          if plr.Name:lower() == targetNameOrUsername:lower() or (plr.DisplayName and plr.DisplayName:lower() == targetNameOrUsername:lower()) then
              targetPlayer = plr
              break
          end
      end

      if not targetPlayer then
          warn("[Addtarget] Pemain '" .. targetNameOrUsername .. "' tidak ditemukan.")
          return
      end

      -- Tambahkan ke whitelist
      local userIdStr = tostring(targetPlayer.UserId)
      if not vars.WhitelistTargets[userIdStr] then
          vars.WhitelistTargets[userIdStr] = true
          print("[Addtarget] Pemain " .. targetPlayer.Name .. " telah ditambahkan ke whitelist.")
      else
          print("[Addtarget] Pemain " .. targetPlayer.Name .. " sudah ada di whitelist.")
      end

      -- 🔹 Opsional: notifikasi ke client jika Library tersedia
      if vars.Library then
          vars.Library:Notify("Whitelist updated: " .. targetPlayer.Name, 3)
      end
  end
}
