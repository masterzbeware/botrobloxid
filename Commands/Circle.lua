-- Circle.lua (Bot mengelilingi VIP, formasi lingkaran)
return {
  Execute = function(msg, client)
      local vars = _G.BotVars or {}
      local RunService = vars.RunService or game:GetService("RunService")
      local Players = game:GetService("Players")
      local player = vars.LocalPlayer or Players.LocalPlayer

      -- Ambil argumen !circle {name}
      local args = {}
      for word in msg:gmatch("%S+") do table.insert(args, word) end
      local targetNameOrUsername = args[2]

      -- Cari pemain target
      local targetPlayer = nil
      if targetNameOrUsername then
          for _, plr in ipairs(Players:GetPlayers()) do
              if plr.Name:lower() == targetNameOrUsername:lower() or
                 (plr.DisplayName and plr.DisplayName:lower() == targetNameOrUsername:lower()) then
                  targetPlayer = plr
                  break
              end
          end
          if not targetPlayer then
              warn("[Circle] Pemain '" .. targetNameOrUsername .. "' tidak ditemukan.")
              return
          end
      else
          targetPlayer = client
      end

      -- Toggle mode
      vars.CircleActive = not vars.CircleActive
      vars.FollowAllowed = false
      vars.RowActive = false
      vars.ShieldActive = false
      vars.CurrentFormasiTarget = targetPlayer

      -- Disconnect loop lama
      if vars.CircleConnection then pcall(function() vars.CircleConnection:Disconnect() end) vars.CircleConnection = nil end

      if not vars.CircleActive then
          print("[Circle] Deactivated")
          return
      end

      -- Config
      local radius = tonumber(vars.CircleRadius) or 6
      local speed  = tonumber(vars.CircleSpeed) or 1 -- rotasi per detik

      -- Bot mapping
      local botMapping = vars.BotMapping or {
          ["8802945328"] = "Bot1",
          ["8802949363"] = "Bot2",
          ["8802939883"] = "Bot3",
          ["8802998147"] = "Bot4",
      }

      local botIds = {}
      for idStr, _ in pairs(botMapping) do
          local n = tonumber(idStr)
          if n then table.insert(botIds, n) end
      end
      table.sort(botIds)

      -- References
      local humanoid, myRootPart, moving
      local function updateBotRefs()
          local character = player.Character or player.CharacterAdded:Wait()
          humanoid = character:WaitForChild("Humanoid")
          myRootPart = character:WaitForChild("HumanoidRootPart")
      end
      player.CharacterAdded:Connect(updateBotRefs)
      updateBotRefs()

      local function moveToPosition(targetPos, lookAtPos)
          if not humanoid or not myRootPart then return end
          if moving then return end
          if (myRootPart.Position - targetPos).Magnitude < 0.5 then return end

          moving = true
          humanoid:MoveTo(targetPos)
          humanoid.MoveToFinished:Wait()
          moving = false

          if lookAtPos then
              myRootPart.CFrame = CFrame.new(myRootPart.Position, Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z))
          end
      end

      -- 🔹 Circle loop
      local startTime = tick()
      vars.CircleConnection = RunService.Heartbeat:Connect(function()
          if not vars.CircleActive or not vars.CurrentFormasiTarget or not vars.CurrentFormasiTarget.Character then return end
          if not humanoid or not myRootPart then return end

          local targetHRP = vars.CurrentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
          if not targetHRP then return end

          -- Index bot
          local index = 1
          for i, id in ipairs(botIds) do
              if id == player.UserId then index = i break end
          end

          -- Tentukan posisi mengelilingi VIP
          local totalBots = #botIds
          local angle = ((tick() - startTime) * speed + (index-1)/totalBots*math.pi*2) % (math.pi*2)
          local offset = Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
          local targetPos = targetHRP.Position + offset

          moveToPosition(targetPos, targetHRP.Position)
      end)

      print("[Circle] Activated around", vars.CurrentFormasiTarget.Name)
  end
}
