module("luci.controller.youku-info", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/youku") then
		return
	end

	entry({"youku-info"}, call("getinfo"))
end

function getinfo()
	if (luci.sys.call("pidof ikuacc > /dev/null") == 0) then
		local info = luci.sys.exec("/etc/youku/youku-info")
		luci.http.prepare_content("application/json")
		luci.http.write_json({success = 1, data = info })
	else
		luci.http.prepare_content("application/json")
		luci.http.write_json({success = 0, data = 'Not working' })
	end
end
