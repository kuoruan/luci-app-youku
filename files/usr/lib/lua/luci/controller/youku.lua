module("luci.controller.youku", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/youku") then
		return
	end

	entry({"admin", "services", "youku"}, cbi("youku"), _("优酷路由宝")).dependent = true
end
