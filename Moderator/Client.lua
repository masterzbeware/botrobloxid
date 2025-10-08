return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local Players = vars.Players or game:GetService("Players")
      local TextChatService = vars.TextChatService or game:GetService("TextChatService")

      local mainClientName = "FiestaGuardVip"
      local secondaryClientName = "Client2"
      local activeClient = vars.ActiveClient or mainClientName
      local commandFiles = vars.CommandFiles or {}

      local function sendChat(text)
          local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
          if channel then
              pcall(function()
                  channel:SendAsync(text)
              end)
          end
      end

      local function sendWhisper(targetPlayer, text)
          if targetPlayer then
              sendChat("/whisper " .. targetPlayer.Name .. " " .. text)
          end
      end

      if msg:lower():match("^!client%s+") then
          local targetName = msg:match("^!client%s+(.+)")
          if client.Name == mainClientName then
              local targetPlayer = nil
              for _, plr in ipairs(Players:GetPlayers()) do
                  if plr.DisplayName:lower() == targetName:lower() or plr.Name:lower() == targetName:lower() then
                      targetPlayer = plr
                      break
                  end
              end

              if targetPlayer then
                  _G.BotVars.ActiveClient = targetPlayer.Name
                  sendWhisper(targetPlayer, targetPlayer.Name .. " sekarang menjadi Client aktif.")
                  local mainClient = Players:FindFirstChild(mainClientName)
                  if mainClient then
                      sendWhisper(mainClient, targetPlayer.Name .. " sekarang menjadi Client aktif.")
                  end
                  local secondClient = Players:FindFirstChild(secondaryClientName)
                  if secondClient then
                      sendWhisper(secondClient, targetPlayer.Name .. " sekarang menjadi Client aktif.")
                  end
              else
                  local mainClient = Players:FindFirstChild(mainClientName)
                  if mainClient then
                      sendWhisper(mainClient, "Player " .. targetName .. " tidak ditemukan.")
                  end
              end
          else
              local mainClient = Players:FindFirstChild(mainClientName)
              if mainClient then
                  sendWhisper(mainClient, "Hanya " .. mainClientName .. " yang dapat mengganti Client aktif.")
              end
              local secondClient = Players:FindFirstChild(secondaryClientName)
              if secondClient then
                  sendWhisper(secondClient, "Hanya " .. mainClientName .. " yang dapat mengganti Client aktif.")
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
