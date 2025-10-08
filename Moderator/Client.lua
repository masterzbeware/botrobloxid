return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local Players = vars.Players or game:GetService("Players")
      local commandFiles = vars.CommandFiles or {}
      local mainClientName = "FiestaGuardVip"
      local activeClient = vars.ActiveClient or mainClientName

      if msg:lower():match("^!client%s+") then
          local targetName = msg:match("^!client%s+(.+)")
          if client.Name == mainClientName and targetName then
              local targetPlayer = nil
              for _, plr in ipairs(Players:GetPlayers()) do
                  if plr.DisplayName:lower() == targetName:lower() or plr.Name:lower() == targetName:lower() then
                      targetPlayer = plr
                      break
                  end
              end

              if targetPlayer then
                  _G.BotVars.ActiveClient = targetPlayer.Name
              end
          end
          return
      end

      if client.Name == activeClient then
          local lowerMsg = msg:lower()
          for name, cmd in pairs(commandFiles) do
              if lowerMsg:match("^!" .. name) and cmd.Execute then
                  local success, err = pcall(function()
                      cmd.Execute(msg, client)
                  end)
                  if not success then
                      warn("Gagal menjalankan command " .. name .. ": " .. tostring(err))
                  end
              end
          end
      end
  end
}
