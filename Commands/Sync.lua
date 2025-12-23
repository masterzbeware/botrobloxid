-- Commands/Sync.lua
-- Bot otomatis sync ke admin ketika admin mengetik !sync
-- Dengan debugging
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
          print("[DEBUG] Menerima command sync dari admin:", adminPlayer.Name, "UserId:", adminPlayer.UserId)
          local success, err = pcall(function()
              local commandHandler = ReplicatedStorage:WaitForChild("Connections")
                  :WaitForChild("dataProviders")
                  :WaitForChild("commandHandler")
              commandHandler:InvokeServer("sync", adminPlayer.UserId)
          end)
          if success then
              print("[DEBUG] Sync berhasil dijalankan ke admin:", adminPlayer.Name)
          else
              warn("[DEBUG] Gagal sync ke admin:", err)
          end
      end

      -- Handle chat commands dari admin
      local function handleCommand(msg, sender)
          if not Admin:IsAdmin(sender) then 
              print("[DEBUG] Player bukan admin, abaikan command:", sender.Name)
              return 
          end
          msg = msg:lower()
          if msg == "!sync" then
              syncToAdmin(sender)
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
                      print("[DEBUG] Pesan diterima:", message.Text, "dari:", sender.Name)
                      handleCommand(message.Text, sender)
                  end
              end
          end
      end

      -- Fallback lama
      for _, player in ipairs(Players:GetPlayers()) do
          player.Chatted:Connect(function(msg)
              print("[DEBUG] Pesan chat lama diterima:", msg, "dari:", player.Name)
              handleCommand(msg, player)
          end)
      end

      Players.PlayerAdded:Connect(function(player)
          player.Chatted:Connect(function(msg)
              print("[DEBUG] Player baru chat diterima:", msg, "dari:", player.Name)
              handleCommand(msg, player)
          end)
      end)
  end
}
