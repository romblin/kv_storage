local log = require('log')
local json = require('json')

function parse_request(req)
    local status, json_req = pcall(req.json, req)
    if not status then
        return false, 'Body is invalid'
    end
    return true, json_req
end

function validate_request(req)
    local status, json_req = parse_request(req)
    if not status then
        return status, json_req
    end
    if type(json_req.key) ~= 'string' or json_req.key == '' then
        return false, 'Key is invalid'
    end
    return true, json_req
end


local api = {
    init = function(self)
        box.once('init', function()
            box.schema.create_space('pairs', { if_not_exists = true, format = {
                {name = 'key', type = 'string'},
                {name = 'value', type = 'string'}
            }})
        box.space.pairs:create_index('pk', {type = 'hash', parts = {{field = 'key'}}})
        end)
    end,

    add = function(self, req)
        local status, json_req = validate_request(req)
        if not status then
            return { status = 400, body = json_req }
        end
        local s, _ = pcall(function() box.space.pairs:insert{json_req.key, json.encode(json_req.value)} end)
        if s then
            log.info('Added key "%s"', json_req.key)
            return { status = 201 }
        end
        log.info('Failed to add key "%s" due to a duplicate', json_req.key)
        return { status = 409 }
    end,

    update = function(self, req)
        local status, json_req = parse_request(req)
        if not status then
            return { status = 400, body = json_req }
        end
        local key = req:stash('key')
        local o = box.space.pairs:update(key, {{'=', 'value', json.encode(json_req.value)}})
        if o == nil then
            log.info('Failed to update key "%s" because it doesn`t exist', json_req.key)
            return { status = 404 }
        end
        log.info('Updated key "%s"', json_req.key)
        return { status = 200 }
    end,

    get = function(self, req)
        local key = req:stash('key')
        local o = box.space.pairs:get(key)
        if o == nil then
            log.info('Failed to find key "%s"', key)
            return { status = 404}
        end
        log.info('Found key "%s"', key)
        return { status = 200, body = o.value, headers = { ['Content-Type'] = 'application/json' } }
    end,

    delete = function(self, req)
        local key = req:stash('key')
        local o = box.space.pairs:delete(key)
        if o == nil then
            log.info('Failed to delete key "%s" because it doesn`t exist')
            return { status = 404 }
        end
        log.info('Deleted key "%s"', key)
        return { status = 200 }
    end
}

return api