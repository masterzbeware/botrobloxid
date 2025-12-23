-- Commands/Diamond.lua
-- Admin-only follow system with bots forming a Diamond formation behind Admin

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
      local adminFollowDistance = 3 -- jarak mengikuti Admin
      local defaultBotFollowDistance = 2 -- jarak default antar bot

      -- Update references
      local function updateCharacter()
          local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
          humanoid = char:WaitForChild("Humanoid")
          myHRP = char:WaitForChild("HumanoidRootPart")
      end

      updateCharacter()
      LocalPlayer.CharacterAdded:Connect(updateCharacter)

      -- Fungsi kirim chat satu kali
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

      -- Stop following
      local function stopFollow()
          following = false
          targetPlayer = nil
          if followConnection then
              followConnection:Disconnect()
              followConnection = nil
          end
      end

      -- Diamond Formation offsets
      local function getDiamondOffset(index)
          -- Diamond pattern:
          --      2
          --    1   3
          --  0       4
          --       5
          local distance = defaultBotFollowDistance
          local offsets = {
              Vector3.new(0, 0, 2),
              Vector3.new(-1, 0, 1),
              Vector3.new(1, 0, 1),
              Vector3.new(-2, 0, 0),
              Vector3.new(2, 0, 0),
              Vector3.new(0, 0, -1),
          }
          return offsets[index] or Vector3.new(0,0,0)
      end

      -- Start following target in Diamond
      local function startFollow(player)
          stopFollow()
          targetPlayer = player
          following = true

          sendChat("Siap, formasi Diamond!")

          followConnection = RunService.Heartbeat:Connect(function()
              if not following or not humanoid or not myHRP then return end
              if not targetPlayer.Character then return end

              local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
              if hrp then
                  local distance = defaultBotFollowDistance

                  -- Admin jarak
                  if Admin:IsAdmin(targetPlayer) then
                      distance = adminFollowDistance
                  end

                  -- Pasangan bot jarak khusus
                  local specialDistance = Distance:GetDistance(tostring(LocalPlayer.UserId), tostring(targetPlayer.UserId))
                  if specialDistance then
                      distance = specialDistance
                  end

                  -- Bot order
                  local botOrder = {
                      "10191476366", -- Bot1
                      "10191480511", -- Bot2
                      "10191462654", -- Bot3
                      "10190853828", -- Bot4
                      "10191023081", -- Bot5
                      "10191070611", -- Bot6
                  }

                  local myIndex = table.find(botOrder, tostring(LocalPlayer.UserId)) or 1
                  local offset = getDiamondOffset(myIndex)

                  -- Rotate offset sesuai arah Admin
                  local cf = hrp.CFrame
                  local targetPosition = hrp.Position + cf.RightVector * offset.X + cf.UpVector * offset.Y - cf.LookVector * offset.Z

                  humanoid:MoveTo(targetPosition)
              end
          end)
      end

      -- Handle chat commands
      local function handleCommand(msg, sender)
          msg = msg:lower()
          if Admin:IsAdmin(sender) then
              if msg == "!diamond" then
                  startFollow(sender)
              elseif msg == "!stop" or msg == "!undiamond" then
                  stopFollow()
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
