-- Commands/Diamond.lua
-- Admin-only follow system (DIAMOND + TWOLINE formation)

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
      local sideSpacing = 3

      ----------------------------------------------------------------
      -- UPDATE CHARACTER
      ----------------------------------------------------------------
      local function updateCharacter()
          local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
          humanoid = char:WaitForChild("Humanoid")
          myHRP = char:WaitForChild("HumanoidRootPart")
      end
      updateCharacter()
      LocalPlayer.CharacterAdded:Connect(updateCharacter)

      ----------------------------------------------------------------
      -- SEND CHAT
      ----------------------------------------------------------------
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

      ----------------------------------------------------------------
      -- STOP FOLLOW
      ----------------------------------------------------------------
      local function stopFollow()
          following = false
          targetPlayer = nil
          if followConnection then
              followConnection:Disconnect()
              followConnection = nil
          end
      end

      ----------------------------------------------------------------
      -- START DIAMOND FOLLOW
      ----------------------------------------------------------------
      local function startFollow(player)
          stopFollow()
          following = true
          targetPlayer = player
          sendChat("Yes, Sir!")

          local botOrder = {
              "10191476366", -- 1
              "10191480511", -- 2
              "10191462654", -- 3
              "10190853828", -- 4
              "10191023081", -- 5
              "10191070611", -- 6
              "10191489151", -- 7
              "10191571531", -- 8
              "10192469244", -- 9
              "10192474291", -- 10
              "10196485340", -- Bot11
              "10196526503", -- Bot12
          }

          local myIndex = table.find(botOrder, tostring(LocalPlayer.UserId))
          if not myIndex then return end

          followConnection = RunService.Heartbeat:Connect(function()
              if not following or not humanoid or not myHRP then return end
              if not targetPlayer.Character then return end

              local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
              if not hrp then return end

              -- DISTANCE
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

              local targetPosition

              -- =========================
              -- DIAMOND CORE
              -- =========================
              if myIndex == 1 then
                  -- FRONT
                  targetPosition = hrp.Position + hrp.CFrame.LookVector * distance

              elseif myIndex == 2 then
                  -- RIGHT
                  targetPosition = hrp.Position + hrp.CFrame.RightVector * sideSpacing

              elseif myIndex == 3 then
                  -- LEFT
                  targetPosition = hrp.Position - hrp.CFrame.RightVector * sideSpacing

              elseif myIndex == 4 then
                  -- BACK
                  targetPosition = hrp.Position - hrp.CFrame.LookVector * distance

              else
                  -- =========================
                  -- TWOLINE (BOT 5+)
                  -- =========================
                  local twolineIndex = myIndex - 4
                  local isLeft = twolineIndex % 2 == 1
                  local lineIndex = math.ceil(twolineIndex / 2)

                  local backOffset = hrp.CFrame.LookVector * -(distance * (lineIndex + 1))
                  local sideDir = isLeft and -hrp.CFrame.RightVector or hrp.CFrame.RightVector
                  local sideOffset = sideDir * sideSpacing

                  targetPosition = hrp.Position + backOffset + sideOffset
              end

              humanoid:MoveTo(targetPosition)
          end)
      end

      ----------------------------------------------------------------
      -- COMMAND HANDLER
      ----------------------------------------------------------------
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
