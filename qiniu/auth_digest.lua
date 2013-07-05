-- qiniu auth_digest client

local string = require('string')
local qiniu_conf = require('conf')
local qiniu_client = require('rpc')
local hmac_sha1 = require('common.hmac_sha1')
local base64 = require('common.base64')
local url = require('socket.url')
local t = {}
qiniu_auth_digest = t
local client = class.new(qiniu_client)

function client:ctor(param_tbl)
	self.__mac = (param_tbl and param_tbl.mac) and param_tbl.mac or mac.new()
end

function client:round_tripper(method, path, body)
	local token = self.__mac:sign_request(path, body, self.headers['Content-Type'])
	self:set_header('Authorization', 'QBox ' .. token)
	return self.super.round_tripper(self, method, path, body)
end

local mac = class.new()
function mac:ctor(access_key, secret_key)
	self.access_key = access_key or qiniu_conf.ACCESS_KEY
	self.secret_key = secret_key or qiniu_conf.SECRET_KEY
end

local function sign(secret_key, data)
	local digest = hmac_sha1.hmac_sha1_binary(secret_key, data)
	return base64.encode_url(digest)
end

function mac:sign(data)
	return string.format('%s:%s', self.access_key, sign(self.secret_key, data))
end

function mac:sign_with_data(data)
	local encode_data = base64.encode_url(data)
	return string.format('%s:%s:%s', self.access_key, sign(self.secret_key, encode_data), encode_data)
end

function mac:sign_request(path, body, content_type)
	local parsed_url = url.parse(path)
	local query = parsed_url.query
	local path = parsed_url.path
	local data = (query == nil or query == '') and path or (string.format('%s?%s', path, query))
	data = data .. '\n'
	
	local content_types = {['application/x-www-form-urlencoded'] = true}
	if body and content_types[content_type] then data = data .. body end
	return self:sign(data)
end

t.client = client
t.mac = mac
return t
