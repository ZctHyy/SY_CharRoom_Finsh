#!/bin/bash
if [ -f ../cfg.ini ]; then
    source ../cfg.ini;
elif [ -f cfg.ini ]; then
    source ./cfg.ini;
else
    ERL=erl
    HOST=localhost
    ROOT_DIR=/data/practice.dev
    COOKIE=abdoc3
    MAKE_ARGS="[{d, debug}]"
fi
START_FILE=start.sh
## 命令行帮助
fun_help(){
    echo "-------------------------------------------"
    echo "请使用以下有效指令"
    echo "-------------------------------------------"
    echo "cfg           生成配置文件"
    echo "pull          拉各项目代码"
    echo "make          编译erlang代码"
    echo "start         启动服务 platform id"
    echo "setup         搭建服务区 platform id"
    echo "clean         清理已编译的模块"
    echo "stop          停止服务 platform id"
}

## 编译
fun_make(){
    cd ${ROOT_DIR}/server
    ${ERL} -eval "make:all(${MAKE_ARGS})" -s c q
}

## 清理编译结果
fun_clean(){
    echo "这里会报错，找下原因"
    rm -r ebin/*.beam
}

## 拉各库代码
fun_pull(){
    echo "还没实现"
}

## 搭建服务区
fun_setup(){
    if [ "$2" = "" ] || [ "$3" = "" ]; then
        echo "请输入平台和区号"
    else
        newHost=${ROOT_DIR}/zone/$2_$3
        if [ -d ${newHost} ]; then
            echo "目录已经存在"
        else
            mkdir -p ${newHost}/dets
            cp ${ROOT_DIR}/server/tpl/main.app ${newHost}/
            sed -i "" -e "s/<#zone_id#>/$3/g" ${newHost}/main.app
            sed -i "" -e "s/<#cookie#>/${COOKIE}/g" ${newHost}/main.app
            sed -i "" -e "s/<#platform#>/$2/g" ${newHost}/main.app
            sed -i "" -e "s/<#host#>/${HOST}/g" ${newHost}/main.app
            CMD="${ERL} -pa ${ROOT_DIR}/server/ebin  -name $2_$3@${HOST} -s main -setcookie ${COOKIE}"
            cat > ${newHost}/${START_FILE} <<EOF
#!/bin/bash
cd ${newHost} 
${CMD}
EOF
            chmod 755 ${newHost}/${START_FILE}
        fi
    fi
}


## 启动
fun_start(){
    if [ "$2" = "" ] || [ "$3" = "" ]; then
        echo "请输入平台和区号"
    else
        cd ${ROOT_DIR}/zone/$2_$3
        if $(in_cygwin); then
            werl -pa ${ROOT_DIR}/server/ebin  -name $2_$3@${HOST} -s main -setcookie ${COOKIE} &
        else
            screen -mLS $2_$3@${HOST} -s ${ROOT_DIR}/zone/$2_$3/${START_FILE}
            # erl -pa ${ROOT_DIR}/server/ebin  -name $2_$3@${HOST} -s main -setcookie ${COOKIE};
        fi
    fi
}

## 启动
fun_stop(){
    ${ERL} -name ostop_$2_$3@${HOST} -setcookie ${COOKIE} -eval "rpc:call('$2_$3@${HOST}', c, q, [])" -s c q
}

## 生成配置文件
fun_cfg(){
    cat > ../cfg.ini <<EOF
ERL=erl
HOST=localhost
ROOT_DIR=/data/practice.dev
COOKIE=abdoc3
MAKE_ARGS="[{d, debug}]"
# 如果在cygwin下工作请设置以下两个变量
# ROOT_DIR=d:/practice.dev
EOF
}

# 检测是否在cygwin环境中
in_cygwin(){
    local os=$(uname)
    [[ "${os:0:3}" == "CYG" ]]; return $?
}

## 执行入口
cmd=$1
case $cmd in
    cfg) fun_cfg;;
    clean) fun_clean;;
    start) fun_start $@;;
    make) fun_make;;
    stop) fun_stop $@;;
    setup) fun_setup $@;;
*) fun_help;;
esac

