-- Commands/Pushup.lua
-- Pushup command with safe Admin loader (anti 404 crash)

return {
  Execute = function(msg, client)

      -- SERVICES
      local Players = game:GetService("Players")
      local TextChatService = game:GetService("TextChatService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")

      local LocalPlayer = Players.LocalPlayer
      if not LocalPlayer then return end

      ----------------------------------------------------------------
      -- SAFE ADMIN MODULE LOADER
      ----------------------------------------------------------------
      local function safeLoadAdmin(url)
          local ok, result = pcall(function()
              local source = game:HttpGet(url)
              if not source or source:find("404") then
                  error("HTTP 404 or empty response")
              end
              return loadstring(source)()
          end)

          if not ok then
              warn("[ADMIN MODULE LOAD FAILED]", result)
              return nil
          end

          return result
      end

      local Admin = safeLoadAdmin(
          "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
      )

      if not Admin then
          warn("Admin.lua gagal dimuat, Pushup dibatalkan")
          return
      end

      ----------------------------------------------------------------
      -- ADMIN CHECK
      ----------------------------------------------------------------
      if not Admin:IsAdmin(client) then
          return
      end

      ----------------------------------------------------------------
      -- GLOBAL BOT VARS
      ----------------------------------------------------------------
      _G.BotVars = _G.BotVars or {}
      local vars = _G.BotVars

      ----------------------------------------------------------------
      -- CHAT CHANNEL
      ----------------------------------------------------------------
      local channel
      if TextChatService.TextChannels then
          channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
      end

      local function sendChat(text)
          if channel then
              pcall(function()
                  channel:SendAsync(text)
              end)
          end
      end

      ----------------------------------------------------------------
      -- STOP PUSHUP JIKA MASIH AKTIF
      ----------------------------------------------------------------
      if vars.PushupActive then
          vars.PushupActive = false
          if vars.PushupConnection then
              task.cancel(vars.PushupConnection)
              vars.PushupConnection = nil
          end
      end

      vars.PushupActive = true

      ----------------------------------------------------------------
      -- JUMLAH PUSHUP
      ----------------------------------------------------------------
      local jumlah = tonumber(msg:match("!pushup%s+(%d+)")) or 3

      ----------------------------------------------------------------
      -- MAIN TASK
      ----------------------------------------------------------------
      vars.PushupConnection = task.spawn(function()

          sendChat("Siap laksanakan!")
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
                  sendChat(i .. " push up, Komandan!")
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
