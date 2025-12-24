-- Commands/Sync.lua
-- Admin-only sync command (chat based, uses commandHandler sync)

return {
  Execute = function()

      -- =========================
      -- SERVICES
      -- =========================
      local Players = game:GetService("Players")
      local TextChatService = game:GetService("TextChatService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")

      local LocalPlayer = Players.LocalPlayer
      if not LocalPlayer then return end

      -- =========================
      -- LOAD ADMIN MODULE
      -- =========================
      local Admin = loadstring(game:HttpGet(
          "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
      ))()

      -- =========================
      -- GLOBAL BOT VARS
      -- =========================
      _G.BotVars = _G.BotVars or {}
      local vars = _G.BotVars

      vars.SyncActive = false

      -- =========================
      -- CHAT SEND
      -- =========================
      local function sendChat(text)
          if not text then return end

          if TextChatService and TextChatService.TextChannels then
              local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
              if ch then
                  pcall(function()
                      ch:SendAsync(text)
                  end)
                  return
              end
          end

          pcall(function()
              ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
                  :FireServer(text, "All")
          end)
      end

      -- =========================
      -- SYNC CALL
      -- =========================
      local function runSync()
          pcall(function()
              local args = {
                  "sync",
                  8393332524
              }

              ReplicatedStorage
                  :WaitForChild("Connections")
                  :WaitForChild("dataProviders")
                  :WaitForChild("commandHandler")
                  :InvokeServer(unpack(args))
          end)
      end

      -- =========================
      -- COMMAND HANDLER
      -- =========================
      local function handleCommand(msg, sender)
          msg = msg:lower()

          if not Admin:IsAdmin(sender) then
              return
          end

          if msg == "!sync" then
              if vars.SyncActive then
                  return
              end

              vars.SyncActive = true
              sendChat("Sync dimulai, Komandan.")
              runSync()
              vars.SyncActive = false
          end
      end

      -- =========================
      -- CHAT LISTENER (SINGLE SOURCE)
      -- =========================
      if TextChatService and TextChatService.TextChannels then
          local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
          if ch then
              ch.OnIncomingMessage = function(message)
                  local uid = message.TextSource and message.TextSource.UserId
                  local sender = uid and Players:GetPlayerByUserId(uid)
                  if sender then
                      handleCommand(message.Text, sender)
                  end
              end
          end
      else
          -- FALLBACK ONLY IF TextChatService NOT AVAILABLE
          for _, p in ipairs(Players:GetPlayers()) do
              p.Chatted:Connect(function(msg)
                  handleCommand(msg, p)
              end)
          end

          Players.PlayerAdded:Connect(function(p)
              p.Chatted:Connect(function(msg)
                  handleCommand(msg, p)
              end)
          end)
      end
  end
}
