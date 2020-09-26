local httpd = require('http.server').new('0.0.0.0', 8081)
local router = require('http.router').new({ charset = 'application/json'})
local api = require('api')

box.cfg{listen=3031}
api.init()

router:route({ path = '/kv/:key', method = 'GET' }, api.get)
router:route({ path = '/kv/:key', method = 'PUT' }, api.update)
router:route({ path = '/kv', method = 'POST' }, api.add)
router:route({ path = '/kv/:key', method = 'DELETE' }, api.delete)
httpd:set_router(router)

httpd:start()