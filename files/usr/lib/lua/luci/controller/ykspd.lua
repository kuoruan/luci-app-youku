--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

module("luci.controller.ykspd", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/youku") then
		return
	end

	entry({"ykspd"}, call("spd"))
end

function spd()
	local running = (luci.sys.call("pidof ikuacc > /dev/null") == 0)
	if running then
		local spd = luci.sys.exec("/lib/spd")
		luci.http.prepare_content("application/json")
		luci.http.write_json({success = 1, data = spd })
	else
		luci.http.prepare_content("application/json")
		luci.http.write_json({success = 0, data = 'not working' })
	end
end
