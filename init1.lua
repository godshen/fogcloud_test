local _M = {}
local bit = require "bit"
local crc16 = require "crc16"
local cjson = require "cjson.safe"

local Json = cjson.encode

local insert = table.insert
local concat = table.concat

local strbyte = string.byte
local strchar = string.char

local strload
local DATALENGTH = 42

local humanbeing = 1300000


local cmds = {
  [0x00] = "head1",
  [0x01] = "head2",
  [0x02] = "length",
  [0x03] = "DTU_time",
  [0x04] = "DTU_status",
  [0x05] = "device_address",
  [0x06] = "feedback_speed",
  [0x07] = "given_speed",
  [0x08] = "output_voltage",
  [0x09] = "output_current",
  [0x0a] = "output_torque",
  [0x0b] = "bus_voltage",
  [0x0c] = "analog_input0",
  [0x0d] = "analog_input1",
  [0x0e] = "analog_input2",
  [0x0f] = "cooling_temperature",
  [0x10] = "output_actpow",
  [0x11] = "output_tpow",
  [0x12] = "reserve0",
  [0x13] = "reserve1",
  [0x14] = "reserve2",
  [0x15] = "reserve3",
  [0x16] = "CRCheck"

}


function utilCalcFCS( pBuf , len )
	local rtrn = 0
	local l = len

	while (len ~= 0)
		do
		len = len - 1
		rtrn = bit.bxor( rtrn , pBuf[l-len] )
	end

	return rtrn
end



function getnumber( index )
   return strTonum(string.byte(string.sub(strload,index,index)))
end
function strTonum( data )
  if data > 96 and data < 103 then
    data = data - 87
  end
  if data > 64 and data < 70 then
    data = data - 55
  end
  if data > 47 and data < 59 then
    data = data - 48
  end
  return data
end


local function _pack(cmd, data, msg_id)
    local packet = {}

    insert(packet, string.char(0xAA))
    
    return concat(packet, "")
end

local function _unpack(data)
    local packet = {}

    return packet
end

function _M.encode(payload)
    local obj, err = cjson.decode(payload)
    if obj == nil then
        error("json_decode error:"..err)
    end

    for cmd, data in pairs(obj) do
        return _pack(cmd, data)
    end
end

function _M.decode(payload)
    local packet = {}
    strload = payload;
    packet['status'] = 'not'

    --DATALENGTH = getnumber(3) * 256 + getnumber(4); 

    if( false ) then
      local head1 = string.sub(payload,1,1)
      local head2 = string.sub(payload,2,2)

      if (head1== ';' and head2=='1') then 

        packet[ cmds[2] ] = getnumber(3) * 256 + getnumber(4);
        packet[ cmds[3] ] = getnumber(5) * 16777216 + getnumber(6) * 65536 + getnumber(7) * 256 + getnumber(8)
        if getnumber(9) == 1 then
          packet[ cmds[4] ] = 'Mode-485'
        else
          packet[ cmds[4] ] = 'Mode-232'
        end
        packet[ cmds[5] ] = getnumber(10)

        for i=0,30,2
          do
          packet[ cmds[6+i/2] ] = getnumber(11+i) * 256 + getnumber(12+i)
        end
        packet['crc0'] = CRC16( crcdata , DATALENGTH + 4 )
        packet['crc1'] = ( getnumber(43)*256+getnumber(44) )
        packet['status'] = 'success'

      else
        packet['status'] = 'HEAD-ERROR'

      end
    else
      packet['status'] = 'CRC-ERROR'
    end

    local fcsarr={}
    for i=1,20,1
    	do
    	fcsarr[i]=i*3+5
    end
    local bittest = {}
    bittest['test1']=bit.bnot(8)
    bittest['test2']=bit.band(8,10)
    bittest['fcs']=utilCalcFCS(fcsarr,20)
    return Json(bittest)
end

return _M

