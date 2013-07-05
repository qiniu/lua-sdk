-- fop test

require('test_config')

local qiniu_fop = require('fop')
local url = 'http://cheneya.qiniudn.com/hello_jpg'

local t = {}
test_fop = t

local function exif(url)
	local ex = qiniu_fop.exif.new()
	local _, err = ex:call(url)
	assert(err == nil)
end

local function imageinfo(url)
	local info = qiniu_fop.image_info.new()
	local _, err = info:call(url)
	assert(err == nil)
end

local function imageview(url)
	local view = qiniu_fop.image_view.new()
	view.mode = 1
	view.height = 200
	local _, err = view:call(url)
	assert(err == nil)
end

-- exif test
local exif_test = class.new(test_case)
function exif_test:ctor(name)
end

function exif_test:test()
	exif(url)
end

-- image info test
local imageinfo_test = class.new(test_case)
function imageinfo_test:ctor(name)
end

function imageinfo_test:test()
	imageinfo(url)
end

-- image view test
local imageview_test = class.new(test_case)
function imageview_test:ctor(name)
end

function imageview_test:test()
	imageview(url)
end

test_fop.exif_test = exif_test
test_fop.imageinfo_test = imageinfo_test
test_fop.imageview_test = imageview_test
return t

