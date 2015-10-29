--[[
Copyright 2015 kuoruan <kuoruan@qq.com>
Licensed to the public under the Apache License 2.0.
--]]

local uci   = require "luci.model.uci".cursor()
local jsonc = require "luci.jsonc"
-- jQuery库
local jquery = "<script src='http://libs.baidu.com/jquery/1.7.2/jquery.min.js'></script>"
-- AJAX
local ajax = "<script>setInterval(function(){$.get('/cgi-bin/luci/youkuspeed',function(s){if(1 == s.success){$('#speed').html(s.data)}},'json')},3000)</script>"
-- 根据MAC计算的S/N
local macsn = luci.sys.exec("echo 2115$(cat /sys/class/net/br-lan/address|tr -d ':'|md5sum |tr -dc [0-9]|cut -c 0-12)")
-- S/N
local sn = uci:get("youku", "general", "sn")
-- 绑定按钮
local bind = ""

-- 获取信息
local userjson = luci.sys.exec("curl -s http://pcdnapi.youku.com/pcdn/user/check_bindinfo?pid=0000$(uci get -q youku.general.sn)")
local creditjson = luci.sys.exec("curl -s http://pcdnapi.youku.com/pcdn/credit/summary?pid=0000$(uci get -q youku.general.sn)")

local user = jsonc.parse(userjson)
local credit = jsonc.parse(creditjson)
-- 绑定状态
local status = -1
if user ~= nil then
	status = user.code
end

if (luci.sys.call("pidof ikuacc > /dev/null") == 0) then
	local speed = luci.sys.exec("/lib/youku/youkuspeed")
	m = Map("youku", translate("优酷路由宝"), translate("正在工作中……").."<span id=\"speed\">"..speed.."</span>"..jquery..ajax)
elseif (luci.sys.call("pidof youkudome > /dev/null") == 0) then
	m = Map("youku", translate("优酷路由宝"), translate("正在预热，请稍后……"))
else
	m = Map("youku", translate("优酷路由宝"), translate("已停止工作……"))
end

s1 = m:section(TypedSection, "settings", translate("<a href=\"http://yjb.youku.com\" target=\"_blank\">点击进入官方金币平台>></a>"))
s1.anonymous = true

if (status == 0) then
	s1:tab("income", translate("Income"))
	s1:taboption("income", DummyValue, "cursn", "<strong>"..translate("当前使用的S/N: ").."</strong>").default = sn
	if(credit.code == 11) then --当前无数据
		o = s1:taboption("income", DummyValue, "nodata", "<strong>"..translate("无更多信息: ").."</strong>")
		o.default = translate("绑定新用户后需要第二天才能显示收益！")
	else
		o = s1:taboption("income", DummyValue, "username", "<strong>"..translate("已绑定的用戶 :").."</strong>")
		o.default = user.data.name
		o = s1:taboption("income", DummyValue, "today", "<strong>"..translate("今日收益: ").."</strong>")
		o.default = credit.data.credits_today
		o = s1:taboption("income", DummyValue, "lastday", "<strong>"..translate("昨日收益: ").."</strong>")
		o.default = credit.data.credits_lastday
		o = s1:taboption("income", DummyValue, "total", "<strong>"..translate("总收益: ").."</strong>")
		o.default = credit.data.total_credits
	end
elseif (status == 25) then
	local bdlink = luci.sys.exec("getykbdlink 0000$(uci get -q youku.general.sn)|sed -e's/&/&amp;/g'")
	bind = "<input type=\"button\" value=\""..translate("绑定优酷帐号").."\" onclick=\"window.open('".. bdlink .."')\" style=\"margin-left:20px;\">"
elseif (status == 10259) then
	bind = "<span style=\"margin-left:10px;font-weight:bold;color:red;\">"..translate("S/N格式不正确！").."</span>"
elseif (status == -1) then
	bind = "<span style=\"margin-left:10px;font-weight:bold;color:red;\">"..translate("请检查网络连接！").."</span>"
else
	bind = "<span style=\"margin-left:10px;font-weight:bold;color:red;\">"..translate("未知错误！").."</span>"
end

s1:tab("basic", translate("Settings"))

if (sn == nil) or (sn <= "0") then
	o = s1:taboption("basic", Flag, "enable", translate("启用矿机"), "<span style=\"font-weight:bold;color:red;\">"..translate("请输入正确的S/N！").."</span>")
	o.rmempty = false
else
	o = s1:taboption("basic", Flag, "enable", translate("启用矿机"), "<strong>"..translate("S/N: ").."</strong><font color=\"green\">"..sn.."</font>"..bind)
	o.rmempty = false
end

o = s1:taboption("basic", Value, "sn", translate("S/N"), translate("请输入S/N后保存，可以使用路由宝原版S/N"))
if sn ~= nil then
	o:value(sn)
end
o:value(macsn, macsn..translate("(根据MAC获得)"))

o = s1:taboption("basic", ListValue, "version", translate("插件版本"))
o:value("", translate("默认版本(211)"))
for _, p_ipk in luci.util.vspairs(luci.util.split(luci.sys.exec("ls $(uci get -q youku.@paths[0].path)/ikuacc |grep ikuacc|sed 's/ikuacc.//'"))) do
	if p_ipk ~= "" then
		o:value(p_ipk)
	end
end
for _, p_ipk in luci.util.vspairs(luci.util.split(luci.sys.exec("awk '{print$1}' /lib/youku/FILES"))) do
	if p_ipk ~= "" then
		o:value(p_ipk)
	end
end

o = s1:taboption("basic", ListValue, "mode", translate("挖矿模式"))
o:value("0", translate("激进模式：赚取收益优先"))
o:value("2", translate("平衡模式：赚钱上网兼顾"))
o:value("3", translate("保守模式：上网体验优先"))

o = s1:taboption("basic", Value, "reboot", translate("定时重启"), translate("定时重启，可以自定义重启时间，例：3点重启就输入0300即可，5点半重启就输入0530即可."))
o:value("", translate("不重启"))
o:value("0100", translate("凌晨1点"))
o:value("0245", translate("凌晨2点45"))
o:value("0300", translate("凌晨3点"))
s1:taboption("basic", Flag, "ikreboot", translate("只重启矿机"), translate("勾选表示只重启挖矿程序，不勾选则重启路由器。"))

s2 = m:section(TypedSection, "paths", translate("缓存目录"), translate("请在“系统-挂载点”里把磁盘挂载到/mnt目录下，缓存的大小是按1000MB=1GB算的，如7GB缓存空间就填写7000."))
s2.template = "cbi/tblsection"
s2.sortable = true
s2.anonymous = true
s2.addremove = true

pth = s2:option(Value, "path", translate("缓存文件路径"))
local p_user
for _, p_user in luci.util.vspairs(luci.util.split(luci.sys.exec("df|grep '/mnt/'|awk '{print$6}'"))) do
	if p_user ~= "" then
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
