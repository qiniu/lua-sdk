-- qiniu auth_up

local qiniu_conf = require('conf')
local qiniu_client = require('rpc')
local t = {}
qiniu_auth_up = t
local client = class.new(qiniu_client)

function client:ctor(para_tbl)
	if para_tbl then self.up_token = para_tbl.token end
	self.super.ctor(self, {host = config.UP_HOST})
end

function client:round_tripper(method, path, body)
	self:set_header('Authorization', 'UpToken ' .. self.up_token)
	return self.super.round_tripper(self, method, path, body)
end

t.client = client
return t