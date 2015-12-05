# luci-app-youku
OpenWrt 优酷挖矿扩展，适用于MTK7620A(N)

参考了网上许多挖矿扩展，整合功能，完善界面

### 2015年12月5日 ###
* 经本人测试，最新trunk源码无法编译使用本挖矿插件，因为官方现在将默认的c库从uClibc切换到了musl [Advanced configuration options (for developers) ---> Toolchain Options ---> C Library implementation (Use (e)glibc)],在找到切换回去的方法之前，是无法在trunk版本使用的，推荐用BB或者CC编译。

### 2015年11月22日
* 将不规范的"uci get -q"全部改为"uci -q get"命令，现在Openwrt最新版也能使用了
* 官方trunk默认不能编译libthread-db，编译本插件时会因为依赖不足而无法在Luci中显示，~~建议编译前修改目录下的Makefile文件的DEPENDS这一行，去掉"+libthread-db"之后编译，编译完之后安装我这里提供的libthread-db~~

### 2015年11月3日
* 再改版，许多小优化，感觉像是做了无用功...
* 现在大家可以尝试安装挖矿试试！
* 感谢恩山网友 @lucktu @andrewm10 大力支持

### 2015年11月2日
* ~~大家暂时别用，挂了两天没收益，我正在排查问题~~
* 由于本人宽带无法获取外网IP，不知道能不能正常挖矿，希望能收到各位的反馈
* 有没有谁有优酷路由宝真机啊，求联系...<kuoruan@gmail.com>
* 反馈地址：http://www.right.com.cn/forum/thread-177764-1-1.html

### 2015年10月29日
* 去除实时统计;
* 优化程序,使用jsonc解析数据,~~大幅降低占用~~;
* 更新文件目录,修改部分文件名;
* 去除无用内容.
