local httpd = require('http.server').new('0.0.0.0', 8081)
local router = require('http.router').new({ charset = 'application/json'})
local api = require('api')

box.cfg{listen=3031}
api:init()

function handler(handler)
    return function(req)
        return api[handler](api, req)
    end
end

router:route({ path = '/kv/:key', method = 'GET' }, handler('get'))
router:route({ path = '/kv/:key', method = 'PUT' }, handler('update'))
router:route({ path = '/kv', method = 'POST' }, handler('add'))
router:route({ path = '/kv/:key', method = 'DELETE' }, handler('delete'))
httpd:set_router(router)

httpd:start()