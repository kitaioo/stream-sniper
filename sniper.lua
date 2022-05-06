local user_id = "3485422903"
local game_id = "6361937392"

local http_service = game:GetService("HttpService")

local image_request = syn.request({
    Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=".. user_id .. "&size=150x150&format=Png&isCircular=false"
})

local image_url = http_service:JSONDecode(image_request.Body).data[1].imageUrl

local function get_servers()
    local servers, cursor = {}
    while true do
        local data = syn.request({
            Url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100%s", game_id, cursor and "cursor=" .. cursor or "")
        })
        data = http_service:JSONDecode(data.Body)
        if not data.data then
            break
        end
        for _, server in pairs(data.data) do
            table.insert(servers, server)
        end
        if not data.nextPageCursor then
            break
        end
        cursor = data.nextPageCursor
    end
    return servers
end

local servers = get_servers()
for _, server in pairs(servers) do
    local server_data = {}
    for i, t in next, server.playerTokens do
        table.insert(server_data, {
            token = t,
            type = "AvatarHeadshot",
            size = "150x150"
        })
    end
    local post_request = syn.request({
        Url = "https://thumbnails.roblox.com/v1/batch",
        Method = "POST",
        Body = http_service:JSONEncode(server_data),
        Headers = {
            ["Content-Type"] = "application/json"
        }
    })
    for _, v in next, http_service:JSONDecode(post_request.Body).data do
        if v.imageUrl == image_url then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game_id, server.id)
        end
    end
end
