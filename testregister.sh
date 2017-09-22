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

testRegister(){
    #curl -k -c emic_cookie   https://10.0.0.42:1066/auth/third/getVerify
	interface_uri="auth/third/getVerify"
	cxl_echo_info "测试接口${interface_uri}"
	result=`curl -s -k -c ${cookie_file} ${spi_uri}/${interface_uri}` && status=0 || status=1
	assertEquals "接口${interface_uri}失败" 0 $status
	if [ $status -gt 0 ]; then return; fi
	resultcheck=`echo "$result" | jq ".status"`
	assertNotEquals "不是合法的json文件" "null" "$resultcheck"
	assertEquals "返回status非0，接口失败" 0 "$resultcheck"
	verify=`echo "$result" | jq ".data.verify" | sed 's/"//g'`
	interface_uri="auth/third/register"
	cxl_echo_info "测试接口${interface_uri}"
	#curl -k  -d "account=spiauth&password=admin&verify=pPEL&redirect_uri=http://10.0.0.23:1045/Talk/ServerManager/setSpiAuthorize&grant_type=code&state=1501491927" https://10.0.0.42:1066/auth/third/register
	result=`curl -s -k -b ${cookie_file} -d "account=${spi_auth_account}&password=${spi_auth_pwd}&verify=${verify}&redirect_uri=${ep_uri}/Talk/ServerManager/setSpiAuthorize&grant_type=code&state=1501491927" ${spi_uri}/${interface_uri}` && status=0 || status=1
	assertEquals "接口${interface_uri}失败" 0 $status
	resultcheck=`echo "$result" | jq ".status"`
	assertNotEquals "不是合法的json文件" "null" "$resultcheck"
	assertEquals "返回status非0，接口失败" 0 "$resultcheck"
	redirectUrl=`echo "$result" | jq ".data.redirect_uri"`
	#{"status":0,"info":"调用接口成功","data":{"redirect_uri":"http:\/\/10.0.0.23:1045\/Talk\/ServerManager\/setSpiAuthorize?code=cfa19df0a5d2c84294ba6e48c2ed85da&client_id=7347cf568ed6cf687f60db0b5096d158&client_secret=53da916d3e10d05bcf8a774bc62db6e3&state=1501491927"}}
	#curl -v -k -H "ClientID:b0b610b7b6d29cce2eff34efb94daf95" -H "ClientSecret:68727c8cbf7f10e87282f15a6e74eb3e" -d "code=083afdd850621abc1838bc8e2a4e8bd7&grant_type=authorization_code&redirect_uri=http://10.0.0.23:1045/Talk/ServerManager/setSpiAuthorize&expire_span=86400&ep_token=ep_token&mt_uri=http://10.0.0.23:1046" https://10.0.0.42:1066/auth/third/authorize
	param=`echo "$redirectUrl" | awk -F '?' '{print $2}'`;
	clientId=`echo "$param" | awk -F '&' '{i=1;while(i<=NF){n=split($i,array,"=");if(array[1]=="client_id"){print array[2];break;};i++;}}'`;
	clientSecret=`echo "$param" | awk -F '&' '{i=1;while(i<=NF){n=split($i,array,"=");if(array[1]=="client_secret"){print array[2];break;};i++;}}'`;
	code=`echo "$param" | awk -F '&' '{i=1;while(i<=NF){n=split($i,array,"=");if(array[1]=="code"){print array[2];break;};i++;}}'`;
	assertTrue "client_id为空" "[ ! -z $clientId ]"
	assertTrue "clientSecret为空" "[ ! -z $clientSecret ]"
	assertTrue "code为空" "[ ! -z $code ]"
	if [ -z $clientId ]; then return; fi
	if [ -z $clientSecret ]; then return; fi
	if [ -z $code ]; then return; fi
	interface_uri="auth/third/authorize"
	cxl_echo_info "测试接口${interface_uri}"
	result=`curl -s -k -b ${cookie_file} -H "ClientID:$clientId" -H "ClientSecret:$clientSecret" -d "code=${code}&grant_type=authorization_code&redirect_uri=${ep_uri}/Talk/ServerManager/setSpiAuthorize&expire_span=86400&ep_token=ep_token&mt_uri=$mt_uri" ${spi_uri}/${interface_uri}` && status=0 || status=1
	assertEquals "接口${interface_uri}失败" 0 $status
	resultcheck=`echo "$result" | jq ".status"`
	assertNotEquals "不是合法的json文件" "null" "$resultcheck"
	assertEquals "返回status非0，接口失败" 0 "$resultcheck"
}

clear(){ :; } 

. ${shunit_dir}/shunit2