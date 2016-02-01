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


--[[--]]
function MoveBit( dir , data , num )
  if dir == 'L' then
    data = data * (2^num)
  else
    data = data / (2^num)
  end
  data = math.modf(data)
  return data
end


function BitOperationAND( a , b )
  local res = 0

  for i=8,1,-1
    do
    res = MoveBit('L',res,1)

    t1 = MoveBit('R',a,i-1)
    t2 = MoveBit('R',a,i)
    t2 = MoveBit('L',t2,1)
    aa = t1 - t2    

    t1 = MoveBit('R',b,i-1)
    t2 = MoveBit('R',b,i)
    t2 = MoveBit('L',t2,1)
    bb = t1 - t2    

    if( ( aa==1 ) and ( bb==1) )then
      res = res + 1
      --print(res)
      --print(aa..'&'..bb..'->'..'1')
    else
      --print(aa..'&'..bb..'->'..'0')
    end
  end
  --print("end of and")
  return res
end


function BitOperationOR( a , b )
  local res = 0


  for i=8,1,-1
    do
    res = MoveBit('L',res,1)

    t1 = MoveBit('R',a,i-1)
    t2 = MoveBit('R',a,i)
    t2 = MoveBit('L',t2,1)
    aa = t1 - t2    

    t1 = MoveBit('R',b,i-1)
    t2 = MoveBit('R',b,i)
    t2 = MoveBit('L',t2,1)
    bb = t1 - t2    

    if( ( aa==0 ) and ( bb==0) )then
      res = res + 0
      --print(res)
      --print(aa..'&'..bb..'->'..'0')
    else
      res = res + 1
      --print(aa..'&'..bb..'->'..'1')
    end
  end
  --print("end of and")
  return res
end


function BitOperationXOR( a , b )
  local mask
  local res = 0
  local aa
  local bb
  
  for i = 7 , 0 , -1
    do
    res = MoveBit('L',res,1)
    mask = MoveBit('L',1,i)
    aa = BitOperationAND(a,mask)
    bb = BitOperationAND(b,mask)

    if aa == bb then
      res = res + 0
    else
      res = res + 1
    end

  end
  return res
end


function CRC16( pdata, datalen)

  local CRC16Lo,CRC16Hi,CL,CH,SaveHi,SaveLo;
  local i,Flag;
  
  CRC16Lo = 0xFF;
  CRC16Hi = 0xFF;
  CL = 0x01;
  CH = 0xA0;

  for i=1,datalen,1
    do
    CRC16Lo = BitOperationXOR(CRC16Lo , pdata[i]);
    
    for Flag=0,7,1
      do
      SaveHi = CRC16Hi;
      SaveLo = CRC16Lo;
      CRC16Hi = MoveBit('R',CRC16Hi,1)
      CRC16Lo = MoveBit('R',CRC16Lo,1)
      
      if(BitOperationAND(SaveHi , 0x01) == 0x01) then
      --if((SaveHi & 0x01) == 0x01) then
        --print(SaveHi)
        CRC16Lo = BitOperationOR( CRC16Lo , 0x80 );
      end

      if(BitOperationAND(SaveLo , 0x01) == 0x01) then
      --if((SaveLo & 0x01) == 0x01) then
        --print(SaveLo)
        CRC16Hi = BitOperationXOR(CRC16Hi , CH);
        CRC16Lo = BitOperationXOR(CRC16Lo , CL);
      end

    end 
  end 

  return  BitOperationOR(MoveBit('L',CRC16Hi,8) , CRC16Lo)
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

    DATALENGTH = getnumber(3) * 256 + getnumber(4);
    local crcdata = {}
    for i=1,DATALENGTH,1
      do
      crcdata[i] = getnumber(i)
    end
    
    --if CRC16( crcdata , DATALENGTH + 4 ) == (getnumber(43)*256+getnumber(44) ) then
    if( true ) then
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

    return Json(packet)
end

return _M

