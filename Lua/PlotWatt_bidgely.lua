-- http://forum.micasaverde.com/index.php?topic=25850.0
-- v1.1
-- Script for uploading data to PlotWatt and BIDGELY
-- Visit PlotWatt.com for more information
-- Visit BIDGELY.com for more information
--
-- See API documentation at https://plotwatt.com/docs/api
-- (Select Low-level details with Curl examples)
--
-- Bidgely API params
-- https://api.bidgely.com/v1/users/90d4356c-8011-4980-a0b4-692aa7e1c1d8/homes/1/gateways/1/upload


-- PlotWatt API Key
local PW_KEY = "Y2E2MGUzNzI5MzVi"


local meterId_01 = '1439154'
local deviceId_01 = 29
local serviceId_01 = 'urn:micasaverde-com:serviceId:EnergyMetering1'
local serviceVar_01 = "Watts"


----------------------------
-- Upload Frequency
----------------------------
-- The PlotWatt API specifies an upload interval of no more frequent than 60 seconds
-- in seconds
local uploadFreq = 60

-- Extra debug messages
local DEBUG = false
local BOX_DEBUG = false



-- Shouldn't need to change anything below this line
local http = require('socket.http')
http.TIMEOUT = 5

local PW_URL = "http://" .. PW_KEY .. ":@plotwatt.com/api/v2/push_readings"
local BG_URL = "https://api.bidgely.com/v1/users/90d4356c-8011-4980-a0b4-692aa7e1c1d8/homes/1/gateways/1/upload"
local pwLog = function (text) luup.log('PlotWatt Logger: ' .. (text or "empty")) end
local lastUpload = os.time()


local powerArray = {}

------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
local function initWatch()
    luup.variable_watch('powerWatch', serviceId_01, serviceVar_01, deviceId_01)
end

function powerWatch(deviceId, serviceId, serviceVar, oldValue, newValue)
 

   if (BOX_DEBUG) then
      --Show in the upper panel the time
      t = os.date('*t')
      luup.task(t.hour .. ":" .. t.min .. ":" .. t.sec .. " -- EXECUTION", 2, "PLOTWATT_BIDGELY", -1)
   end
   
  timeNow = os.time()
  if (DEBUG) then pwLog("plotWattUpload Outside sendfunction timeNow = " ..  timeNow .. " lastUpload = " .. lastUpload .. " uploadFreq = " .. uploadFreq)
end

  plotUpload = false
  if (timeNow - lastUpload >= uploadFreq) then
    plotUpload = true
    lastUpload = timeNow
  end
  
  meterValue = 0
  meterValue = luup.variable_get(serviceId, serviceVar, deviceId)
  BidgelyUpload(timeNow, meterValue)
  plotWattUpload(timeNow, meterValue, plotUpload)
  
end
------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
function plotWattUpload(timeStamp, newValue, upload)

   powerArray[#powerArray + 1] = meterId_01
   powerArray[#powerArray + 1] = newValue/1000
   powerArray[#powerArray + 1] = timeStamp

   if (DEBUG) then pwLog("plotWattUpload Got update of " .. newValue .. " at " .. timeStamp)
   end
 
   if (upload) then
    status = http.request(PW_URL,table.concat(powerArray,","))
    powerArray = {}
      if (BOX_DEBUG) then
        --Show in the upper panel the time
        t = os.date('*t')
        luup.task(t.hour .. ":" .. t.min .. ":" .. t.sec .. " --  uploaded with status: #" .. status .. "#", 2, "PLOTWATT", -1)
    end
  end
  
end


------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
function BidgelyUpload(timeStamp, newValue)
   
   if (DEBUG) then pwLog("BidgelyUpload Got update of " .. newValue .. " at " .. timeStamp)
   end

   -- the [[ are to delimit literal strings
   local XML_DATA = [[
      <upload version="1.0">
         <meters>
            <meter id="11:22:33:44:55:66" model="API" type="0" description="NAC API">
               <streams>
                  <stream id="InstantaneousDemand" unit="W" description="Real-Time Demand">
                     <data time="]] .. timeStamp .. [[" value="]] .. newValue .. [["/>
                  </stream>
               </streams>
            </meter>
         </meters>
      </upload>]]

   local response, status, header  = http.request{
      method = "POST",
      url = BG_URL,
      headers = {["Content-Type"] = "application/xml"},
      
      headers = {
         ["Content-Type"] = "application/xml",
         ["Content-Length"] = string.len(XML_DATA)
      },
      source = ltn12.source.string(XML_DATA),
      sink = ltn12.sink.table(response_body)
   }

   if (BOX_DEBUG) then
      --Show in the upper panel the time
      t = os.date('*t')
      luup.task(t.hour .. ":" .. t.min .. ":" .. t.sec .. " --  uploaded with status: #" .. status .. "#", 2, "BIDGELY", -1)
   end

end


------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
function WattvisionUpload(timeStamp, newValue)
  
  sensor_id = 22469802 
  api_id = 14tgrvo4e0drvas166qqjujxd7ciz8gt
  api_key = 0mcj77yrdkj8hz75yxewo0x8ojutonqk
  time = timeStamp
  watts = newValue
  watthours = 
  
  result, status = http.request("https://www.wattvision.com/api/v0.2/elec", "{"sensor_id":"XXXXXX","api_id":"XXXXXX","api_key":"XXXXXX","watts":1003}")  
  
end



initWatch()