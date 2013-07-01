--[[
Easy Qiniu Lua SDK

Module: qiniu_base64.lua

Author: LIANG Tao
Weibo:  @无锋之刃
Email:  amethyst.black@gmail.com
        liangtao@qiniu.com

Wiki:   https://en.wikipedia.org/wiki/Base64
--]]

require('bit32')
require('string')

qiniu_base64 = (function ()
    local t = {}

    local function __encode_iterator(buf)
        if type(buf) == 'string' then
            return function (s)
                if s.pos == s.len then
                    return nil, nil, nil, nil
                end

                s.pos = s.pos + 1
                local d1 = s.buf:byte(s.pos)
                if s.pos == s.len then
                    return d1, 0, 0, 2
                end

                s.pos = s.pos + 1
                local d2 = s.buf:byte(s.pos)
                if s.pos == s.len then
                    return d1, d2, 0, 1
                end

                s.pos = s.pos + 1
                local d3 = s.buf:byte(s.pos)
                return d1, d2, d3, 0
            end,
            {
                pos = 0,
                len = buf:len(),
                buf = buf
            },
            nil
        end

        if type(buf) == 'table' then
            return function (s)
                if s.pos == s.len then
                    return nil, nil, nil, nil
                end

                s.pos = s.pos + 1
                local d1 = s.buf[s.pos]
                if s.pos == s.len then
                    return d1, 0, 0, 2
                end

                s.pos = s.pos + 1
                local d2 = s.buf[s.pos]
                if s.pos == s.len then
                    return d1, d2, 0, 1
                end

                s.pos = s.pos + 1
                local d3 = s.buf[s.pos]
                return d1, d2, d3, 0
            end,
            {
                pos = 0,
                len = #buf,
                buf = buf
            },
            nil
        end
    end -- __encode_iterator

    local function __encode(buf, map, padding)
        local ret = {}

        for d1, d2, d3, padding_len in __encode_iterator(buf) do
            local p1 = bit32.band(bit32.rshift(d1, 2), 0x3F)
            local p2 = bit32.bor(
                bit32.lshift(bit32.band(d1, 0x03), 4),
                bit32.rshift(bit32.band(d2, 0xF0), 4)
            )
            local p3 = bit32.bor(
                bit32.lshift(bit32.band(d2, 0x0F), 2),
                bit32.rshift(bit32.band(d3, 0xC0), 6)
            )
            local p4 = bit32.band(d3, 0x3F)

            local c1 = map[p1+1]
            local c2 = map[p2+1]
            local c3 = map[p3+1]
            local c4 = map[p4+1]

            if padding_len == 2 then
                ret[#ret+1] = c1
                ret[#ret+1] = c2
                ret[#ret+1] = padding:rep(padding_len)
            end
            if padding_len == 1 then
                ret[#ret+1] = c1
                ret[#ret+1] = c2
                ret[#ret+1] = c3
                ret[#ret+1] = padding:rep(padding_len)
            end
            if padding_len == 0 then
                ret[#ret+1] = c1
                ret[#ret+1] = c2
                ret[#ret+1] = c3
                ret[#ret+1] = c4
            end
        end -- for

        return table.concat(ret)
    end -- __encode

    local function __decode_iterator(buf)
        if type(buf) == 'string' then
            return function (s)
                if s.pos == s.len then
                    return nil
                end
                s.pos = s.pos + 1
                return s.buf:byte(s.pos)
            end,
            {
                pos = 0,
                len = buf:len(),
                buf = buf,
            },
            nil
        end
        if type(buf) == 'table' then
            return function (s)
                if s.pos == s.len then
                    return nil
                end
                s.pos = s.pos + 1
                return s.buf[s.pos]
            end,
            {
                pos = 0,
                len = #buf,
                buf = buf,
            },
            nil
        end
    end -- __decode_iterator

    local FIRST  = 1
    local SECOND = 2
    local THIRD  = 3
    local FOURTH = 4

    local function __decode(buf, map)
        local ret   = {}
        local chr   = 0
        local state = FIRST

        for d in __decode_iterator(buf) do
            local val = map[d]
            if state == FIRST then
                chr = bit32.lshift(bit32.band(val, 0x3F), 2)
                state = SECOND
            elseif state == SECOND then
                chr = bit32.bor(chr, bit32.rshift(bit32.band(val, 0x30), 4))
                ret[#ret+1] = string.char(chr)
                chr = bit32.lshift(bit32.band(val, 0x0F), 4)
                state = THIRD
            elseif state == THIRD then
                chr = bit32.bor(chr, bit32.rshift(bit32.band(val, 0x3C), 2))
                ret[#ret+1] = string.char(chr)
                chr = bit32.lshift(bit32.band(val, 0x03), 6)
                state = FOURTH
            else
                chr = bit32.bor(chr, bit32.band(val, 0x3F))
                ret[#ret+1] = string.char(chr)
                state = FIRST
            end
        end -- for

        return table.concat(ret)
    end -- __decode

    local ENCODE_MIME_MAP = {
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K',
        'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V',
        'W', 'X', 'Y', 'Z',
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k',
        'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
        'w', 'x', 'y', 'z',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '+', '/'
    }

    function t.encode_mime(buf)
        ret = __encode(buf, ENCODE_MIME_MAP, '=')
        ret = ret:gsub(string.rep('.', 76), "%0\r\n")
        return ret 
    end -- t.encode_mime

    local DECODE_MIME_MAP = {}
    for i = 1, #ENCODE_MIME_MAP, 1 do
        local pos = ENCODE_MIME_MAP[i]:byte()
        DECODE_MIME_MAP[pos] = i - 1
    end -- for

    function t.decode_mime(buf)
        return __decode(
            (buf:gsub("\r\n", "")):gsub("=+$", ""),
            DECODE_MIME_MAP
        )
    end -- t.decode_mime

    local ENCODE_URL_MAP = {
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K',
        'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V',
        'W', 'X', 'Y', 'Z',
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k',
        'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
        'w', 'x', 'y', 'z',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '-', '_'
    }

    function t.encode_url(buf)
        ret = __encode(buf, ENCODE_URL_MAP, '=')
        return ret 
    end -- t.encode_url

    local DECODE_URL_MAP = {}
    for i = 1, #ENCODE_URL_MAP, 1 do
        local pos = ENCODE_URL_MAP[i]:byte()
        DECODE_URL_MAP[pos] = i - 1
    end -- for

    function t.decode_url(buf)
        return __decode(
            (buf:gsub("\r\n", "")):gsub("=+$", ""),
            DECODE_URL_MAP
        )
    end -- t.decode_url

    return t
end)()

return qiniu_base64
