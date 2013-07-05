-- test case

package.path = package.path .. ";../?.lua;?.lua"
local class = require('common.class')

local t = class.new()
test_case = t

function test_case:ctor(name)
	self.name = name
end

function test_case:set_up()
	print('test case [' .. self.name .. '] start')
end

function test_case:clean_up()
	print('test case [' .. self.name .. '] end')
end

function test_case:test()
end

function test_case:run()
	self:set_up()
	self:test()
	self:clean_up()
end

return t