-- qiniu fop

local class = require('common.class')
local string = require('string')
local socket = require('socket')
local math = require('math')
local qiniu_conf = require('conf')
local qiniu_client = require('rpc')
local t = {}
qiniu_fop = t

local exif = class.new()
function exif:ctor() end
function exif:make_request(url) return url .. '?exif' end
function exif:call(url) return qiniu_client.new():get(self:make_request(url), true) end

local image_info = class.new()
function image_info:ctor() end
function image_info:make_request(url) return url .. '?imageInfo' end
function image_info:call(url) return qiniu_client.new():get(self:make_request(url), true) end

local image_view = class.new()
function image_view:ctor() self.mode = 1 end
function image_view:make_request(url)
	local info = {}
	table.insert(info, string.format('%d', self.mode))
	if self.width then table.insert(info, string.format('w/%d', self.width)) end
	if self.height then table.insert(info, string.format('h/%d', self.height)) end
	if self.quality then table.insert(info, string.format('q/%d', self.quality)) end
	if self.format then table.insert(info, string.format('format/%d', self.format)) end
	return string.format('%s?imageView/%s', url, table.concat(info, '/'))
end
function image_view:call(url) return qiniu_client.new():get(self:make_request(url)) end

t.image_view = image_view
t.image_info = image_info
t.exif = exif

return qiniu_fop
