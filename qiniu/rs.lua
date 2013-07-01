-- qiniu rs

local class = require('common.class')
local string = require('string')
local qiniu_conf = require('conf')
local qiniu_auth_digest = require('auth_digest')
local base64 = require('common.base64')
local t = {}
qiniu_rs = t
local client = class.new()

function client:ctor(param_tbl)
	local mac = (param_tbl and param_tbl.mac) and param_tbl.mac or qiniu_auth_digest.mac.new()
	self.conn = qiniu_auth_digest.client.new{host = qiniu_conf.RS_HOST, mac = mac}
end

local function uri_stat(bucket, key)
	return '/stat/' .. base64.encode_url(string.format('%s:%s', bucket, key))
end

function client:stat(bucket, key)
	return self.conn:call(uri_stat(bucket, key))
end

local function uri_delete(bucket, key)
	return '/delete/' .. base64.encode_url(string.format('%s:%s', bucket, key))
end

function client:delete(bucket, key)
	return self.conn:call(uri_delete(bucket, key))
end

local function uri_pair_op(bucket_src, key_src, bucket_dest, key_dest, op)
	local src = base64.encode_url(string.format('%s:%s', bucket_src, key_src))
	local dest = base64.encode_url(string.format('%s:%s', bucket_dest, key_dest))
	return op .. string.format('/%s/%s', src, dest)
end

local function uri_move(bucket_src, key_src, bucket_dest, key_dest)
	return uri_pair_op(bucket_src, key_src, bucket_dest, key_dest, '/move')
end

function client:move(bucket_src, key_src, bucket_dest, key_dest)
	return self.conn:call(uri_move(bucket_src, key_src, bucket_dest, key_dest))
end

local function uri_copy(bucket_src, key_src, bucket_dest, key_dest)
	return uri_pair_op(bucket_src, key_src, bucket_dest, key_dest, '/copy')
end

function client:copy(bucket_src, key_src, bucket_dest, key_dest)
	return self.conn:call(uri_copy(bucket_src, key_src, bucket_dest, key_dest))
end

function client:batch(ops)
	return self.conn:call_with_form("/batch", {op = ops})
end

function client:batch_ops(entries, operator) 
	local ops = {}
	for i, entry in ipairs(entries) do
		table.insert(ops, operator(entry))
	end
	return self:batch(ops)
end

function client:batch_stat(entries)
	return self:batch_ops(entries, function (entry)
		return uri_stat(entry.bucket, entry.key)
	end)
end

function client:batch_delete(entries)
	return self:batch_ops(entries, function (entry)
		return uri_delete(entry.bucket, entry.key)
	end)
end

function client:batch_move(entries)
	return self:batch_ops(entries, function (entry)
		return uri_move(entry.src.bucket, entry.src.key, 
			entry.dest.bucket, entry.dest.key)
	end)
end

function client:batch_copy(entries)
	return self:batch_ops(entries, function (entry)
		return uri_copy(entry.src.bucket, entry.src.key, 
			entry.dest.bucket, entry.dest.key)
	end)
end

local entry_path = class.new()
function entry_path:ctor(bucket, key)
	self.bucket, self.key = bucket, key
end

local entry_path_pair = class.new()
function entry_path_pair:ctor(src, dest)
	self.src, self.dest = src, dest
end

t.client = client
t.entry_path = entry_path
t.entry_path_pair = entry_path_pair
return qiniu_rs