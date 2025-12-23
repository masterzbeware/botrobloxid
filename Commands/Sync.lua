-- Commands/Sync.lua
-- Admin-only sync system
return {
  Execute = function()
      local Players = game:GetService("Players")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local TextChatService = game:GetService("TextChatService")

      local LocalPlayer = Players.LocalPlayer
      if not LocalPlayer then return end

      -- 🔗 LOAD ADMIN MODULE
      local Admin = loadstring(game:HttpGet(
          "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
      ))()

      -- Fungsi untuk mengirim sync
      local function sendSyncCommand(userId)
          local success, err = pcall(function()
              local commandHandler = ReplicatedStorage:WaitForChild("Connections")
                  :WaitForChild("dataProviders")
                  :WaitForChild("commandHandler")

              -- Kirim perintah sync ke UserId
              commandHandler:InvokeServer("sync", userId)
          end)
          if not success then
              warn("Gagal melakukan sync: "..tostring(err))
          end
      end

      -- Fungsi untuk keluar dari sync
      local function leaveSync()
          local success, err = pcall(function()
              local animationHandler = ReplicatedStorage:WaitForChild("Connections")
                  :WaitForChild("dataProviders")
                  :WaitForChild("animationHandler")

              animationHandler:InvokeServer("leaveSync")
          end)
          if not success then
              warn("Gagal keluar dari sync: "..tostring(err))
          end
      end

      -- Handle chat commands
      local function handleCommand(msg, sender)
          msg = msg:lower()
          if Admin:IsAdmin(sender) then
              if msg:sub(1,5) == "!sync" then
                  local targetName = msg:sub(7) -- ambil string setelah !sync 
                  if targetName and targetName ~= "" then
                      -- Cari player dengan username atau displayname
                      local targetPlayer
                      for _, p in ipairs(Players:GetPlayers()) do
                          if p.Name:lower() == targetName:lower() or (p.DisplayName and p.DisplayName:lower() == targetName:lower()) then
                              targetPlayer = p
                              break
                          end
                      end

                      if targetPlayer then
                          sendSyncCommand(targetPlayer.UserId)
                      else
                          warn("Player '"..targetName.."' tidak ditemukan")
                      end
                  end
              elseif msg == "!leavesync" then
                  leaveSync()
              end
          end
      end

      -- TextChatService listener
      if TextChatService and TextChatService.TextChannels then
          local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
          if channel then
              channel.OnIncomingMessage = function(message)
                  local userId = message.TextSource and message.TextSource.UserId
                  local sender = userId and Players:GetPlayerByUserId(userId)
                  if sender then
                      handleCommand(message.Text, sender)
                  end
              end
          end
      end

      -- Fallback lama
      for _, player in ipairs(Players:GetPlayers()) do
          player.Chatted:Connect(function(msg)
              handleCommand(msg, player)
          end)
      end

      Players.PlayerAdded:Connect(function(player)
          player.Chatted:Connect(function(msg)
              handleCommand(msg, player)
          end)
      end)
  end
}
