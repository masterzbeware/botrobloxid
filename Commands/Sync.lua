-- Commands/Sync.lua
-- Bot otomatis sync ke admin ketika admin mengetik !sync
return {
  Execute = function()
      local Players = game:GetService("Players")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local TextChatService = game:GetService("TextChatService")

      local LocalPlayer = Players.LocalPlayer
      if not LocalPlayer then return end

      -- 🔗 Load Admin module
      local Admin = loadstring(game:HttpGet(
          "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
      ))()

      local function syncToAdmin(adminPlayer)
          local success, err = pcall(function()
              local commandHandler = ReplicatedStorage:WaitForChild("Connections")
                  :WaitForChild("dataProviders")
                  :WaitForChild("commandHandler")
              commandHandler:InvokeServer("sync", adminPlayer.UserId)
          end)
          if not success then
              warn("Gagal sync ke admin: "..tostring(err))
          end
      end

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

      -- Handle chat commands dari admin
      local function handleCommand(msg, sender)
          if not Admin:IsAdmin(sender) then return end
          msg = msg:lower()
          if msg == "!sync" then
              syncToAdmin(sender)
          elseif msg == "!leavesync" then
              leaveSync()
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
