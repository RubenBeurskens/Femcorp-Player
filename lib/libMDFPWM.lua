-- MDFPWMv3 file format reader
-- Code by Drucifer@SwitchCraft.kst
-- Consider donating?
local string,math=_G.string,_G.math

-- Main functions
--Usage .parse(fs.open("disk/song.mdfpwm","rb"))
--Returns table with single function .getSample(sec)
local function parse(handle) --Parse the file format
  if not handle or type(handle) ~= "table" or not handle.read then return false,"Incorrect handle provided" end --Basic check if we got a handle
  if handle.read(7) == "MDFPWM\003" then --Check if the file header is correct
    local currpos,datalen,_,_,_,headerlen=handle.seek(),string.unpack("<Is1s1s1",handle.read(770)) --Read length of DFPWM data stream following header
    local sampleCount=math.ceil(datalen/12000) --Get the sample count
    handle.seek("set",currpos+headerlen+1) --Reposition the handle as we likely read too much before
    local dataStream=handle.read(datalen)
	-- Usage .getSample(sec)
	-- Returns: One second of buffer from both channels indicated by seconds (starting at 1) {left=<6000 bytes DFPWM>,right=<6000 bytes DFPWM>}
    local function getSample(iNum) --Pull sample from datastream
      if iNum < 1 or iNum > sampleCount then return nil end
      local sampleData=dataStream:sub(((iNum-1)*12000)+1,iNum*12000)
      return {left=sampleData:sub(1,6000),right=sampleData:sub(6001,12000)}
    end
    return {getSample=getSample}
  else
    return false,"MDFPWMv3 header not found"
  end
end

--Usage .meta(fs.open("disk/song.mdfpwm","rb"))
--Returns table containing the metadata of the track {len:int(seconds),artist:string,title:string,album:string}
local function meta(handle)
  local isMDFPWM,currpos,peekData=false,handle.seek(),{}
  if handle.read(7) == "MDFPWM\003" then
    isMDFPWM=true
    peekData.len,peekData.artist,peekData.title,peekData.album=string.unpack("<Is1s1s1",handle.read(770))
    peekData.len=math.ceil(peekData.len/12000)
  end handle.seek("set",currpos) --We're only taking a peek, roll pointer back
  return isMDFPWM and peekData or {false,"Not MDFPWMv3 Formatted"}
end

return {parse=parse,read=parse,meta=meta}