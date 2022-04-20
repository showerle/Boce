#!/bin/bash

#清理之前的配置

#/etc/profile用于login shell;/etc/bashrc用于non-login shell
config_files=('/etc/profile' '/etc/bashrc')
for config_file in ${config_files[@]}
do	
	sed -i '/^http_proxy=/d'  $config_file
	sed -i '/^https_proxy=/d'  $config_file
	sed -i '/^ftp_proxy=/d'  $config_file
	sed -i '/^no_proxy=/d'  $config_file
	sed -i '/^#这里no_proxy/d'  $config_file

	sed -i '/^export http_proxy/d'  $config_file
	sed -i '/^#curl和wget等/d'  $config_file


	unset http_proxy
	unset https_proxy
	unset ftp_proxy
done

echo "disable internet proxy success!"


