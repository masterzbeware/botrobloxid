return {
    Execute = function()

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then
            return
        end

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        --------------------------------------------------
        -- NATURAL LANGUAGE (TANPA PREFIX)
        --------------------------------------------------
        -- Parser berasal dari Perfix.lua (_G.BotVars.NLP).
        -- Perfix.lua belum memiliki intent untuk modul ini, jadi
        -- modul ini mendaftarkan intent-nya sendiri ke NLP.Intents.
        --
        -- Pertanyaan (tanda baca ? dan ! diabaikan parser):
        --   mengerti / mengerti? / mengerti?! / apakah kalian mengerti?
        --   jelas / jelas? / jelas?!
        --   ada pertanyaan / ada pertanyaan? / ada pertanyaan?!
        --
        -- Panggilan barisan (HANYA Admin), bot menjawab
        -- "Siap menerima perintah.":
        --   barisan / pimpin / pimpinan / pasukan
        --   pimpinan saya ambil alih / barisan saya ambil alih
        --
        -- Perintah (HANYA Admin):
        --   agree
        --   unagree / stop / berhenti / bubar
        --------------------------------------------------

        local NLP = _G.BotVars.NLP

        if not NLP then

            warn(
                "[Agree] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            NLP.Intents.agree_mengerti =
                NLP.Intents.agree_mengerti
                or {
                    StrictRemainder = true,

                    Words = {
                        mengerti = 2,

                        -- Kata pendamping (bernilai 0) untuk
                        -- "apakah kalian mengerti?".
                        apakah = 0,
                    },
                }

            NLP.Intents.agree_jelas =
                NLP.Intents.agree_jelas
                or {
                    StrictRemainder = true,

                    Words = {
                        jelas = 2,
                    },
                }

            -- Butuh kedua kata (masing-masing 1 poin, minimal 2)
            -- supaya kata "pertanyaan" saja tidak memicu balasan.
            NLP.Intents.agree_pertanyaan =
                NLP.Intents.agree_pertanyaan
                or {
                    StrictRemainder = true,

                    Words = {
                        ada = 1,
                        pertanyaan = 1,
                    },
                }

            -- Panggilan barisan / pimpinan, termasuk "pimpinan saya ambil alih".
            -- Threshold 1 supaya "barisan" (kata formasi lemah) sendirian
            -- tetap dikenali, tanpa mengalahkan perintah formasi seperti
            -- "barisan depan" (skor formasi 2 > skor intent ini 1).
            -- Intent ini juga yang membuat Message.lua tidak mengulang
            -- (echo) pesan tersebut, karena Message.lua melewati semua
            -- pesan yang dikenali parser.
            NLP.Intents.agree_siap =
                NLP.Intents.agree_siap
                or {
                    Threshold = 1,
                    StrictRemainder = true,

                    Words = {
                        barisan = 1,
                        pimpin = 2,
                        pimpinan = 2,
                        pasukan = 2,

                        -- Kata pendamping (bernilai 0) untuk
                        -- "... saya ambil alih".
                        ambil = 0,
                        alih = 0,
                    },
                }

            NLP.Intents.agree =
                NLP.Intents.agree
                or {
                    StrictRemainder = true,

                    Words = {
                        agree = 2,
                    },
                }

            NLP.Intents.unagree =
                NLP.Intents.unagree
                or {
                    Threshold = 3,
                    Priority = 1,
                    StrictRemainder = true,

                    Words = {
                        unagree = 3,
                    },
                }

        end

        local AGREE_MESSAGES = {
            "Yes, Sir!",
        }

        -- Respon otomatis untuk pertanyaan, berdasarkan nama intent.
        local QUESTION_RESPONSES = {
            agree_mengerti = "Siap, mengerti!",
            agree_jelas = "Siap, jelas!",
            agree_pertanyaan = "Siap, Tidak ada!",
        }

        local agreeing = false
        local agreeGeneration = 0

        local function sendChat(message)
            if not message then
                return false
            end

            if TextChatService and TextChatService.TextChannels then
                local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if channel then
                    local success = pcall(function()
                        channel:SendAsync(message)
                    end)
                    if success then
                        return true
                    end
                end
            end

            return false
        end

        local function stopAgree()
            agreeGeneration += 1
            agreeing = false
        end

        _G.BotVars.ModeControllers.agree = stopAgree

        local function stopOtherModes()
            for modeName, controller in pairs(_G.BotVars.ModeControllers) do
                if modeName ~= "agree" and type(controller) == "function" then
                    pcall(controller)
                end
            end
        end

        local function startAgree()
            agreeGeneration += 1
            local generation = agreeGeneration

            agreeing = true
            _G.BotVars.ActiveMode = "agree"
            stopOtherModes()

            if generation ~= agreeGeneration or not agreeing then
                return
            end

            -- Bot pertama yang menerima command memilih pesan.
            -- Bot lain menggunakan pilihan global yang sama.
            local selectedMessage = _G.BotVars.AgreeMessage

            if not selectedMessage then
                local randomObject = Random.new()
                selectedMessage = AGREE_MESSAGES[
                    randomObject:NextInteger(1, #AGREE_MESSAGES)
                ]
                _G.BotVars.AgreeMessage = selectedMessage
            end

            sendChat(selectedMessage)
        end

        -- Kata pemanggil barisan / pimpinan.
        -- Dicocokkan langsung (bukan lewat NLP.Intents) supaya kata
        -- "barisan" tidak bentrok dengan perintah formasi di modul lain
        -- (misalnya "barisan depan" atau "barisan belakang").
        local READY_WORDS = {
            barisan = true,
            pimpin = true,
            pimpinan = true,
            pasukan = true,
        }

        local READY_RESPONSE = "Siap menerima perintah."

        -- True jika pesan hanya berisi kata pemanggil (kata pengisi
        -- seperti "siap" diabaikan), misalnya "barisan" atau "siap pimpinan".
        local function isReadyCall(message)
            if not NLP then
                return false
            end

            local found = false

            for _, token in ipairs(NLP.Tokenize(message)) do
                if not NLP.Fillers[token.norm] then
                    if READY_WORDS[token.norm] then
                        found = true
                    else
                        return false
                    end
                end
            end

            return found
        end

        local function handleCommand(message, sender)
            if not message or not sender then
                return
            end

            local isAdmin = false
            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            if not isAdmin then
                return
            end

            -- Barisan / pimpin / pimpinan: bot menjawab siap.
            if isReadyCall(message) then
                sendChat(READY_RESPONSE)
                return
            end

            local intent

            if NLP then
                intent = NLP.Classify(message, NLP.Intents)
            end

            if not intent then
                return
            end

            -- Barisan / pimpin / pimpinan (termasuk "... saya ambil alih").
            if intent == "agree_siap" then
                sendChat(READY_RESPONSE)
                return
            end

            local questionResponse = QUESTION_RESPONSES[intent]

            if questionResponse then
                sendChat(questionResponse)
                return
            end

            if intent == "agree" then
                _G.BotVars.AgreeMessage = nil
                startAgree()
                return
            end

            if intent == "unagree" or intent == "stop" then
                if _G.BotVars.ActiveMode == "agree" then
                    _G.BotVars.ActiveMode = nil
                end

                _G.BotVars.AgreeMessage = nil
                stopAgree()
                return
            end
        end

        local connectedPlayers = {}

        local function connectPlayerChat(player)
            if connectedPlayers[player] then
                return
            end

            connectedPlayers[player] = true

            player.Chatted:Connect(function(message)
                handleCommand(message, player)
            end)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            connectPlayerChat(player)
        end

        Players.PlayerAdded:Connect(function(player)
            connectPlayerChat(player)
        end)

        Players.PlayerRemoving:Connect(function(player)
            connectedPlayers[player] = nil
        end)

        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)

            if _G.BotVars.ActiveMode == "agree" then
                agreeing = true

                local selectedMessage = _G.BotVars.AgreeMessage
                if selectedMessage then
                    task.wait(0.2)
                    sendChat(selectedMessage)
                end
            end
        end)

        return {
            Execute = function()
                return true
            end
        }

    end
}
