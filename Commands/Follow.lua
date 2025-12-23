-- Follow.lua
-- Ketik !follow untuk diikuti bot

return {
  Execute = function()
      local Players = game:GetService("Players")
      local RunService = game:GetService("RunService")

      local LocalPlayer = Players.LocalPlayer
      if not LocalPlayer then return end

      local following = false
      local targetPlayer = nil
      local followConnection

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

          followConnection = RunService.Heartbeat:Connect(function()
              if not following then return end
              if not LocalPlayer.Character or not targetPlayer.Character then return end

              local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
              local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
              local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

              if myHRP and targetHRP and humanoid then
                  humanoid:MoveTo(targetHRP.Position)
              end
          end)
      end

      -- Listen chat player lain
      for _, player in ipairs(Players:GetPlayers()) do
          player.Chatted:Connect(function(msg)
              if msg:lower() == "!follow" then
                  startFollow(player)
              elseif msg:lower() == "!unfollow" then
                  stopFollow()
              end
          end)
      end

      -- Player join baru
      Players.PlayerAdded:Connect(function(player)
          player.Chatted:Connect(function(msg)
              if msg:lower() == "!follow" then
                  startFollow(player)
              elseif msg:lower() == "!unfollow" then
                  stopFollow()
              end
          end)
      end)
  end
}
