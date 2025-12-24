-- Commands/Twoline.lua
-- Admin-only follow system (TWO LINE formation: left & right)

return {
  Execute = function()
      local Players = game:GetService("Players")
      local RunService = game:GetService("RunService")
      local TextChatService = game:GetService("TextChatService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")

      local LocalPlayer = Players.LocalPlayer
      if not LocalPlayer then return end

      -- LOAD ADMIN MODULE
      local Admin = loadstring(game:HttpGet(
          "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
      ))()

      -- LOAD DISTANCE MODULE
      local Distance = loadstring(game:HttpGet(
          "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
      ))()

      local humanoid, myHRP
      local following = false
      local targetPlayer
      local followConnection

      local adminFollowDistance = 3
      local defaultBotFollowDistance = 2
      local sideSpacing = 2.5 -- jarak kiri / kanan

      -- UPDATE CHARACTER
      local function updateCharacter()
          local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
          humanoid = char:WaitForChild("Humanoid")
          myHRP = char:WaitForChild("HumanoidRootPart")
      end
      updateCharacter()
      LocalPlayer.CharacterAdded:Connect(updateCharacter)

      -- SEND CHAT
      local function sendChat(msg)
          local ok = false
          if TextChatService and TextChatService.TextChannels then
              local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
              if ch then
                  pcall(function()
                      ch:SendAsync(msg)
                  end)
                  ok = true
              end
          end
          if not ok then
              pcall(function()
                  ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
                      :FireServer(msg, "All")
              end)
          end
      end

      -- STOP FOLLOW
      local function stopFollow()
          following = false
          targetPlayer = nil
          if followConnection then
              followConnection:Disconnect()
              followConnection = nil
          end
      end

      -- START TWOLINE FOLLOW
      local function startFollow(player)
          stopFollow()
          following = true
          targetPlayer = player
          sendChat("Two line formation, Sir!")

          -- BOT ORDER (FIXED)
          local botOrder = {
              "10191476366",
              "10191480511",
              "10191462654",
              "10190853828",
              "10191023081",
              "10191070611",
              "10191489151",
              "10191571531",
              "10192469244",
              "10192474291",
          }

          local myIndex = table.find(botOrder, tostring(LocalPlayer.UserId))
          if not myIndex then return end

          -- FORMATION INDEX
          local isLeft = myIndex <= math.ceil(#botOrder / 2)
          local lineIndex = isLeft and myIndex or (myIndex - math.ceil(#botOrder / 2))

          followConnection = RunService.Heartbeat:Connect(function()
              if not following or not humanoid or not myHRP then return end
              if not targetPlayer.Character then return end

              local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
              if not hrp then return end

              -- FOLLOW DISTANCE
              local distance = defaultBotFollowDistance
              if Admin:IsAdmin(targetPlayer) then
                  distance = adminFollowDistance
              end

              local special = Distance:GetDistance(
                  tostring(LocalPlayer.UserId),
                  tostring(targetPlayer.UserId)
              )
              if special then
                  distance = special
              end

              -- BASE BACK OFFSET
              local backOffset = hrp.CFrame.LookVector * -(distance * lineIndex)

              -- LEFT / RIGHT OFFSET
              local sideDir = isLeft and -hrp.CFrame.RightVector or hrp.CFrame.RightVector
              local sideOffset = sideDir * sideSpacing

              local targetPosition = hrp.Position + backOffset + sideOffset

              humanoid:MoveTo(targetPosition)
          end)
      end

      -- COMMAND HANDLER
      local function handleCommand(msg, sender)
          msg = msg:lower()
          if Admin:IsAdmin(sender) then
              if msg == "!twoline" then
                  startFollow(sender)
              elseif msg == "!stop" or msg == "!unfollow" then
                  stopFollow()
              end
          end
      end

      -- TEXT CHAT SERVICE
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

      -- FALLBACK CHAT
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
