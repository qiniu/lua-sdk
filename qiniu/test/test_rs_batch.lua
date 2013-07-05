-- rs batch test

require('test_config')
local qiniu_rs_token = require('rs_token')
local qiniu_io = require('io_')
local qiniu_rs = require('rs')

local bucket_src = 'junit_bucket_src'
local bucket_dest = 'junit_bucket_dest'
local key1 = 'BatchCopyTest-key1'
local key2 = 'BatchCopyTest-key2'
local expeted_hash = 'FmDZwqadA4-ib_15hYfQpb7UXUYR'

local t = {}
test_rs_batch = t

local function upload(bucket, key)
	local put_policy = qiniu_rs_token.put_policy.new(bucket)
	local up_token = put_policy:token()
	local put_extra = qiniu_io.put_extra.new(bucket)
	local ret, err = qiniu_io.put_file(up_token, key, test_path, put_extra)
	assert(err == nil)
	assert(ret.hash == expeted_hash)
end

local function batch_delete(entries)
	local rs = qiniu_rs.client.new()
	local _, _ = rs:batch_delete(entries)
end

local function batch_stat(entries, ok, expeted_hash)
	local rs = qiniu_rs.client.new()
	local ret, err = rs:batch_stat(entries)
	if ok then
		assert(err == nil)
		for _, result in ipairs(ret) do
			assert(result.data.hash == expeted_hash)
		end
	else 
		assert(err ~= nil)
	end	
end

local function batch_copy(entries)
	local rs = qiniu_rs.client.new()
	local ret, err = rs:batch_copy(entries)
	assert(err == nil)
end

local function batch_move(entries)
	local rs = qiniu_rs.client.new()
	local ret, err = rs:batch_move(entries)
	assert(err == nil)
end

-- batch stat test
local batchstat_test = class.new(test_case)
function batchstat_test:ctor(name)
end

function batchstat_test:set_up()
	self.super.set_up(self)
	upload(bucket_src, key1)
	upload(bucket_src, key2)
end

function batchstat_test:clean_up()
	batch_delete{{bucket = bucket_src, key = key1}, {bucket = bucket_src, key = key2}}
	self.super.clean_up(self)
end

function batchstat_test:test()
	batch_stat({{bucket = bucket_src, key = key1}, {bucket = bucket_src, key = key2}}, true, expeted_hash)
end


-- batch copy test

local batchcopy_test = class.new(test_case)
function batchcopy_test:ctor(name)
end

function batchcopy_test:set_up()
	batch_delete{{bucket = bucket_dest, key = key1}, {bucket = bucket_dest, key = key2}}

	self.super.set_up(self)
	upload(bucket_src, key1)
	upload(bucket_src, key2)
end

function batchcopy_test:clean_up()
	batch_delete { {bucket = bucket_src, key = key1}, 
				   {bucket = bucket_src, key = key2}, 
				   {bucket = bucket_dest, key = key1}, 
				   {bucket = bucket_dest, key = key2}}
	self.super.clean_up(self)
end

function batchcopy_test:test()
	batch_copy{ {src = {bucket = bucket_src, key = key1}, dest = {bucket = bucket_dest, key = key1}}, 
				{src = {bucket = bucket_src, key = key2}, dest = {bucket = bucket_dest, key = key2}} }
	batch_stat({{bucket = bucket_src, key = key1}, {bucket = bucket_src, key = key2}, 
				{bucket = bucket_dest, key = key1}, {bucket = bucket_dest, key = key2}}, true, expeted_hash)
end

-- move test

local batchmove_test = class.new(test_case)
function batchmove_test:ctor(name)
end

function batchmove_test:set_up()
	batch_delete{{bucket = bucket_dest, key = key1}, {bucket = bucket_dest, key = key2}}

	self.super.set_up(self)
	upload(bucket_src, key1)
	upload(bucket_src, key2)
end

function batchmove_test:clean_up()
	batch_delete {{bucket = bucket_dest, key = key1}, 
				   {bucket = bucket_dest, key = key2}}
	self.super.clean_up(self)
end

function batchmove_test:test()
	batch_move{ {src = {bucket = bucket_src, key = key1}, dest = {bucket = bucket_dest, key = key1}}, 
				{src = {bucket = bucket_src, key = key2}, dest = {bucket = bucket_dest, key = key2}} }
	batch_stat({{bucket = bucket_src, key = key1}, {bucket = bucket_src, key = key2}})
	batch_stat({{bucket = bucket_dest, key = key1}, {bucket = bucket_dest, key = key2}}, true, expeted_hash)
end

test_rs_batch.batchstat_test = batchstat_test
test_rs_batch.batchcopy_test = batchcopy_test
test_rs_batch.batchmove_test = batchmove_test
return t

	