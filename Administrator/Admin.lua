-- Administrator/Admin.lua
-- Central admin whitelist (UserId based)

local Admin = {}

Admin.AllowedUsers = {
    [11001607521] = true, -- MAIN ADMIN
}

function Admin:IsAdmin(player)
    if not player then return false end
    return Admin.AllowedUsers[player.UserId] == true
end

return Admin
