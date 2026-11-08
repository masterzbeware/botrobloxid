-- Perfix.lua
-- Core / Prefix Loader (tanpa Tab)

--------------------------------------------------
-- NATURAL COMMAND PARSER (TANPA PREFIX)
--------------------------------------------------
-- Perintah ditulis dengan kata biasa, tidak perlu tanda seru.
-- Parser dan kamus perintah ini dibagikan ke semua modul
-- lewat _G.BotVars.NLP.
--
-- Cara kerja:
-- 1. Pesan dibersihkan: huruf kecil, tanda baca dibuang,
--    huruf berulang dirapikan ("jalaaan" menjadi "jalan").
-- 2. Kata pengisi ("tolong", "dong", "ya", dll) diabaikan.
-- 3. Setiap intent mendapat skor dari kata dan frasa yang cocok.
--    Salah ketik satu huruf pada kata panjang tetap dikenali.
-- 4. Intent dengan skor tertinggi (minimal Threshold) menang.
-- 5. "jangan ..." membalik perintah (lihat NegationOf).
-- 6. Kata yang tidak dikenal dikembalikan sebagai args
--    (misalnya nama pemain).
--
-- NLP.Classify(pesan, intents) mengembalikan:
--     nama_intent, args, skor
-- atau nil jika pesan bukan perintah.
--
-- Format satu intent:
--     Words           = { kata = poin }
--     Phrases         = { ["dua kata"] = poin_tambahan }
--     Threshold       = skor minimal (default 2)
--     Priority        = pemenang jika skor sama (default 0)
--     StrictRemainder = true: tolak jika ada kata tak dikenal
--     NegationOf      = nama intent yang dibalik oleh "jangan"
--------------------------------------------------

local NLP = {}

-- Pesan yang lebih panjang dari ini dianggap obrolan biasa.
NLP.MaxTokens = 8

local function makeSet(list)
    local set = {}

    for _, word in ipairs(list) do
        set[word] = true
    end

    return set
end

-- Kata pengisi: diabaikan sepenuhnya.
NLP.Fillers = makeSet({
    "tolong", "dong", "donk", "deh", "ya", "yah", "yaa",
    "lah", "kah", "nih", "sih", "aja", "saja",
    "dulu", "sekarang", "segera", "cepat", "cepetan",
    "langsung", "usah", "now", "please", "pls", "plis",
    "bot", "bots", "semua", "semuanya", "kalian", "kamu",
    "anda", "kita", "kami", "all", "everyone",
    "bareng", "barengan", "bersama",
    "sir", "komandan", "siap", "t",
    "buat", "bikin", "membuat", "membentuk", "form", "make",
    "jadi", "menjadi",
})

-- Kata ganti diri: "ikuti saya" artinya target = pengirim.
NLP.SelfWords = makeSet({
    "saya", "aku", "gue", "gw", "gua", "ane", "ku",
    "me", "myself",
})

-- Kata sambung: bukan bagian dari nama pemain.
NLP.Connectors = makeSet({
    "ke", "di", "kepada", "untuk", "pada", "dengan", "sama",
    "yang", "itu", "ini", "nya", "dan", "and", "to", "the", "a",
    "tempat", "sini", "situ", "kesini", "kemari", "here", "there",
    "sekitar", "around", "dari",
})

-- Kata negasi: "jangan ikuti saya" berarti berhenti.
NLP.Negations = makeSet({
    "jangan", "janganlah", "tidak", "tak", "gak", "ga",
    "nggak", "ngga", "enggak", "engga",
    "no", "not", "dont", "don",
})

--------------------------------------------------
-- KAMUS PERINTAH
--------------------------------------------------

-- Kata umum formasi (lemah, bernilai 1): baru berarti jika
-- dipasangkan dengan kata penentu seperti 'depan' atau 'tengah'.
local function formation(words)
    local common = {
        formasi = 1,
        bentuk = 1,
        barisan = 1,
        baris = 1,
        line = 1,
    }

    for word, points in pairs(common) do
        words[word] = points
    end

    return words
end

NLP.Intents = {

    -- Formasi depan (modul Frontline)
    frontline = {
        Words = formation({
            frontline = 2,
            front = 1,
            depan = 1,
        }),
    },

    -- Formasi belakang (modul Backline)
    backline = {
        Words = formation({
            backline = 2,
            back = 1,
            belakang = 1,
        }),
    },

    -- Formasi tengah (modul Centerline)
    centerline = {
        Words = formation({
            centerline = 2,
            center = 1,
            centre = 1,
            tengah = 1,
        }),
    },

    -- Formasi lingkaran (modul Circle)
    circle = {
        Words = formation({
            circle = 2,
            lingkaran = 2,
            melingkar = 2,
            keliling = 2,
            kelilingi = 2,
            mengelilingi = 2,
        }),
    },

    -- Formasi empat baris (modul Fourline)
    fourline = {
        Words = formation({
            fourline = 2,
            four = 1,
            empat = 1,
            ["4"] = 1,
        }),
    },

    -- Formasi panah (modul Arrow)
    arrow = {
        Words = formation({
            arrow = 2,
            panah = 2,
        }),
    },

    -- Hentikan formasi panah saja (modul Arrow)
    unarrow = {
        Threshold = 3,
        Priority = 1,
        StrictRemainder = true,

        Words = {
            unarrow = 3,
        },
    },

    -- Ikuti pemain (modul Follow)
    follow = {
        Threshold = 2,

        Words = {
            -- Kata kerja "ikuti" (kuat, cukup satu kata)
            ikuti = 2,
            ikut = 2,
            ikutin = 2,
            mengikuti = 2,
            follow = 2,
            following = 2,
            kejar = 2,

            -- Kata gerak (lemah, perlu dua kata atau lebih)
            bergerak = 1,
            gerak = 1,
            maju = 1,
            jalan = 1,
            berjalan = 1,
            ayo = 1,
            yuk = 1,
            mari = 1,
            move = 1,
            walk = 1,
            forward = 1,
            march = 1,
        },

        Phrases = {
            ["maju jalan"] = 1,
            ["bergerak maju"] = 1,
        },
    },

    -- Berhenti (menghentikan semua mode)
    stop = {
        Threshold = 3,
        Priority = 1,
        StrictRemainder = true,
        NegationOf = "follow",

        Words = {
            berhenti = 3,
            hentikan = 3,
            stop = 3,
            setop = 3,
            halt = 3,
            bubar = 3,
            unfollow = 3,
            unbackline = 3,
            uncenterline = 3,
            uncircle = 3,
            unfourline = 3,
            unfrontline = 3,
        },
    },

}

--------------------------------------------------
-- HELPER
--------------------------------------------------

-- "jalaaan" -> "jalan" (3 huruf sama atau lebih jadi 1)
local function collapseRepeats(word)
    local result = {}
    local index = 1

    while index <= #word do
        local char = word:sub(index, index)
        local last = index

        while word:sub(last + 1, last + 1) == char do
            last += 1
        end

        if last - index + 1 >= 3 then
            table.insert(result, char)
        else
            table.insert(result, word:sub(index, last))
        end

        index = last + 1
    end

    return table.concat(result)
end

-- True jika dua kata hanya beda satu huruf
-- (salah ganti, kelebihan, kurang, atau dua huruf tertukar).
local function nearlyEqual(a, b)
    if a == b then
        return true
    end

    local lengthA = #a
    local lengthB = #b

    if math.abs(lengthA - lengthB) > 1 then
        return false
    end

    local i = 1

    while i <= lengthA
        and i <= lengthB
        and a:sub(i, i) == b:sub(i, i) do

        i += 1

    end

    -- Salah satu kata habis: selisih satu huruf di ujung.
    if i > lengthA or i > lengthB then
        return true
    end

    local restA = a:sub(i + 1)
    local restB = b:sub(i + 1)

    -- Salah ganti huruf.
    if restA == restB then
        return true
    end

    -- Kelebihan huruf di a.
    if restA == b:sub(i) then
        return true
    end

    -- Kelebihan huruf di b.
    if a:sub(i) == restB then
        return true
    end

    -- Dua huruf tertukar.
    if a:sub(i, i) == b:sub(i + 1, i + 1)
        and a:sub(i + 1, i + 1) == b:sub(i, i)
        and a:sub(i + 2) == b:sub(i + 2) then

        return true

    end

    return false
end

-- Cocokkan satu kata dengan kamus (toleran salah ketik
-- untuk kata dengan panjang 6 huruf atau lebih).
local function resolveWord(norm, vocabulary)
    if vocabulary[norm] then
        return norm
    end

    if #norm >= 6 then
        for word in pairs(vocabulary) do
            if #word >= 6 and nearlyEqual(norm, word) then
                return word
            end
        end
    end

    return nil
end

--------------------------------------------------
-- TOKENIZE
--------------------------------------------------
-- Mengembalikan daftar { raw = ..., norm = ... }.
-- raw  : kata asli (dipakai untuk nama pemain)
-- norm : kata yang sudah dirapikan (dipakai untuk mencocokkan)
--------------------------------------------------

function NLP.Tokenize(text)
    local tokens = {}

    text = tostring(text or ""):lower()
    text = text:gsub("[^%w%s_]", " ")

    for word in text:gmatch("%S+") do
        table.insert(tokens, {
            raw = word,
            norm = collapseRepeats(word),
        })
    end

    return tokens
end

--------------------------------------------------
-- CLASSIFY
--------------------------------------------------

function NLP.Classify(text, intents)
    text = tostring(text or "")

    ----------------------------------------------
    -- Perintah lama milik modul lain ("!frontline",
    -- "!message ...") bukan urusan parser ini, kecuali
    -- kata pertamanya dikenal oleh salah satu intent.
    ----------------------------------------------

    local legacy = text:match("^%s*!%s*([%w_]+)")

    if legacy then
        legacy = collapseRepeats(legacy:lower())

        local recognized = false

        for _, def in pairs(intents) do
            if resolveWord(legacy, def.Words) then
                recognized = true
                break
            end
        end

        if not recognized then
            return nil
        end
    end

    ----------------------------------------------
    -- Buang kata pengisi
    ----------------------------------------------

    local content = {}

    for _, token in ipairs(NLP.Tokenize(text)) do
        if not NLP.Fillers[token.norm] then
            table.insert(content, token)
        end
    end

    if #content == 0 or #content > NLP.MaxTokens then
        return nil
    end

    ----------------------------------------------
    -- Negasi dan gabungan kata (untuk frasa)
    ----------------------------------------------

    local known = {}
    local norms = {}
    local negated = false

    for index, token in ipairs(content) do
        norms[index] = token.norm

        if NLP.Negations[token.norm] then
            negated = true
            known[index] = true
        end
    end

    local joined = " " .. table.concat(norms, " ") .. " "

    ----------------------------------------------
    -- Skor tiap intent
    ----------------------------------------------

    local scores = {}

    for name, def in pairs(intents) do
        local score = 0
        local counted = {}

        for index, token in ipairs(content) do
            local word = resolveWord(token.norm, def.Words)

            if word then
                known[index] = true

                -- Kata yang diulang hanya dihitung sekali.
                if not counted[word] then
                    counted[word] = true
                    score += def.Words[word]
                end
            end
        end

        if def.Phrases then
            for phrase, points in pairs(def.Phrases) do
                if joined:find(" " .. phrase .. " ", 1, true) then
                    score += points
                end
            end
        end

        scores[name] = score
    end

    ----------------------------------------------
    -- "jangan <perintah>" menjadi kebalikannya
    ----------------------------------------------

    if negated then
        for name, def in pairs(intents) do
            local base = def.NegationOf and scores[def.NegationOf]

            if base and base > 0 then
                scores[def.NegationOf] = 0
                scores[name] = (scores[name] or 0)
                    + (def.Threshold or 2)
            end
        end
    end

    ----------------------------------------------
    -- Sisa kata yang tidak dikenal (misalnya nama pemain)
    ----------------------------------------------

    local args = {}

    for index, token in ipairs(content) do
        if not known[index]
            and not NLP.SelfWords[token.norm]
            and not NLP.Connectors[token.norm] then

            table.insert(args, token.raw)

        end
    end

    ----------------------------------------------
    -- Pilih pemenang
    ----------------------------------------------

    local bestName
    local bestScore
    local bestPriority

    for name, def in pairs(intents) do
        local score = scores[name] or 0
        local priority = def.Priority or 0

        if score >= (def.Threshold or 2)
            and not (def.StrictRemainder and #args > 0) then

            if not bestName
                or score > bestScore
                or (score == bestScore and priority > bestPriority) then

                bestName = name
                bestScore = score
                bestPriority = priority

            end
        end
    end

    if not bestName then
        return nil
    end

    -- Dua perintah dengan skor dan prioritas sama berarti ambigu
    -- (misalnya hanya 'formasi baris'): lebih aman diabaikan.
    for name, def in pairs(intents) do
        if name ~= bestName
            and (scores[name] or 0) == bestScore
            and (def.Priority or 0) == bestPriority
            and bestScore >= (def.Threshold or 2)
            and not (def.StrictRemainder and #args > 0) then

            return nil

        end
    end

    return bestName, args, bestScore
end

-- Cari nama pemain dari args (sisa kata yang tidak dikenal).
-- Mencoba gabungan semua kata, lalu kata pertama, lalu kata terakhir.
-- findPlayer = fungsi pencari pemain milik modul pemanggil.
-- Mengembalikan teks nama yang cocok, atau nil.
function NLP.ResolveTarget(args, findPlayer)
    if not args or #args == 0 then
        return nil
    end

    local candidates = {
        table.concat(args, " "),
        args[1],
        args[#args],
    }

    for _, candidate in ipairs(candidates) do
        if findPlayer(candidate) then
            return candidate
        end
    end

    return nil
end

return {
  Execute = function()
      _G.BotVars = _G.BotVars or {}
      local vars = _G.BotVars

      -- Ambil MainWindow dari loader utama
      if not vars.MainWindow then
          warn("[Perfix] MainWindow not found")
          return
      end

      -- Prefix dikosongkan: perintah memakai kata biasa, bukan tanda seru
      vars.Prefix = ""

      -- Parser bahasa natural, dipakai bersama oleh semua modul
      vars.NLP = NLP

      -- Status bot
      vars.BotReady = true

      print("[Perfix] Loaded successfully")
  end
}
