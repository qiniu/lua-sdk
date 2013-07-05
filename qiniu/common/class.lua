-- class.lua
-- idea from http://blog.codingnow.com/2006/06/oo_lua.html

local _class = {}
local t = {}
class = t

function class.new(super)
	local class_type = {}
	class_type.ctor = false
	class_type.super = super
	class_type.new = function(...) 
		local obj = {}
		setmetatable(obj, {__index = _class[class_type]})
		obj.super = _class[super]

		do
			local create
			create = function(c, ...)
				if c.super then
					_class[super].ctor = c.super.ctor
					create(c.super, ...)
				end
				if c.ctor then
					c.ctor(obj, ...)
				end
			end
 
			create(class_type, ...)
		end

		return obj
	end
	local vtbl = {}
	_class[class_type] = vtbl
 
	setmetatable(class_type, {__newindex =
		function(t,k,v)
			vtbl[k] = v
		end
	})
 
	if super then
		setmetatable(vtbl, {__index =
			function(t,k)
				local ret = _class[super][k]
				vtbl[k]=ret
				return ret
			end
		})
	end
 
	return class_type
end

return t
