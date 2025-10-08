return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local Players = vars.Players or game:GetService("Players")
      local mainClientName = "FiestaGuardVip"
      local activeClient = vars.ActiveClient or mainClientName

      if msg:lower():match("^!remove$") then
          -- Hanya client utama yang bisa menghapus client
          if client.Name ~= mainClientName then
              return
          end

          -- Jika active client bukan client utama, reset ke client utama
          if activeClient ~= mainClientName then
              vars.ActiveClient = mainClientName
          end
      end
  end
}
