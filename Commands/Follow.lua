-- Follow.lua
-- Command !follow hanya bisa dijalankan oleh UserId tertentu

return {
  Execute = function()
      local Players = game:GetService("Players")
      local RunService = game:GetService("RunService")

      local LocalPlayer = Players.LocalPlayer
      if not LocalPlayer then return end

      -- 🔐 USERID YANG DIIZINKAN
      local ALLOWED_USERID = 10190678566

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

      -- 🔎 Validasi command
      local function handleChat(player, msg)
          -- ❌ bukan user yang diizinkan
          if player.UserId ~= ALLOWED_USERID then
              return
          end

          msg = msg:lower()

          if msg == "!follow" then
              startFollow(player)
          elseif msg == "!unfollow" then
              stopFollow()
          end
      end

      -- Player existing
      for _, player in ipairs(Players:GetPlayers()) do
          player.Chatted:Connect(function(msg)
              handleChat(player, msg)
          end)
      end

      -- Player baru join
      Players.PlayerAdded:Connect(function(player)
          player.Chatted:Connect(function(msg)
              handleChat(player, msg)
          end)
      end)
  end
}
