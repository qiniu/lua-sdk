-- qiniu rs token

local class = require('common.class')
local string = require('string')
local socket = require('socket')
local math = require('math')
local qiniu_conf = require('conf')
local qiniu_auth_digest = require('auth_digest')
local json = require('cjson')
local url = require('socket.url')
local t = {}
qiniu_rs_token = t

local put_policy = class.new()
function put_policy:ctor(scope, expires)
	self.scope = scope
	self.expires = expires or 3600
end

function put_policy:token(mac)
	local _mac = mac or qiniu_auth_digest.mac.new()
	local token = { scope = self.scope, deadline = math.floor(socket.gettime()) + self.expires }
	token['callbackUrl'] = self.callbackUrl
	token['callbackBody'] = self.callbackBody
	token['returnUrl'] = self.returnUrl
	token['returnBody'] = self.returnBody
	token['asyncOps'] = self.asyncOps
	local data = json.encode(token)
	return _mac:sign_with_data(data)
end

local get_policy = class.new()
function get_policy:ctor(expires)
	self.expires = expires or 3600
end

function get_policy:make_request(base_url, mac)
	mac = mac or qiniu_auth_digest.mac.new()
	local deadline = math.floor(socket.gettime()) + self.expires
	base_url = base_url .. ((string.find(base_url, '?') and '&') or '?')
	base_url = string.format('%se=%d', base_url, deadline)
	local token = mac.sign(base_url)
	return string.format('%s&token=%s', base_url, token)
end

local function make_base_url(domain, key)
	return string.format('http://%s/%s', domain, url.escape(key))
end

t.put_policy = put_policy
t.get_policy = get_policy
t.make_base_url = make_base_url

return t