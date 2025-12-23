-- admin.lua
-- Admin / Controller whitelist (UserId based)

local Admin = {}

-- 🔐 ADMIN USERIDS
Admin.AllowedUsers = {
    [10190678566] = true, -- MAIN CONTROLLER
}

-- Cek apakah player admin
function Admin:IsAdmin(player)
    if not player then return false end
    return Admin.AllowedUsers[player.UserId] == true
end

return Admin
