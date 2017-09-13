#! /bin/bash
# file: testlogin.sh
# author: chenxuelin@emicnet.com
# feature: 测试登录

. helper

CALLER=`basename $0`      # 主程序名称

init(){ :; } 

testConnect(){
	cxl_echo_info "测试是否能连接到SPI服务器"
	result=`curl -s -k -c ${cookie_file} ${spi_uri}` && status=0 || status=1
	assertEquals "not connect to spi server" 0 $status
	if [ $status -gt 0 ]
	then
		cxl_echo_fail "无法连接到SPI服务器,退出"
		exit 2;
	fi
	result=`echo "$result" | jq ".status"`
	assertNotEquals "不是合法的json文件" "null" "$result"
	assertEquals "返回status非0，接口失败" 0 "$result"
}

testlogin(){
    #curl -k -c emic_cookie   https://10.0.0.42:1066/auth/third/getVerify
	interface_uri="/auth/third/getVerify"
	cxl_echo_info "测试接口${interface_uri}"
	result=`curl -s -k -c ${cookie_file} ${spi_uri}/${interface_uri}` && status=0 || status=1
	assertEquals "接口${interface_uri}失败" 0 $status
	if [ $status -gt 0 ]; then return; fi
	resultcheck=`echo "$result" | jq ".status"`
	assertNotEquals "不是合法的json文件" "null" "$resultcheck"
	assertEquals "返回status非0，接口失败" 0 "$resultcheck"
	verify=`echo "$result" | jq ".data.verify" | sed 's/"//g'`
	interface_uri="/auth/local/login"
	cxl_echo_info "测试接口${interface_uri}"
	#curl -k -b emic_cookie  -d "account=spiadmin&password=admin&verify=SWKo" https://10.0.0.42:1066/auth/local/login
	result=`curl -s -k -b ${cookie_file} -d "account=${spi_login_account}&password=${spi_login_pwd}&verify=${verify}" ${spi_uri}/${interface_uri}` && status=0 || status=1
	assertEquals "接口${interface_uri}失败" 0 $status
	resultcheck=`echo "$result" | jq ".status"`
	assertNotEquals "不是合法的json文件" "null" "$resultcheck"
	assertEquals "返回status非0，接口失败" 0 "$resultcheck"
}

clear(){ :; } 

. ${shunit_dir}/shunit2