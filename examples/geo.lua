--
--  luaRT geo.lua example
--  Find the location where you currently are
--
local net = require "net" 

-- use a free GEOIP localization web API
local url = "https://freegeoip.app"
local client = net.Http(url)
-- make a GET request, returning the response as a string
local uri = "/json/"
local response = client:get(uri)

-- parse the response (a JSON string)
print("You are located in "..response:match('"country_name":"(%w+)"').." near "..response:match('"city":"(%w+)"'))