-- test all

local tfop = require('test_fop')
local tio = require('test_io')
local trs = require('test_rs')
local trs_batch = require('test_rs_batch')

local function run_pack(pack)
	for key, obj in pairs(pack) do
		local test = obj.new(key)
		test:run()
	end
end

run_pack(tfop)
run_pack(tio)
run_pack(trs)
run_pack(trs_batch)

