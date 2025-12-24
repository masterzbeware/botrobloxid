-- Commands/Pushup.lua

return {
  Execute = function(msg, client)

      -- SERVICES
      local Players = game:GetService("Players")
      local TextChatService = game:GetService("TextChatService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")

      local LocalPlayer = Players.LocalPlayer
      if not LocalPlayer then return end

      -- 🔗 LOAD ADMIN MODULE
      local Admin = loadstring(game:HttpGet(
          "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
      ))()

      -- 🔗 LOAD DISTANCE MODULE (tidak dipakai, tapi konsisten)
      local Distance = loadstring(game:HttpGet(
          "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
      ))()

      -- ADMIN CHECK
      if not Admin:IsAdmin(client) then
          return
      end

      -- GLOBAL VARS
      _G.BotVars = _G.BotVars or {}
      local vars = _G.BotVars

      local channel
      if TextChatService.TextChannels then
          channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
      end

      -- STOP JIKA MASIH PUSHUP
      if vars.PushupActive then
          vars.PushupActive = false
          if vars.PushupConnection then
              task.cancel(vars.PushupConnection)
              vars.PushupConnection = nil
          end
      end

      vars.PushupActive = true

      -- CHAT FUNCTION
      local function sendChat(text)
          if channel then
              pcall(function()
                  channel:SendAsync(text)
              end)
          end
      end

      -- JUMLAH PUSH UP
      local jumlah = tonumber(msg:match("!pushup%s+(%d+)")) or 3

      vars.PushupConnection = task.spawn(function()

          sendChat("Yes, Sir!")
          task.wait(2)
          if not vars.PushupActive then return end

          -- PLAY ANIMATION
          pcall(function()
              ReplicatedStorage
                  :WaitForChild("Connections")
                  :WaitForChild("dataProviders")
                  :WaitForChild("animationHandler")
                  :InvokeServer("playAnimation", "Push Up")
          end)

          for i = 1, jumlah do
              task.wait(5)
              if not vars.PushupActive then break end

              if i == jumlah then
                  sendChat(i .. " push up, Yes, Sir!")
              else
                  sendChat(i .. " push up!")
              end
          end

          -- STOP ANIMATION
          pcall(function()
              ReplicatedStorage
                  :WaitForChild("Connections")
                  :WaitForChild("dataProviders")
                  :WaitForChild("animationHandler")
                  :InvokeServer("stopAnimation", "Push Up")
          end)

          vars.PushupActive = false
          vars.PushupConnection = nil
      end)
  end
}
