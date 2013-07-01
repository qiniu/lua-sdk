-- qiniu rpc

local class = require('common.class')
local string = require('string')
local ltn12 = require('ltn12')
local http = require('socket.http')
local json = require('cjson')

local t = class.new()
qiniu_client = t

function qiniu_client:ctor(para_tbl)
	self.headers = {}
	if para_tbl then self.host = para_tbl.host end
end

function qiniu_client:round_tripper(method, path, body)
	local resp_body = {}
	local _, status_code, resp_head, _ = http.request{
		url = self.host and self.host .. path or path,
		sink = ltn12.sink.table(resp_body),
		method = method,
		headers = self.headers,
		source = ltn12.source.string(body)
	}
	return status_code, resp_head, resp_body[1]
end

function qiniu_client:get(path, need_parse) 
	return self:call_with_method(path, 'GET', need_parse)
end

function qiniu_client:call(path)
	return self:call_with(path)
end

function qiniu_client:call_with_method(path, method, need_parse, body, content_type, content_length)
	self:set_header('Content-Type', content_type)
	self:set_header('Content-Length', content_length)
	local status_code, resp_head, resp_body = self:round_tripper(method, path, body)
	local ret = nil
	if need_parse then
		if resp_body then
			--print('resp_body--->', resp_body)
			ret = json.decode(resp_body)
			if not ret then return nil, 'json decode error' end
		else 
			ret = {}
		end
	else
		ret = resp_body
	end

	if status_code / 100 ~= 2 then
		local err_msg = ret['error'] or 'error'
		local detail = resp_head['x-log']
		if detail then err_msg = err_msg .. ', detail:' .. detail end
		return nil, err_msg
	end
	return ret, nil
	
end

function qiniu_client:call_with(path, body, content_type, content_length)
	return self:call_with_method(path, "POST", true, body, content_type, content_length)
end

function qiniu_client:call_with_multipart(path, fields, files)
	local content_type, body = self:encode_multipart_formdata(fields, files)
	return self:call_with(path, body, content_type, string.len(body))
end

function qiniu_client:encode_multipart_formdata(fields, files)
	--[[
		fields => { {key, value}, ...}
		files => { {key, filename, value}, ... }
		return content_type, body
	--]]
	files = files or {}
	fields = fields or {}
	local boundary = '----------ThIs_Is_tHe_bouNdaRY_$'
	local crlf = '\r\n'
	local l = {}
	
	for i, kv in ipairs(fields) do
		table.insert(l, string.format('--%s', boundary))
		table.insert(l, string.format('Content-Disposition: form-data; name=%s', kv[1]))
		table.insert(l, '')
		table.insert(l, kv[2])
	end
	local disposition = 'Content-Disposition: form-data;'
	for i, kvd in ipairs(files) do
		table.insert(l, string.format('--%s', boundary))
		table.insert(l, string.format('%s name=%s; filename=%s', disposition, kvd[1], kvd[2]))
		table.insert(l, 'Content-Type: application/octet-stream')
		table.insert(l, '')
		table.insert(l, kvd[3])
	end
	
	table.insert(l, string.format('--%s--', boundary))
	table.insert(l, '')
	local body = table.concat(l, crlf)
	local content_type = 'multipart/form-data; boundary=' .. boundary
	return content_type, body
end

function qiniu_client:call_with_form(path, ops)
	local body_tbl = {}
	for key, op in pairs(ops) do
		local data = ((type(op) == 'table') and table.concat(op, string.format('&%s=', key))) or op 
		table.insert(body_tbl, string.format('%s=%s', key, data))
	end 
	local body = table.concat(body_tbl, '&')
	local content_type = 'application/x-www-form-urlencoded'
	return self:call_with(path, body, content_type, string.len(body)) 
end

function qiniu_client:set_header(field, value)
	self.headers[field] = value
end

function qiniu_client:set_headers(headers)
	for k, v in pairs(headers) do self.headers[k] = v end
end

return qiniu_client
