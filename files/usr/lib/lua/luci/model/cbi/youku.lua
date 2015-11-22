--[[
Copyright 2015 kuoruan <kuoruan@gmail.com>
Licensed to the public under the Apache License 2.0.
--]]

local jsonc = require "luci.jsonc"
local function isempty(obj)
  return obj == nil or obj == ""
end
-- 根据MAC计算的S/N
local macsn = luci.sys.exec("echo 2115$(cat /sys/class/net/br-lan/address|tr -d ':'|md5sum |tr -dc [0-9]|cut -c 0-12)")
-- S/N
local sn = luci.sys.exec("uci -q get youku.config.sn")
-- 提示信息
local notice = ""
local sbtn = ""
-- 状态
local status = -1
-- 获取信息
luci.sys.exec("wget -qO /tmp/user http://pcdnapi.youku.com/pcdn/user/check_bindinfo?pid=0000"..sn)
luci.sys.exec("wget -qO /tmp/credit http://pcdnapi.youku.com/pcdn/credit/summary?pid=0000"..sn)

local user = jsonc.parse(luci.sys.exec("cat /tmp/user"))

if not isempty(user) then
	status = user.code
end

if (luci.sys.call("pidof ikuacc > /dev/null") == 0) then
	local speed = luci.sys.exec("/etc/youku/youku-info")
	m = Map("youku", translate("优酷路由宝"), translate("正在运行...").."<span id=\"speed\">"..speed.."</span>")
	local link = luci.sys.exec("printf http://$(uci -q get network.lan.ipaddr):8908/peer/config/config.htm")
	sbtn = "<input type=\"button\" value=\""..translate("详细设置").."\" onclick=\"window.open('"..link.."')\" style=\"margin-left:10px;\" />"
elseif (luci.sys.call("pidof youku-main > /dev/null") == 0) then
	m = Map("youku", translate("优酷路由宝"), "<span id=\"speed\">"..translate("正在准备，请稍候...").."</span>")
else
	m = Map("youku", translate("优酷路由宝"), "<span id=\"speed\">"..translate("已停止...").."</span>")
end

m.redirect = luci.dispatcher.build_url("admin/services/youku")
s1 = m:section(TypedSection, "youku", translate("<a href=\"http://yjb.youku.com\" target=\"_blank\">点击进入官方金币平台&gt;&gt;</a>")..sbtn)
s1.template = "youku/tsection"
s1.anonymous = true

if (status == 0) then
	s1:tab("info", translate("信息"))
	cursn = s1:taboption("info", DummyValue, "cursn", translate("当前使用的S/N:"))
	cursn.template = "youku/dvalue"
	cursn.default = sn
	name = s1:taboption("info", DummyValue, "name", translate("已绑定的用戶:"))
	name.template = "youku/dvalue"
	name.default = user.data.name
elseif (status == 25) then
	local bdlink = luci.sys.exec("getykbdlink 0000$(uci -q get youku.config.sn)|sed -e's/&/&amp;/g'")
	notice = "<input type=\"button\" value=\""..translate("绑定优酷帐号").."\" onclick=\"window.open('".. bdlink .."')\" style=\"margin-left:10px;\" />"
elseif (status == 10259) then
	notice = "<span style=\"margin-left:10px;font-weight:bold;color:red;\">"..translate("S/N格式错误！").."</span>"
elseif (status == -1) then
	notice = "<span style=\"margin-left:10px;font-weight:bold;color:red;\">"..translate("请检查网络连接！").."</span>"
else
	notice = "<span style=\"margin-left:10px;font-weight:bold;color:red;\">"..user.text.."</span>"
end

s1:tab("config", translate("设置"))

if isempty(sn) or (sn <= "0") then
	o = s1:taboption("config", Flag, "enable", translate("启用"), "<span style=\"font-weight:bold;color:red;\">"..translate("S/N不能为空或者负数！").."</span>")
	o.rmempty = false
else
	o = s1:taboption("config", Flag, "enable", translate("启用"), "<strong>"..translate("S/N: ").."</strong><font color=\"green\">"..sn.."</font>"..notice)
	o.rmempty = false
end

o = s1:taboption("config", Value, "sn", translate("S/N"), translate("请输入S/N后保存，可以使用路由宝原版S/N"))
if not isempty(sn) then
	o:value(sn)
end
o:value(macsn, macsn..translate("(根据MAC获得)"))

o = s1:taboption("config", ListValue, "version", translate("插件版本"))
o:value("", translate("1.5.0211.47252(默认)"))
for _, p_ipk in luci.util.vspairs(luci.util.split(luci.sys.exec("ls $(uci -q get youku.@paths[0].path)/ikuacc |grep ikuacc|sed 's/ikuacc.//'"))) do
	if isempty(p_ipk) == false then
		o:value(p_ipk)
	end
end
for _, p_ipk in luci.util.vspairs(luci.util.split(luci.sys.exec("awk '{print $1}' /etc/youku/FILES"))) do
	if not isempty(p_ipk) then
		o:value(p_ipk)
	end
end

o = s1:taboption("config", ListValue, "mode", translate("挖矿模式"))
o:value("0", translate("激进模式：赚取收益优先"))
o:value("2", translate("平衡模式：赚钱上网兼顾"))
o:value("3", translate("保守模式：上网体验优先"))

o = s1:taboption("config", Value, "restart", translate("定时重启"), translate("定时重启，可以自定义重启时间，例：3点重启就输入0300即可，5点半重启就输入0530即可."))
o:value("", translate("不重启"))
o:value("0100", translate("凌晨1点"))
o:value("0245", translate("凌晨2点45"))
o:value("0300", translate("凌晨3点"))
s1:taboption("config", Flag, "ikrestart", translate("只重启矿机"), translate("勾选表示只重启挖矿程序，不勾选则重启路由器。"))

s2 = m:section(TypedSection, "paths", translate("缓存目录"), translate("请在“系统-挂载点”里把磁盘挂载到/mnt目录下，缓存的大小是按1000MB=1GB算的，如7GB缓存空间就填写7000."))
s2.template = "cbi/tblsection"
s2.sortable = true
s2.anonymous = true
s2.addremove = true

pth = s2:option(Value, "path", translate("缓存文件路径"))
local p_user
for _, p_user in luci.util.vspairs(luci.util.split(luci.sys.exec("df|grep '/mnt/'|awk '{print$6}'"))) do
	if not isempty(p_user) then
		pth:value(p_user)
	end
end

cache = s2:option(Value, "cache", translate("缓存目录大小限制"))
cache:value("", translate("保持默认"))
cache:value("1000", translate("1GB缓存"))
cache:value("2000", translate("2GB缓存"))
cache:value("7000", translate("7GB缓存"))
cache:value("14000", translate("14GB缓存"))
cache:value("28000", translate("28GB缓存"))
cache:value("56000", translate("56GB缓存"))

clear = s2:option(Button, "clear", translate("清空缓存"))
clear.render = function(self, section, scope)
	self.inputstyle = "清空缓存"
	Button.render(self, section, scope)
end

clear.write = function(self, section, scope)
	luci.sys.exec("rm -rf %s/youku/youkudisk" % m:get(section, "path"))
end
return m
