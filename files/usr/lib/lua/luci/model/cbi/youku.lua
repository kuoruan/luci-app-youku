--[[
LuCI - Lua Configuration Interface
youku for KOS
$Id$
]]--

local jq = "<script src='http://libs.baidu.com/jquery/1.7.2/jquery.min.js'></script>"
local ajax = "<script>setInterval(function(){$.get('/cgi-bin/luci/ykspd',function(s){if(1 == s.success){$('#ykspd').html(s.data)}},'json')},3000)</script>"
local kosqd = luci.http.formvalue("cbi.apply")
local opsn = luci.sys.exec("echo $(uci get -q youku.youku.opsn)")
local tog = luci.sys.exec("echo $(uci get -q youku.credits.today)")
local macsn = luci.sys.exec("echo 2115$(cat /sys/class/net/br-lan/address|tr -d ':'|md5sum |tr -dc [0-9]|cut -c 0-12)")
--昨日流量
local today_lastday = luci.sys.exec("echo $(uci get -q youku.credits.today_lastday)")
--上小时速度
local tog = luci.sys.exec("echo $(uci get -q youku.credits.today)")
--每小时收益
local oldday = luci.sys.exec("cat /etc/today")
local bd_button = ""
local sudu = luci.sys.exec("/lib/spd")
local running = (luci.sys.call("pidof ikuacc > /dev/null") == 0)
local run = (luci.sys.call("pidof youkudome > /dev/null") == 0)

luci.sys.exec("wget -O /tmp/user http://pcdnapi.youku.com/pcdn/user/check_bindinfo?pid=0000$(uci get -q youku.youku.opsn)")
luci.sys.exec("wget -O /tmp/day http://pcdnapi.youku.com/pcdn/credit/summary?pid=0000$(uci get -q youku.youku.opsn)")

local bdsn = luci.sys.exec("getykbdlink 0000$(uci get -q youku.youku.opsn)|sed -e's/&/&amp;/g'")
local bdzt = luci.sys.exec("cat /tmp/user |grep 'name'|cut -d '\"' -f 16")
local zt = luci.sys.exec("cat /tmp/user |cut -d '\"' -f 3|tr -dc [0-9]")
local today = luci.sys.exec("cat /tmp/day|cut -d '\"' -f 15|grep -Eo '[0-9]+'")
local lastday = luci.sys.exec("cat /tmp/day|cut -d '\"' -f 13|grep -Eo '[0-9]+'")
local total = luci.sys.exec("cat /tmp/day|cut -d '\"' -f 11|grep -Eo '[0-9]+'")

if running then
	m = Map("youku", translate("优酷路由宝"), translate("正在工作中……").."<span id='ykspd'>"..sudu.."</span>"..jq..ajax)
	else
if run then
	m = Map("youku", translate("优酷路由宝"), translate("<span id='ykspd'>正在预热，请稍后……</span>"))
	else
	m = Map("youku", translate("优酷路由宝"), translate("<span id='ykspd'>已停止工作……</span>"))
	end
end
if (zt == "25") then
	bd_button = "<input type=\"button\" value=\""..translate("绑定优酷帐号").."\" onclick=\"window.open('".. bdsn .."')\" style=\"margin-left:20px;\" />"
end

s = m:section(TypedSection, "youku", translate("<a href=\"http://yjb.youku.com\" target=\"_blank\">点击进入官方金币平台>></a>"))
s.anonymous = true
s:tab("income", translate("收益"))
s:tab("basic", translate("Settings"))

s:taboption("income", DummyValue, "sn", translate("<strong>当前正在使用的S/N: </strong>")).default = opsn
s:taboption("income", DummyValue, "bdzt", translate("<strong>绑定状态: </strong>")).default = bdzt
s:taboption("income", DummyValue, "today", translate("<strong>今日收益: </strong>")).default = today
s:taboption("income", DummyValue, "lastday", translate("<strong>昨日收益: </strong>")).default = lastday
s:taboption("income", DummyValue, "today_lastday", translate("<strong>昨日流量: </strong>")).default = today_lastday
s:taboption("income", DummyValue, "total", translate("<strong>总收益: </strong>")).default = total
s:taboption("income", DummyValue, "credits_today", translate("<strong>上小时速度: </strong>")).default = tog
s:taboption("income", DummyValue, "oldday", translate("<strong>每小时收益: </strong>")).default = oldday

if (opsn <= "0") then
	bdzt = ""
	o = s:taboption("basic", Flag, "enable", translate("是否启用矿机"))
	o.rmempty = false
else
	o = s:taboption("basic", Flag, "enable", translate("是否启用矿机"), "<strong>"..translate("S/N: ").."</strong><font color='green'>"..opsn.."</font>"..bd_button)
	o.rmempty = false
end

o = s:taboption("basic", Value, "opsn", translate("S/N"), translate("请输入S/N后保存，可以使用路由宝原版S/N"))
if opsn ~= "" then
	o:value(opsn)
	o:value(macsn, macsn..translate("(根据MAC获得)"))
end

xwareup = s:taboption("basic", ListValue, "VERSION", translate("插件版本"))
xwareup:value("", translate("默认版本(211)"))
for _, p_ipk in luci.util.vspairs(luci.util.split(luci.sys.exec("ls $(uci get -q youku.@path[0].path)/ikuacc |grep ikuacc|sed 's/ikuacc.//'"))) do
	if p_ipk ~= "" then
		xwareup:value(p_ipk)
	end
end
for _, p_ipk in luci.util.vspairs(luci.util.split(luci.sys.exec("awk '{print$1}' /lib/youku/FILES"))) do
	if p_ipk ~= "" then
		xwareup:value(p_ipk)
	end
end

o = s:taboption("basic", ListValue, "wkmod", translate("挖矿模式"))
o:value("0", translate("激进模式：赚取收益优先"))
o:value("2", translate("平衡模式：赚钱上网兼顾"))
o:value("3", translate("保守模式：上网体验优先"))

o = s:taboption("basic", Value, "cqboot", translate("定时重启"), translate("定时重启，可以自定义重启时间，例：3点重启就输入0300即可，5点半重启就输入0530即可."))
o:value("", translate("不重启"))
o:value("0100", translate("凌晨1点"))
o:value("0245", translate("凌晨2点45"))
o:value("0300", translate("凌晨3点"))
s:taboption("basic", Flag, "ikrebot", translate("只重启矿机"), translate("勾选表示只重启挖矿程序，不勾选则重启路由器。"))

s2 = m:section(TypedSection, "path", translate("缓存文件"), translate("请在“系统-挂载点”里把磁盘挂载到/mnt目录下，缓存的大小是按1000MB=1GB算的，如7GB缓存空间就填写7000."))
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

o = s2:option(Value, "pathhc", translate("缓存目录大小限制"))
o:value("", translate("保持默认"))
o:value("1000", translate("1GB缓存"))
o:value("2000", translate("2GB缓存"))
o:value("7000", translate("7GB缓存"))
o:value("14000", translate("14GB缓存"))
o:value("28000", translate("28GB缓存"))
o:value("56000", translate("56GB缓存"))

btnrm = s2:option(Button, "remove", translate("清空缓存"))
btnrm.render = function(self, section, scope)
	self.inputstyle = "清空缓存"
	Button.render(self, section, scope)
end

btnrm.write = function(self, section, scope)
	luci.sys.exec("rm -rf %s/youku/youkudisk" % m:get(section, "path"))
end
return m
