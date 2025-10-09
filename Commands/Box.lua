-- Box.lua
-- Command !box: Bot membentuk formasi Box di sekitar target (VIP di tengah)

return {
  Execute = function(msg, client)
      local vars = _G.BotVars
      local RunService = vars.RunService
      local player = vars.LocalPlayer

      if not RunService then
          warn("[BOX] RunService tidak tersedia!")
          return
      end

      -- Toggle mode Box
      vars.BoxActive = not vars.BoxActive
      vars.FollowAllowed = false
      vars.RowActive = false
      vars.WedgeActive = false
      vars.ShieldActive = false
      vars.FrontlineActive = false
      vars.CircleMoveActive = false
      vars.PushupActive = false
      vars.SyncActive = false
      vars.ReportingActive = false
      vars.RoomVIPActive = false

      -- Tentukan target
      local target
      local args = {}
      for word in msg:gmatch("%S+") do
          table.insert(args, word)
      end

      if #args > 1 then
          local searchName = table.concat(args, " ", 2)
          for _, plr in ipairs(game.Players:GetPlayers()) do
              if plr.DisplayName:lower():find(searchName:lower()) or plr.Name:lower():find(searchName:lower()) then
                  target = plr
                  break
              end
          end
          if not target then
              print("[BOX] Target tidak ditemukan. Menggunakan client sebagai target.")
              target = client
          end
      else
          target = client
      end

      vars.CurrentFormasiTarget = target

      if not vars.BoxActive then
          print("[BOX] Dinonaktifkan")
          if vars.BoxConnection then
              pcall(function() vars.BoxConnection:Disconnect() end)
              vars.BoxConnection = nil
          end
          return
      end

      print("[BOX] Formasi Box diaktifkan. Target:", target.Name)

      -- Referensi karakter bot
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
          if (myRootPart.Position - targetPos).Magnitude < 1 then return end

          moving = true
          humanoid:MoveTo(targetPos)
          humanoid.MoveToFinished:Wait()
          moving = false

          if lookAtPos then
              myRootPart.CFrame = CFrame.new(
                  myRootPart.Position,
                  Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z)
              )
          end
      end

      if vars.BoxConnection then
          pcall(function() vars.BoxConnection:Disconnect() end)
          vars.BoxConnection = nil
      end

      if RunService.Heartbeat then
          vars.BoxConnection = RunService.Heartbeat:Connect(function()
              if not vars.BoxActive or not target.Character then return end
              local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
              if not targetHRP then return end

              -- Urutan bot
              local orderedBots = {
                  "8802945328", -- G1 kiri VIP
                  "8802949363", -- G2 depan kiri
                  "8802939883", -- G3 depan kanan
                  "8802998147", -- G4 kanan VIP
                  "8802991722", -- G5 belakang VIP
              }

              local myUserId = tostring(player.UserId)
              local index = 1
              for i, uid in ipairs(orderedBots) do
                  if uid == myUserId then
                      index = i
                      break
                  end
              end

              -- Jarak formasi
              local jarakDepan = tonumber(vars.JarakDepan) or 4
              local jarakBelakang = tonumber(vars.JarakBelakang) or 4
              local jarakSamping = tonumber(vars.SideSpacing) or 3

              -- Offset posisi (sesuai pola box)
              local offsetMap = {
                  [1] = Vector3.new(-jarakSamping * 1.2, 0, 0),          -- kiri VIP
                  [2] = Vector3.new(-jarakSamping / 1.5, 0, jarakDepan), -- depan kiri
                  [3] = Vector3.new(jarakSamping / 1.5, 0, jarakDepan),  -- depan kanan
                  [4] = Vector3.new(jarakSamping * 1.2, 0, 0),           -- kanan VIP
                  [5] = Vector3.new(0, 0, -jarakBelakang * 1.2),         -- belakang VIP
              }

              local offset = offsetMap[index] or Vector3.zero
              local cframe = targetHRP.CFrame
              local targetPos = (cframe.Position
                  + cframe.RightVector * offset.X
                  + cframe.UpVector * offset.Y
                  + cframe.LookVector * offset.Z)

              moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)
          end)
      else
          warn("[BOX] RunService.Heartbeat tidak tersedia!")
      end
  end
}
