-- Commands/Vote.lua
-- Admin-only vote skip (ONE TIME per bot)

return {
  Execute = function()
      -- SERVICES
      local Players = game:GetService("Players")
      local TextChatService = game:GetService("TextChatService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")

      local LocalPlayer = Players.LocalPlayer
      if not LocalPlayer then return end

      -- LOAD ADMIN MODULE
      local Admin = loadstring(game:HttpGet(
          "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
      ))()

      ----------------------------------------------------------------
      -- REMOTE
      ----------------------------------------------------------------
      local musicInfo =
          ReplicatedStorage
              :WaitForChild("Connections")
              :WaitForChild("dataProviders")
              :WaitForChild("musicInfo")

      ----------------------------------------------------------------
      -- STATE (ANTI SPAM)
      ----------------------------------------------------------------
      local hasVoted = false

      ----------------------------------------------------------------
      -- VOTE FUNCTION
      ----------------------------------------------------------------
      local function voteSkip()
          if hasVoted then return end
          hasVoted = true

          pcall(function()
              musicInfo:InvokeServer("voteSkip")
          end)
      end

      ----------------------------------------------------------------
      -- COMMAND HANDLER
      ----------------------------------------------------------------
      local function handleCommand(msg, sender)
          msg = msg:lower()

          if not Admin:IsAdmin(sender) then
              return
          end

          if msg == "!vote" then
              voteSkip()
          end
      end

      ----------------------------------------------------------------
      -- TEXT CHAT SERVICE
      ----------------------------------------------------------------
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
      end

      ----------------------------------------------------------------
      -- FALLBACK CHAT
      ----------------------------------------------------------------
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
}
