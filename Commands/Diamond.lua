-- Commands/Diamond.lua
-- Admin-only follow system with bots in diamond formation around Admin

return {
  Execute = function()
      local Players = game:GetService("Players")
      local RunService = game:GetService("RunService")
      local TextChatService = game:GetService("TextChatService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")

      local LocalPlayer = Players.LocalPlayer
      if not LocalPlayer then return end

      -- 🔗 LOAD ADMIN MODULE
      local Admin = loadstring(game:HttpGet(
          "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
      ))()

      -- 🔗 LOAD DISTANCE MODULE
      local Distance = loadstring(game:HttpGet(
          "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
      ))()

      local following = false
      local targetPlayer
      local followConnection

      local humanoid
      local myHRP
      local defaultBotDistance = 3 -- jarak formasi

      local function updateCharacter()
          local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
          humanoid = char:WaitForChild("Humanoid")
          myHRP = char:WaitForChild("HumanoidRootPart")
      end

      updateCharacter()
      LocalPlayer.CharacterAdded:Connect(updateCharacter)

      local function sendChat(msg)
          local sent = false
          if TextChatService and TextChatService.TextChannels then
              local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
              if channel then
                  pcall(function()
                      channel:SendAsync(msg)
                  end)
                  sent = true
              end
          end
          if not sent then
              pcall(function()
                  ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
              end)
          end
      end

      local function stopFollow()
          following = false
          targetPlayer = nil
          if followConnection then
              followConnection:Disconnect()
              followConnection = nil
          end
      end

      local function startFollow(player)
          stopFollow()
          targetPlayer = player
          following = true

          sendChat("Siap, Laksanakan!")

          followConnection = RunService.Heartbeat:Connect(function()
              if not following or not humanoid or not myHRP then return end
              if not targetPlayer.Character then return end

              local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
              if hrp then
                  -- Formasi diamond simetris
                  local botOrder = {
                      ["10191462654"] = Vector3.new(-defaultBotDistance, 0, defaultBotDistance),  -- Bot3 kiri depan
                      ["10191476366"] = Vector3.new(0, 0, defaultBotDistance),                     -- Bot1 depan VIP
                      ["10191480511"] = Vector3.new(defaultBotDistance, 0, defaultBotDistance),    -- Bot2 kanan depan
                      ["10190853828"] = Vector3.new(-defaultBotDistance, 0, 0),                    -- Bot4 kiri VIP
                      ["10191023081"] = Vector3.new(defaultBotDistance, 0, 0),                     -- Bot5 kanan VIP
                      ["10191070611"] = Vector3.new(0, 0, -defaultBotDistance)                     -- Bot6 tepat belakang VIP
                  }

                  local myOffset = botOrder[tostring(LocalPlayer.UserId)] or Vector3.new(0,0,-defaultBotDistance)
                  local targetCFrame = hrp.CFrame
                  local targetPosition = targetCFrame.Position + targetCFrame.RightVector * myOffset.X + targetCFrame.LookVector * myOffset.Z
                  humanoid:MoveTo(targetPosition)
              end
          end)
      end

      local function handleCommand(msg, sender)
          msg = msg:lower()
          if Admin:IsAdmin(sender) then
              if msg == "!diamond" then
                  startFollow(sender)
              elseif msg == "!stop" or msg == "!unfollow" then
                  stopFollow()
              end
          end
      end

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
