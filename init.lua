local _M = {}
local bit = require "bit"
local cjson = require "cjson.safe"

local Json = cjson.encode

local insert = table.insert
local concat = table.concat
--
local strload

local cmds = {
  [0] = "length",
  [1] = "DTU_time",
  [2] = "DTU_status",
  [3] = "DTU_function",
  [4] = "device_address"
}

local status_cmds = {
  [1] = "system_status0",
  [2] = "limit_signal",
  [3] = "in_cage_instruction",
  [4] = "on_cage_instruction",
  [5] = "fall_instruction",
  [6] = "contactor_feedback",
  [7] = "contactor_output",
  [8] = "last_fault",
  [9] = "system_status1",
  [10] = "output_current",
  [11] = "bus_voltage",
  [12] = "output_frequency",
  [13] = "load"
}

local para_1 = {
  ["P10_"] = 4,
  ["P11_"] = 3,
  ["P12_"] = 16,
  ["P13_"] = 5,
  ["P20_"] = 8
}
local para_0 = {  
          "P10_","P11_","P12_","P13_","P20_"
        }
local num = 1
--local parameter_cmds = {}

--for k,v in ipairs(para_0) do
--  local l = para_1[v]
--  for i=0,l-1,1 do
--    parameter_cmds[num] = v..string.format("%02d",i)
--    num = num + 1
--  end
--end

local parameter_cmds ={
  "P00_00",
  "P10_00","P10_01","P10_02","P10_03",
  "P11_00","P11_01","P11_02",
  "P12_00","P12_01","P12_02","P12_03","P12_04","P12_05","P12_06","P12_07",
  "P12_08","P12_09","P12_10","P12_11","P12_12","P12_13","P12_14","P12_15",
  "P12_16","P12_17","P12_18","P12_19",
  "P13_00","P13_01","P13_02","P13_03","P13_04",
  "P20_01","P20_02","P20_03","P20_04","P20_05","P20_06","P20_07","P20_08"
}
local parameter_RealValue = {
["P00_00"]=-1,
["P13_04"]=0,["P13_01"]=0,["P12_10"]=0,["P12_05"]=0,["P12_18"]=0,["P10_01"]=2,["P10_02"]=2,["P13_00"]=0,["P12_17"]=0,["P12_04"]=0,
["P12_15"]=0,["P20_06"]=0,["P11_00"]=2,["P12_14"]=3,["P11_02"]=0,["P12_12"]=3,["P12_00"]=0,["P12_02"]=0,["P20_03"]=0,["P20_01"]=2,
["P20_02"]=0,["P12_16"]=0,["P20_08"]=0,["P13_02"]=0,["P10_00"]=2,["P11_01"]=0,["P20_05"]=0,["P20_04"]=0,["P12_11"]=3,["P13_03"]=0,
["P12_13"]=3,["P20_07"]=0,["P12_01"]=0,["P10_03"]=0,["P12_19"]=0,["P12_03"]=0,["P12_06"]=-1,["P12_07"]=-1,["P12_08"]=-1,["P12_09"]=-1
}

local fault_cmds = {}
local faultcmds = {
    [1] = "code",
    [2] = "real_speed",
    [3] = "given_speed",
    [4] = "bus_voltage",
    [5] = "current"
}


for i=0,7,1 do
  for j=1,5,1 do
    fault_cmds[i*5+j] = "fault"..i.."_"..faultcmds[j] 
  end
end


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
   return string.byte(strload,index)
end



function _M.encode(payload)
  return payload
end

function _M.decode(payload)
    local packet = {['status']='not'}
    local FCS_Array = {}
    local FCS_Value = 0

    strload = payload

    local head1 = getnumber(1)
    local head2 = getnumber(2)

    if ( head1 == 0x3B and head2 == 0x31 ) then 
      
      local templen = bit.lshift( getnumber(3) , 8 ) + getnumber(4)   
      packet[ cmds[0] ] = templen
      packet[ cmds[1] ] = bit.lshift( getnumber(5) , 8 ) + bit.lshift( getnumber(6) , 16 ) + bit.lshift( getnumber(7) , 8 ) + getnumber(8)

      local mode = getnumber(9)
      if mode == 1 then
          packet[ cmds[2] ] = 'Mode-485'
        else
          packet[ cmds[2] ] = 'Mode-232'
      end

      local func = getnumber(10)
      if func == 1 then
          packet[ cmds[3] ] = 'func-status'
          local my_cmds = {
			"sys_run","sys_up","sys_down","sys_alert","sys_fault","sys_selflearn","sys_learnerr",
			"limit_front","limit_back","limit_window","limit_up","limit_down","limit_dece","limit_fall",
			"in_switch","in_stop","in_up","in_down","in_highspeed","in_reset","in_run","in_freqswitch",
			"on_stop","on_up","on_down","on_switch","on_insert",
			"fall_enable","fall_fall","fall_up",
			"confeedback_KM4","confeedback_KM5","confeedback_KM6","confeedback_protect","confeedback_bzcon1","confeedback_bzcon2",
			"conoutput_KM1","conoutput_KM2","conoutput_KM3","conoutput_KM4","conoutput_KM5","conoutput_KM6"
      		}
          local my_count = {7,7,8,5,3,6,6}
          FCS_Value = bit.lshift( getnumber(templen+5) , 8 ) + getnumber(templen+6)
          for i=1,(templen-9)/2,1 do        
            packet[ status_cmds[i] ] = bit.lshift( getnumber(10+i*2) , 8 ) + getnumber(11+i*2)
          end
    	    packet[ status_cmds[10] ] = ( bit.lshift( getnumber(30) , 8 ) + getnumber(31) ) / 10
    	    packet[ status_cmds[11] ] = ( bit.lshift( getnumber(32) , 8 ) + getnumber(33) ) / 1
    	    packet[ status_cmds[12] ] = ( bit.lshift( getnumber(34) , 8 ) + getnumber(35) ) / 100  
            packet[ status_cmds[13] ] = ( bit.lshift( getnumber(36) , 8 ) + getnumber(37) ) / 100
          local cou = 1
          for i=1,7,1 do
          	for j=1,my_count[i],1 do
          		local x = bit.band(packet[status_cmds[i]],bit.lshift(1,j))
            	packet[ my_cmds[cou] ] = ((x==0) and "N" or "Y");
            	cou = cou + 1
          	end
          end
          for i=1,templen+4,1 do        
            table.insert(FCS_Array,getnumber(i))
          end
          
        else if func == 2 then
          packet[ cmds[3] ] = 'func-fault'
          FCS_Value = bit.lshift( getnumber(templen+5) , 8 ) + getnumber(templen+6)
          for i=1,(templen-9)/2,1 do
      	    local x = i % 5
      	    if x == 2 or x == 3 then
                    packet[ fault_cmds[i] ] = ( bit.lshift( getnumber(10+i*2) , 8 ) + getnumber(11+i*2) ) / 100
      	    else
      	      packet[ fault_cmds[i] ] = bit.lshift( getnumber(10+i*2) , 8 ) + getnumber(11+i*2)
      	    end
          end
          for i=1,templen+4,1 do        
            table.insert(FCS_Array,getnumber(i))
          end

        else
          packet[ cmds[3] ] = 'func-parameter'
          FCS_Value = bit.lshift( getnumber(templen+5) , 8 ) + getnumber(templen+6)
          for i=1,(templen-9)/2,1 do 
            local temp = 0
            temp = parameter_RealValue[ parameter_cmds[i] ]
            if temp ~= -1 then
              local paranum = ( bit.lshift( getnumber(10+i*2) , 8 ) + getnumber(11+i*2) ) / ( 10^temp )
              local parastrformat = "%0."..temp.."f"
              packet[ parameter_cmds[i] ] = string.format(parastrformat,paranum)
            end
          end

          for i=1,templen+4,1 do        
            table.insert(FCS_Array,getnumber(i))
          end

        end
      end

      packet[ cmds[4] ] = getnumber(11)

      if(utilCalcFCS(FCS_Array,#FCS_Array) == FCS_Value) then
        packet['status'] = 'SUCCESS'
      else
        packet = {}
        packet['status'] = 'FCS-ERROR'
      end

    end

    return Json(packet)
end

return _M

