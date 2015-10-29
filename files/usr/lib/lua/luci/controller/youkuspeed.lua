module("luci.controller.youkuspeed", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/youku") then
		return
	end

	entry({"youkuspeed"}, call("speed"))
end

function speed()
	if (luci.sys.call("pidof ikuacc > /dev/null") == 0) then
		local speed = luci.sys.exec("/lib/youku/youkuspeed")
		luci.http.prepare_content("application/json")
		luci.http.write_json({success = 1, data = speed })
	else
		luci.http.prepare_content("application/json")
		luci.http.write_json({success = 0, data = 'not working' })
	end
end
