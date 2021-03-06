local class = require("scripts/kaitai_struct_lua_runtime-master/class")

local FtlDat = class.class(KaitaiStruct)
local File = class.class(KaitaiStruct)
local Meta = class.class(KaitaiStruct)

--FtlDat

function FtlDat:from_file(filename)
	return KaitaiStruct.from_file(self,filename)
end

function FtlDat:from_string(s)
	return KaitaiStruct.from_string(self,s)
end

function FtlDat:_init(p__io, p__parent, p__root)
	KaitaiStruct._init(self,p__io)
    self.m_parent = p__parent
    self.m_root = p__root or self
	self.signature = false
end

function FtlDat:_read()
    self._numFiles = self._io:read_u4le()
	
    self._files = {}
    for i = 1, self._numFiles do
		local file = File(self._io, self, self.m_root)
		file:_read()
        table.insert(self._files,file)
	end
end

function FtlDat:_write()
	local ret = {lua_struct.pack("<I",self._numFiles)}
	
	local meta = {}
	
	local metaOfs = 4 * (1 + self._numFiles)
	for i = 1, self._numFiles do
		local data = self._files[i]._meta:_write()
		table.insert(meta,data)
		table.insert(ret,lua_struct.pack("<I",metaOfs))
		metaOfs = metaOfs + data:len()
	end
	for i, data in ipairs(meta) do
		table.insert(ret,data)
	end
    return table.concat(ret)
end

--File

function File:_init(p__io, p__parent, p__root)
	KaitaiStruct._init(self,p__io)
	self.m_parent = p__parent
    self.m_root = p__root
end

function File:_read()
    self._metaOfs = self._io:read_u4le()
	
	if (self._metaOfs ~= 0) then
        local _pos = self._io:pos()
        self._io:seek(self._metaOfs)
        self._meta = Meta(self._io, self, self.m_root)
		self._meta:_read()
        self._io:seek(_pos)
    end
end

function File:_write()
	--return lua_struct.pack("<I",self._metaOfs)
end

--Meta

function Meta:_init(p__io, p__parent, p__root)
	KaitaiStruct._init(self,p__io)
    self.m_parent = p__parent
	self.m_root = p__root
end

function Meta:_read()
	self._fileSize = self._io:read_u4le()
	self._filenameSize = self._io:read_u4le()
	self._filename = self._io:read_bytes(self._filenameSize)
	self.body = self._io:read_bytes(self._fileSize)
	
	if self._filename == modApi:getSignature() then
		self.m_root.signature = true
	end
end

function Meta:_write()
	local size = lua_struct.pack("<I",self._fileSize)
	local nameSize = lua_struct.pack("<I",self._filenameSize)
	return table.concat({size,nameSize,self._filename,self.body})
end

return {
	FtlDat = FtlDat,
	File = File,
	Meta = Meta,
}