-- io test

require('test_config')
local qiniu_rs_token = require('rs_token')
local qiniu_io = require('io_')
local qiniu_rs = require('rs')

local bucket = 'junit_bucket'
local key = 'IOTest-key'
local expeted_hash = 'FmDZwqadA4-ib_15hYfQpb7UXUYR'

local t = {}
test_io = t

local function upload(bucket, key)
	local put_policy = qiniu_rs_token.put_policy.new(bucket)
	local up_token = put_policy:token()
	local put_extra = qiniu_io.put_extra.new(bucket)
	local ret, err = qiniu_io.put_file(up_token, key, test_path, put_extra)
	assert(err == nil)
	assert(ret.hash == expeted_hash)
end

local function delete(bucket, key)
	local rs = qiniu_rs.client.new()
	local ret, err = rs:delete(bucket, key)
	assert(err == nil)
end

io_test = class.new(test_case)

function io_test:ctor(name)
end

function io_test:clean_up()
	delete(bucket, key)
	self.super.clean_up(self)
end

function io_test:test()
	upload(bucket, key)
end

test_io.io_test = io_test
return t


