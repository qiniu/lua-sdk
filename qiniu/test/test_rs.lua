-- rs test

require('test_config')
local qiniu_rs_token = require('rs_token')
local qiniu_io = require('io_')
local qiniu_rs = require('rs')

local bucket_src = 'junit_bucket_src'
local key = 'CopyTest-key'
local bucket_dest = 'junit_bucket_dest'
local expeted_hash = 'FmDZwqadA4-ib_15hYfQpb7UXUYR'

local t = {}
rs_test = t

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
	local _, _ = rs:delete(bucket, key)
end

local function stat(bucket, key, ok, expeted_hash)
	local rs = qiniu_rs.client.new()
	local ret, err = rs:stat(bucket, key)
	if ok then 
		assert(err == nil)
		assert(ret.hash == expeted_hash)
	else 
		assert(err ~= nil)
	end	
end

local function copy(bucket_src, key, bucket_dest, key)
	local rs = qiniu_rs.client.new()
	local ret, err = rs:copy(bucket_src, key, bucket_dest, key)
	assert(err == nil)
end

local function move(bucket_src, key, bucket_dest, key)
	local rs = qiniu_rs.client.new()
	local ret, err = rs:move(bucket_src, key, bucket_dest, key)
	assert(err == nil)
end

-- stat test
local stat_test = class.new(test_case)
function stat_test:ctor(name)
end

function stat_test:set_up()
	self.super.set_up(self)
	upload(bucket_src, key)
end

function stat_test:clean_up()
	delete(bucket_src, key)
	self.super.clean_up(self)
end

function stat_test:test()
	stat(bucket_src, key, true, expeted_hash)
end

-- copy test

local copy_test = class.new(test_case)
function copy_test:ctor(name)
end

function copy_test:set_up()
	delete(bucket_dest, key)

	self.super.set_up(self)
	upload(bucket_src, key)
end

function copy_test:clean_up()
	delete(bucket_src, key)
	delete(bucket_dest, key)
	self.super.clean_up(self)
end

function copy_test:test()
	copy(bucket_src, key, bucket_dest, key)
	stat(bucket_src, key, true, expeted_hash)
	stat(bucket_dest, key, true, expeted_hash)
end

-- move test

local move_test = class.new(test_case)
function move_test:ctor(name)
end

function move_test:set_up()
	self.super.set_up(self)

	delete(bucket_dest, key)
	upload(bucket_src, key)
end

function move_test:clean_up()
	delete(bucket_src, key)
	delete(bucket_dest, key)
	self.super.clean_up(self)
end

function move_test:test()
	move(bucket_src, key, bucket_dest, key)
	stat(bucket_src, key)
	stat(bucket_dest, key, true, expeted_hash)
end

rs_test.stat_test = stat_test
rs_test.copy_test = copy_test
rs_test.move_test = move_test
return rs_test
	