-- ModeBuaya.lua (Stop Compatible & No Repeat Until All Sent)
return {
  Execute = function(msg, client)
      local vars = _G.BotVars
      local RunService = vars.RunService
      local player = vars.LocalPlayer

      if not RunService then
          warn("[ModeBuaya] RunService tidak tersedia!")
          return
      end

      local TextChatService = vars.TextChatService or game:GetService("TextChatService")
      local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
      if not channel then
          warn("[ModeBuaya] Channel RBXGeneral tidak ditemukan!")
      end

      -- 🔹 Chat romantis
      local chatList = {
          "Kamu kalau butuh apa-apa, bilang ke aku ya, {name}.",
          "Kamu jangan sedih ya, {name}, kan ada aku di sini.",
          "Senyum dong, {name}, kalau nangis nanti cantiknya luntur.",
          "Enak ya jadi kamu, {name}, kalau mau lihat bidadari, tinggal lihat di kaca.",
          "Sejak kenal kamu, {name}, aku jadi tau tujuan hidupku.",
          "Hari-hariku jadi lebih berwarna sejak ada kamu, {name}, biasanya kelabu.",
          "Kamu kok jahat banget sih, {name}, berani-beraninya mencuri hatiku.",
          "Kamu baik, {name}, tunggu aku persiapkan diri untuk jadi imam kamu ya.",
          "Aku janji, {name}, aku setia.",
          "Kau cantik hari ini, {name}, dan aku suka.",
          "Jika cinta adalah seni, {name}, kau adalah karyaku yang paling berharga.",
          "Ngemil apa yang paling enak, {name}? Ngemilikin kamu sepenuhnya.",
          "Aku temenin ya, {name}, aku nggak mau kamu jadi butiran debu tanpa aku."
      }

      -- 🔹 Emoji baper
      local emojiList = {"😘"}

      -- 🔹 Copy list sementara untuk menghindari duplikasi
      local unusedChatList = {}
      for _, v in ipairs(chatList) do
          table.insert(unusedChatList, v)
      end

      -- 🔹 Atur mode ModeBuaya
      vars.FollowAllowed = true
      vars.ShieldActive = false
      vars.RowActive = false
      vars.FrontlineActive = false
      vars.CurrentFormasiTarget = client

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
          if (myRootPart.Position - targetPos).Magnitude < 2 then return end

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

      -- Hentikan koneksi lama jika ada
      if vars.FollowConnection then pcall(function() vars.FollowConnection:Disconnect() end) vars.FollowConnection = nil end
      if vars.ModeBuayaChatConnection then pcall(function() vars.ModeBuayaChatConnection:Disconnect() end) vars.ModeBuayaChatConnection = nil end

      -- Heartbeat loop (follow)
      if RunService.Heartbeat then
          vars.FollowConnection = RunService.Heartbeat:Connect(function()
              if not vars.FollowAllowed then return end -- kompatibel dengan !stop

              vars.AbsenActive = vars.AbsenActive or {}
              local myId = tostring(player.UserId)
              if vars.AbsenActive[myId] then return end

              if not client or not client.Character then return end
              local targetHRP = client.Character:FindFirstChild("HumanoidRootPart")
              if not targetHRP then return end

              local jarakIkut = tonumber(vars.JarakIkut) or 6
              local followSpacing = tonumber(vars.FollowSpacing) or 4

              local orderedBots = {"8802945328", "8802949363", "8802939883", "8802998147"}

              local myUserId = tostring(player.UserId)
              local index = 1
              for i, uid in ipairs(orderedBots) do
                  if uid == myUserId then index = i break end
              end

              local backOffset = jarakIkut + (index - 1) * followSpacing
              local targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * backOffset

              moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)
          end)

          -- Heartbeat loop (chat + emoji)
          vars.ModeBuayaChatTimer = 0
          vars.ModeBuayaChatConnection = RunService.Heartbeat:Connect(function(step)
              if not vars.FollowAllowed then return end -- kompatibel dengan !stop

              vars.ModeBuayaChatTimer = (vars.ModeBuayaChatTimer or 0) + step
              if vars.ModeBuayaChatTimer >= 10 then
                  vars.ModeBuayaChatTimer = 0
                  if client and client.Parent and channel then
                      local name = client.DisplayName or client.Name

                      -- Reset unusedChatList jika kosong
                      if #unusedChatList == 0 then
                          for _, v in ipairs(chatList) do
                              table.insert(unusedChatList, v)
                          end
                      end

                      -- Ambil chat acak dari unusedChatList
                      local idx = math.random(1, #unusedChatList)
                      local message = unusedChatList[idx]:gsub("{name}", name)
                      table.remove(unusedChatList, idx) -- hapus agar tidak terulang

                      pcall(function() channel:SendAsync(message) end)

                      -- Pesan emoji
                      local emojiIndex = math.random(1, #emojiList)
                      local emojiMessage = emojiList[emojiIndex]
                      pcall(function() channel:SendAsync(emojiMessage) end)
                  end
              end
          end)
      else
          warn("[ModeBuaya] RunService.Heartbeat tidak tersedia!")
      end

      print("[COMMAND] ModeBuaya aktif, target:", client.Name)
  end
}
