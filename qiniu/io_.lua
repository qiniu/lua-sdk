-- qiniu io

local class = require('common.class')
local io = require('io')
local string = require('string')
local qiniu_conf = require('conf')
local qiniu_client = require('rpc')
local base64 = require('common.base64')
local t = {}
qiniu_io = t
put_extra = class.new()

function put_extra:ctor(bucket)
	self.bucket = bucket
	self.callback_params = nil
	self.custom_meta = nil
	self.mime_type = nil
end

local function put(uptoken, key, data, extra)
	local action = {'/rs-put'}
	table.insert(action, base64.encode_url(extra.bucket .. ':' .. key))
	if extra.mime_type then 
		table.insert(action, 'mimeType/' .. base64.encode_url(extra.mime_type))
	end	
	if extra.custom_meta then 
		table.insert(action, 'meta/' .. base64.encode_url(extra.custom_meta))
	end	
	
	local fields = { {'action', table.concat(action, '/')}, {'auth', uptoken} }

	if extra.callback_params then
		table.insert(fields, {'params', extra.callback_params})
	end

	local files = { {'file', key, data} }
	local client = qiniu_client.new{host = qiniu_conf.UP_HOST}
	return client:call_with_multipart('/upload', fields, files)
end

function put_file(uptoken, key, localfile, extra)
	f = io.open(localfile, "rb")
	local data = f:read('*all')
	f:close()
	return put(uptoken, key, data, extra)
end

function get_url(domain, key, dntoken)
	return string.format('%s/%s?token=%s', domain, key, dntoken)
end

t.put_extra = put_extra
t.put_file = put_file
t.get_url = get_url
return t
