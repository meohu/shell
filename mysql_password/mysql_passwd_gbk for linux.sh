#! /bin/bash
############################################
# mysql�����޸Ľű�         
#
#2013-09-03 by ����
#version:1.1
#ʹ�÷�����
#����./mysql_paswd.sh -u �˺� -p ���� -s -x 
#
#ѡ��˵����
# -u(ѡ��) :mysql�˺ţ�Ĭ��Ϊroot 
# -p(����) :mysql���� 
# -s(ѡ��) :��ѯ��ǰmysqlԶ������Ȩ�� 
# -x(ѡ��) :����mysqlԶ������Ȩ��         
#
#2014-04-22
#version:1.1
#�޸����°�һ����װ��mysql��·�����
#
############################################

clear
###ͨ��mysql���̲���mysql·����
mysql_find_proc()
{
###�浵IFS��ȡ�س����ָ�����
IFS_tmp=$IFS
IFS=${IFS:2:1}
mysql_path_tmp=$(ps x|grep mysqld|grep -E -v "grep|${0##*/}")
IFS=${IFS_tmp}
###��ȡmysql����·��
mysql_path=$(echo ${mysql_path_tmp%/bin/mysqld_safe*}|awk '{print $NF}')
}

###ȷ�������Ƿ���ڣ���ʾ����is_path
mysql_is_path()
{
if [ -n "${mysql_path}" ]; then
 is_path=1
else
 is_path=0
fi
}

###mysql���̲�����ʱ��ͨ���ļ�����mysql·��
mysql_find_file()
{
if [ "${is_path}" -eq 0 ]; then
 echo -e "\033[34m��ǰmysqlû����������������mysql...\033[0m"
 mysql_path=$(cat /etc/my.cnf |grep basedir|awk '{print $NF}')
 if [ -f "/alidata/server/mysql/bin/mysqld_safe" ];then
  /etc/init.d/mysqld start
  sleep 2
  mysql_find_proc
  mysql_is_path
 else
  echo -e "\033[34m���Բ���mysql·����ʱ��ϳ������Ե�...\033[0m"
  mysql_file_tmp=$(find / -name "mysql.server"|grep "alidata"|tail -1)
  if [ -n "${mysql_file_tmp}" ]; then
   for start_test in ${mysql_file_tmp}
   do
    echo "��������mysql·����${start_test}"
    ${start_test} start
    sleep 2
    mysql_find_proc
    mysql_is_path
   if [ "${is_path}" -eq 1 ]; then
    echo -e "\033[32mmysql�����ɹ�\033[0m\n"
    break
   fi
   done
  else
   mysql_file_tmp=$(find / -name "mysqld_safe"|grep "bin/mysqld_safe")
   mysql_path={mysql_file_tmp%/bin/mysqld_safe*}
   if [ -f "${mysql_path}/bin/mysqld_safe" ];then
    ${mysql_path}/bin/mysqld_safe &
    sleep 2
    mysql_find_proc
    mysql_is_path
   fi
   if [ -z "${mysql_path}" ]; then
    echo -e "\033[31mû���ҵ�mysql·�������ֶ��޸����롣\033[0m"
    exit
   fi
  fi
  if [ "${is_path}" -ne 1 ]; then
   echo -e "\033[31mmysql����ʧ��\033[0m"
   echo -e "\033[31m�޸�ʧ�ܣ����ֶ��޸����롣\033[0m"
   exit
  fi
 fi
fi 
}

###ֹͣmysql����
mysql_stop()
{
echo -e "\033[34mmysql�ر���...\033[0m"
mysql_file_tmp=${mysql_path}
if [ -f "${mysql_file_tmp}/bin/mysqld_safe" ];then
 /etc/init.d/mysqld stop
 sleep 3
else
 echo -e "\033[31mֹͣʧ��\033[0m"
 echo -e "\033[31m�޸�ʧ�ܣ����ֶ��޸����롣\033[0m"
 exit
fi
}

###����Ȩ������
mysql_skip_grant()
{
mysql_stop
echo -e "\n\033[34mmysql����Ȩ��������...\033[0m"

if [ -f "${mysql_path}/bin/mysqld_safe" ];then
 sed -i 's/^\[mysqld\]/&\nskip-grant-tables #jinxiang_mysqlpasswd/' /etc/my.cnf
 /etc/init.d/mysqld start
 sleep 3
 mysql_find_proc
 mysql_is_path
else
 echo -e "\033[31m����Ȩ������ʧ��\033[0m\n"
 echo -e "\033[31m�޸�ʧ�ܣ����ֶ��޸����롣\033[0m"
 exit
fi
if [ "${is_path}" -eq 1 ]; then
 echo -e "\033[32m����Ȩ�������ɹ�\033[0m\n"
else
 echo -e "\033[31m����Ȩ������ʧ��\033[0m\n"
 echo -e "\033[31m�޸�ʧ�ܣ����ֶ��޸����롣\033[0m"
 exit
fi
}

###����ִ���ж�
mysql_succ_fail()
{
if [ "$?" -eq 0 ]; then
 echo -e "\033[32mִ�гɹ�\033[0m\n"
else
 echo -e "\033[31mִ��ʧ��\033[0m\n"
 echo -e "\033[31m�޸�ʧ�ܣ����ֶ��޸����롣\033[0m\n"
 exit
fi
}

###�޸����룬ˢ��Ȩ��
mysql_update_passwd()
{
echo -e "\n\033[34m�޸����룬ˢ��Ȩ��...\033[0m"
if [ -f "${mysql_path}/bin/mysql" ];then
 ${mysql_path}/bin/mysql -e "update mysql.user set password=PASSWORD('${mysql_passwd}') where user='${mysql_user}'" && \
 ${mysql_path}/bin/mysql -e "flush privileges"
 mysql_succ_fail
else
echo ${mysql_path}
 echo -e "\033[31m·�����������޸�ʧ��\033[0m\n"
 exit
fi
}

###�����޸����룬ˢ��Ȩ��
mysql_update_passwd_normal()
{
echo -e "\n\033[34m�޸����룬ˢ��Ȩ��...\033[0m"
mysql_connect
if [ "$?" -eq 0 ]; then
 if [ -f "${mysql_path}/bin/mysql" ];then
  ${mysql_path}/bin/mysql -u${mysql_user} -p"${mysql_passwd}" -e "update mysql.user set password=PASSWORD('${mysql_passwd}') where user='${mysql_user}'" && \
  ${mysql_path}/bin/mysql -u${mysql_user} -p"${mysql_passwd}" -e "flush privileges"
  mysql_succ_fail
 else
  echo -e "\033[31m·�����������޸�ʧ��\033[0m\n"
  exit
 fi
else
 echo -e "\033[31m��ǰ��������볢��ǿ���޸�����\033[0m\n"
 final_modifi
fi
}

###��������mysql
mysql_start()
{
mysql_stop
echo -e "\n\033[34mmysql����������...\033[0m"
sed -i '/jinxiang_mysqlpasswd/d' /etc/my.cnf
/etc/init.d/mysqld start
sleep 3
if [ "${is_path}" -eq 0 ]; then
 echo -e \033[31m"��������ʧ��\033[0m\n"
 exit
else
 echo -e "\033[32m���������ɹ�\033[0m\n"
fi
}

###mysql���Ӳ���
mysql_connect()
{
mysql_find_proc
mysql_is_path
if [ "${is_path}" -eq 1 ]; then
 ${mysql_path}/bin/mysql -u"${mysql_user}" -p"${mysql_passwd}" -e "flush privileges"
fi
}

###mysql��ѯԶ������Ȩ��
mysql_select_privilege()
{
mysql_find_proc
mysql_is_path
if [ "${is_path}" -eq 1 ]; then
 ${mysql_path}/bin/mysql -u"${mysql_user}" -p"${mysql_passwd}" -e "select host,user,password from mysql.user where user='${mysql_user}'"
 ${mysql_path}/bin/mysql -u"${mysql_user}" -p"${mysql_passwd}" -e "flush privileges"
else
 echo -e "\033[31mmysqlû��������������mysql\033[0m\n"
 mysql_find_file
fi
}

###mysql��ȨԶ������Ȩ��
mysql_grant_privilege()
{
mysql_find_proc
mysql_is_path
if [ "${is_path}" -eq 1 ]; then
 ${mysql_path}/bin/mysql -u"${mysql_user}" -p"${mysql_passwd}" -e "update mysql.user set host='%' where user='${mysql_user}'"
 ${mysql_path}/bin/mysql -u"${mysql_user}" -p"${mysql_passwd}" -e "flush privileges"
else
 echo -e "\033[31mmysqlû��������������mysql\033[0m\n"
 mysql_find_file
fi
}

###�ű�����
usage()
{
echo -e "\n\033[34mʹ�÷�����\033[0m\n \
����$0 -p ���� [-u �˺�] [-s] [-x] \n\n \
ѡ��˵����\n \
-p(����)	:mysql���� \n \
-u(ѡ��)	:mysql�˺ţ�Ĭ��Ϊroot \n \
-s(ѡ��)	:��ѯ��ǰmysqlԶ������Ȩ�� \n \
-x(ѡ��)	:����mysqlԶ������Ȩ�� \n \
" 
}

###mysql�޸����뺯������
mysql_modifi_passwd()
{
mysql_find_proc
mysql_is_path
mysql_find_file
mysql_skip_grant
mysql_update_passwd && mysql_start
}

###�ű�ѡ���������
while getopts ":u:p:sx" opt
do
 case $opt in
  u)
  mysql_user=${OPTARG};;
  p)mysql_passwd=${OPTARG};;
  s)
  mysql_select_opt=1;;
  x)
  mysql_grant_opt=1;;
  ?)
  echo -e "\033[31m�޷�ʶ���ѡ����ʵ��\033[0m"
  usage
  exit;;
 esac 
done

###�趨Ĭ���˺�
mysql_user=${mysql_user:-root}
###�������
if [ -z "${mysql_passwd}" ]; then
 echo -e "\033[31m����д����\033[0m"
 usage
 exit
fi

###�������޸Ĳ���ȷ��
final_modifi()
{
echo -e "�Ƿ���Ҫ���˺ţ�${mysql_user} �������޸�Ϊ��${mysql_passwd}"
read -p"yes[y] or no[n]:" -n 1 mysql_option
if [ "${mysql_option}" = "y" ];then
 echo -e "\n"
 mysql_modifi_passwd
 exit
else
 echo -e "\n\nȡ������\n"
 exit
fi
}

###�����޸Ĳ���ȷ��
final_modifi_normal()
{
mysql_find_proc
mysql_is_path
mysql_find_file
echo -e "�Ƿ���Ҫ���˺ţ�${mysql_user} �������޸�Ϊ��${mysql_passwd}"
read -p"yes[y] or no[n]:" -n 1 mysql_option
if [ "${mysql_option}" = "y" ];then
 echo -e "\n"
 mysql_update_passwd_normal
 exit
else
 echo -e "\n\nȡ������\n"
 exit
fi
}

### -p ѡ��ִ����ͨ��ʽ�����޸Ĳ���
if [[ "$*" =~ "-p" ]] && [ $# -eq 2 ];then
 mysql_connect
 if [ "$?" -eq 0 ]; then
  echo -e "\033[34mmysql�����޸ģ�\033[0m"
  final_modifi_normal
 else
  echo -e "\033[31m��ǰ��������볢��ǿ���޸�����\033[0m\n"
  final_modifi
 exit
 fi
### -u -p ѡ��ִ����ͨ��ʽ�����޸Ĳ���
elif [[ "$*" =~ "-u" ]] && [[ "$*" =~ "-p" ]] && [ $# -eq 4 ];then
 mysql_connect
 if [ "$?" -eq 0 ]; then
  echo -e "\033[34mmysql�����޸ģ�\033[0m"
  final_modifi_normal
 else
  echo -e "\033[31m��ǰ��������볢��ǿ���޸�����\033[0m\n"
  final_modifi
 exit
 fi
### -s ѡ��ִ��select����
elif [[ "${mysql_select_opt}"x == "1x" ]] && [[ "${mysql_grant_opt}"x != "1x" ]];then
 mysql_connect
 if [ "$?" -eq 0 ]; then
  echo -e "mysql��ǰ����Ȩ�ޣ�"
  mysql_select_privilege
 else
  echo -e "\033[31m��ǰ��������볢��ǿ���޸�����\033[0m\n"
  final_modifi
 exit
 fi
### -s -xѡ��ͬʱ����ʱ�������ظ�ִ��select��������ִ��-xѡ�����
else
 mysql_connect
 if [ "$?" -eq 0 ]; then
  echo -e "mysql��ǰ����Ȩ�ޣ�"
  mysql_select_privilege
  mysql_grant_privilege
  echo -e "mysql�޸ĺ�����Ȩ�ޣ�"
  mysql_select_privilege
  exit
 else
  echo -e "\033[31m��ǰ��������볢��ǿ���޸�����\033[0m\n"
  final_modifi
 fi
fi
