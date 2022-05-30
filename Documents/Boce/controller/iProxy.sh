#! /bin/bash
#支持 help install uninstall reload add remove(-help -install -uninstall -reload -add -remove)命令

execute_func=$0
#execute_func 为 -bash时 是source执行？
opreation_name=$1
param=$2
sh_model="bash_model"


##############common function
function get_no_proxy_array(){
    filter_file=$1
    no_proxy_str=`cat $filter_file |grep no_proxy=`
    no_proxy_str_filter=${no_proxy_str#*=}
    #保存旧的分隔符
    OLD_IFS="$IFS" 
    IFS=","
    array=($no_proxy_str_filter)
    # 将IFS恢复成原来的
    IFS="$OLD_IFS" 
    echo ${array[*]}    
}

function array2str(){
    array=($1)
    connect_char=$2    
    for i in "${!array[@]}"; do
        if [ $i = 0 ]
        then        
            str=${array[$i]};
        else
            str=$str$connect_char${array[$i]};
        fi
    done
    echo $str
}

function update_no_proxy(){
    no_proxy_str=$1
    opreation_name=$2
    domain_name=$3
    #/etc/profile用于login shell;/etc/bashrc用于non-login shell
    config_files=('/etc/profile' '/etc/bashrc') 

    for config_file in ${config_files[@]}
    do
        #备份之前的配置
        backup_file $config_file

        #清理之前的配置
        sed -i '/^no_proxy=/d'  $config_file

        #配置        
        echo "no_proxy="$no_proxy_str"" >> $config_file

        #使配置生效
        #echo $config_file
        source $config_file
    done
    if [ -z $domain_name ]
    then
        echo $opreation_name" no_proxy success!"
    else
        printf "%s no_proxy(%s) success!\n" $opreation_name $domain_name
    fi
}

function get_current_timestr(){
    echo $(date "+%Y%m%d%H%M%S")
}

function backup_file(){
    file_name=$1
    cp $file_name $file_name"_bak_""`get_current_timestr`"  2>/dev/null 
}

function mv_file(){
    file_name=$1
    mv $file_name $file_name"_mv_bak_""`get_current_timestr`"  2>/dev/null 
}

function backup_config_file(){
    config_files=('/etc/profile' '/etc/bashrc') 

    for config_file in ${config_files[@]}
    do
        #备份之前的配置
        backup_file $config_file
    done
}

function download_enable_script(){
    #备份之前的配置
    backup_config_file
    wget "http://download.devcloud.oa.com/enable_internet_proxy.sh"    
}

function download_disable_script(){
    #备份之前的配置
    backup_config_file
    wget "http://download.devcloud.oa.com/disable_internet_proxy.sh"    
}

function get_no_proxy_array_from_enable_script(){
    temp_all=`cat enable_internet_proxy.sh |grep 'no_proxy="'`
    #去掉前一截
    temp_r=${temp_all#*=\"}
    #去掉后一截
    ret=${temp_r%%\"*}

    #保存旧的分隔符
    OLD_IFS="$IFS" 
    IFS=","
    array=($ret)
    # 将IFS恢复成原来的
    IFS="$OLD_IFS" 
    echo ${array[*]} 
}

function get_diff_array(){
    #对比no_proxy_array_online 和 no_proxy_array_local，找到no_proxy_array_local中存在no_proxy_array_online没有的。认为是用户自己配置的no_proxy_array_user
    #求差集，array_1中有，array_2中没有的
    array_1=($1)
    array_2=($2) 
    ret=()
    for item in ${array_1[@]}
    do
        exists_flag=false
        for entity in ${array_2[@]}
        do
            if [ $item = $entity ]
            then                
                exists_flag=true
                break
            fi
        done

        if [ $exists_flag = false ]
        then            
            ret[${#ret[*]}]=$item
        fi
    done
    echo ${ret[*]}
}

function has_set_no_proxy(){
    #判断是否设置过no_proxy
    proxy_file="/etc/profile"
    no_proxy_array_local=(`get_no_proxy_array $proxy_file`)
    if [ ${#no_proxy_array_local[*]} = 0 ]
    then
        echo "no"
    else
        echo "ok"
    fi
}

function is_sh_exec(){
    exec_param=$1
    exec_param_check=$2
    if [[ $exec_param == *$exec_param_check* ]]
    then
      echo "ok"
    else
      echo "no"
    fi
}

function get_shell_model(){
    # 如果是zsh，暂时识别不了，先忽略sh or source
    _shell="$(ps -p $$ --no-headers -o comm=)"
    if [ $_shell = "zsh" ]
    then		
        echo "zsh_model"
    else 	
	    echo "bash_model"        
    fi
}

###############


function help_func(){
    echo "List of Commands:"
	echo "Please use bash to execute (请使用bash模式执行)"
    echo ""
    printf "%-15s" "install"
    printf "%s\n" "Enable devnet proxy (开启外网devnet代理)"
    printf "%-15s" "uninstall"
    printf "%s\n" "Disable devnet proxy (关闭外网devnet代理)"
    printf "%-15s" "remove"
    printf "%s\n" "Remove no_proxy domain  for example: remove mirrors.cloud.tencent.com (删除no_proxy域名 例如：remove  a.b.com)"
    printf "%-15s" "add"
    printf "%s\n" "Add no_proxy domain  for example: add mirrors.cloud.tencent.com (增加no_proxy域名 例如：add  a.b.com)"
    printf "%-15s" "reload"
    printf "%s\n" "Updating the no_proxy domain，domain with user-defined settings will be retained (更新no_proxy域名，自定义设置的域名将保留)"
    printf "%-15s" "help"
    printf "%s\n" "Help guide (帮助指引)"

    printf "\n"
    printf "Options:\n\n"

    printf "%-15s" "-install"
    printf "%s\n" "Enable devnet proxy (开启外网devnet代理)"
    printf "%-15s" "-uninstall"
    printf "%s\n" "Disable devnet proxy (关闭外网devnet代理)"
    printf "%-15s" "-remove"
    printf "%s\n" "Remove no_proxy domain  for example: remove mirrors.cloud.tencent.com (删除no_proxy域名 例如：-remove  a.b.com)"
    printf "%-15s" "-add"
    printf "%s\n" "Add no_proxy domain  for example: add mirrors.cloud.tencent.com (增加no_proxy域名 例如：-add  a.b.com)"
    printf "%-15s" "-reload"
    printf "%s\n" "Updating the no_proxy domain，domain with user-defined settings will be retained (更新no_proxy域名，自定义设置的域名将保留)"
    printf "%-15s" "-help"
    printf "%s\n\n" "Help guide (帮助指引)"

    printf "%-15s" "--install"
    printf "%s\n" "Enable devnet proxy (开启外网devnet代理)"
    printf "%-15s" "--uninstall"
    printf "%s\n" "Disable devnet proxy (关闭外网devnet代理)"
    printf "%-15s" "--remove"
    printf "%s\n" "Remove no_proxy domain  for example: remove mirrors.cloud.tencent.com (删除no_proxy域名 例如：--remove  a.b.com)"
    printf "%-15s" "--add"
    printf "%s\n" "Add no_proxy domain  for example: add mirrors.cloud.tencent.com (增加no_proxy域名 例如：--add  a.b.com)"
    printf "%-15s" "--reload"
    printf "%s\n" "Updating the no_proxy domain，domain with user-defined settings will be retained (更新no_proxy域名，自定义设置的域名将保留)"
    printf "%-15s" "--help"
    printf "%s\n\n" "Help guide (帮助指引)"

}

#开启代理
function install_func(){
    #先删除已存在的enable_internet_proxy.sh脚本
    #rm enable_internet_proxy.sh -f
    mv_file "enable_internet_proxy.sh"
    `download_enable_script` && source  ./enable_internet_proxy.sh    
}

#关闭代理
function uninstall_func(){
    #先删除已存在的enable_internet_proxy.sh脚本
    #rm enable_internet_proxy.sh -f
    mv_file "disable_internet_proxy.sh"
    `download_disable_script` && source  ./disable_internet_proxy.sh    
}

#删除某个no_proxy配置
function remove_func(){
    remove_domain=$1
    if [ -z $remove_domain ]
    then
        echo "Params error! Please enter the domain name to be deleted, for example: source iProxy.sh remove xx.oa.com"
    else 
        #判断是否设置过no_proxy
        has_set_no_proxy=`has_set_no_proxy`
        if [ $has_set_no_proxy = "no" ]
        then
            echo "The internet proxy has not been set yet. Please use the install command to enable internet proxy first.(还没设置过代理，请先使用install命令设置代理)"
        else    
            filter_file="/etc/profile"
            #要用括号包起来，带下标的循环才认为是数组！
            no_proxy_array=(`get_no_proxy_array $filter_file`)
            
            #for item in ${no_proxy_array[@]}        
            for (( i=0;i<${#no_proxy_array[@]};i++)) 
            do                      
                if [ ${no_proxy_array[$i]}"x" = $remove_domain"x" ]
                then                          
                    unset no_proxy_array[$i]
                    #为了删除干净
                    no_proxy_array=(${no_proxy_array[*]})
                    i=-1
                fi
            done
            
            #for i in "${!no_proxy_array[@]}";  
            #do 
            #    echo ${no_proxy_array[$i]}            
            #done
            
            connect_char=","
            no_proxy_str=`array2str "${no_proxy_array[*]}" $connect_char`
            #更新no_proxy
            update_no_proxy $no_proxy_str "remove" $remove_domain         
        fi
    fi
}

#no_proxy配置增加一个
function add_func(){
    add_domain=$1
    if [ -z $add_domain ]
    then
        echo "Params error! Please enter the domain name to be added, for example: source iProxy.sh add xx.oa.com"
    else   
        #判断是否设置过no_proxy
        has_set_no_proxy=`has_set_no_proxy`
        if [ $has_set_no_proxy = "no" ]
        then
            echo "The internet proxy has not been set yet. Please use the install command to enable internet proxy first.(还没设置过代理，请先使用install命令设置代理)"
        else 
            #都统一
            filter_file="/etc/profile"
            #要用括号包起来，带下标的循环才认为是数组！
            no_proxy_array=(`get_no_proxy_array $filter_file`)
            
            #先判断有没有，如果有就直接成功
            is_in_no_proxy=false
            for (( i=0;i<${#no_proxy_array[@]};i++))
            do            
                if [ ${no_proxy_array[$i]}"x" = $add_domain"x" ]
                then                
                    is_in_no_proxy=true
                fi
            done
            
            if [ $is_in_no_proxy = true ]
            then
                #已经有了，不用加
                echo "add no_proxy success!(already exists)"
            else
                no_proxy_array[${#no_proxy_array[*]}]=$add_domain
                connect_char=","
                no_proxy_str=`array2str "${no_proxy_array[*]}" $connect_char`
                #echo $no_proxy_str
                #更新no_proxy
                update_no_proxy $no_proxy_str "add" $add_domain    
            fi  
        fi              
    fi
}

#reload线上no_proxy配置，且保留用户设置的
function reload_func(){
    proxy_file="/etc/profile"
    #判断是否设置过no_proxy
    has_set_no_proxy=`has_set_no_proxy`
    if [ $has_set_no_proxy = "no" ]
    then
        echo "The internet proxy has not been set yet. Please use the install command to enable internet proxy first.(还没设置过代理，请先使用install命令设置代理)"
    else
        #“删除”本地的enable_internet_proxy.sh
        mv_file "enable_internet_proxy.sh" 
        #下载新的enable_internet_proxy.sh
        `download_enable_script`
        #找到enable_internet_proxy.sh 脚本中的no_proxy配置，并解析为数组no_proxy_array_online
        no_proxy_array_online=`get_no_proxy_array_from_enable_script`
        #找到本地/etc/profile中的no_proxy配置，并解析为数组no_proxy_array_local,前面已取
        no_proxy_array_local=(`get_no_proxy_array $proxy_file`)

        #对比no_proxy_array_online 和 no_proxy_array_local，找到no_proxy_array_local中存在no_proxy_array_online没有的。认为是用户自己配置的no_proxy_array_user
        no_proxy_array_user=`get_diff_array "${no_proxy_array_local[*]}" "${no_proxy_array_online[*]}"`        
        
        #no_proxy_array_online + no_proxy_array_user 设置为当前的no_proxy      
        no_proxy_array_current=(${no_proxy_array_online[@]} ${no_proxy_array_user[@]})

        connect_char=","
        no_proxy_str=`array2str "${no_proxy_array_current[*]}" $connect_char`
        #更新no_proxy
        update_no_proxy $no_proxy_str "reload"
    fi         
}

sh_model=`get_shell_model`
if [ $sh_model = "zsh_model" ]
then
    echo "请使用bash模式执行该脚本！"
	return
fi
is_source_exec=`is_sh_exec ${execute_func} "bash"`

if [ -z ${opreation_name} ]
then
    help_func
elif ([ ${opreation_name} != "help" ] && [ ${opreation_name} != "-help" ] && [ ${opreation_name} != "--help" ]) && [ ${is_source_exec} != 'ok' ]
then
    echo "Please execute the iProxy script with 'source' instead of 'sh'!(请用 source 执行iProxy脚本，请勿使用 sh 执行)"
else
    case $opreation_name in
        'help')
                help_func
        ;;
        '-help')
                help_func
        ;;
        '--help')
                help_func
        ;;
        'install')
                install_func
        ;;
        '-install')
                install_func
        ;;
        '--install')
                install_func
        ;;
        'uninstall')
                uninstall_func
        ;;
        '-uninstall')
                uninstall_func
        ;;
        '--uninstall')
                uninstall_func
        ;;
        'remove')
                remove_func $param
        ;;
        '-remove')
                remove_func $param
        ;;
        '--remove')
                remove_func $param
        ;;
        'add')
                add_func $param
        ;;
        '-add')
                add_func $param
        ;;
        '--add')
                add_func $param
        ;;
        'reload')
                reload_func
        ;;
        '-reload')
                reload_func
        ;;
        '--reload')
                reload_func
        ;;
        *)
        echo "unkonwn command,please input correct command!";
        #exit;
    esac
fi



