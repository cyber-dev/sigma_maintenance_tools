#!/bin/bash

###################################################
#
#  CYBERMAIL∑ Maintenance Script
#
###################################################


home_dir="/home/webmail"
work_dir="/mnt/storage/workdir/module/patch/201606xx_add"
tmp_list=`mktemp`
backup_list="${work_dir}/backup.list"
backup_file="${work_dir}/backup.tgz"
cm_patch="hotfix_sigma_v6sp4c004"
m2kctrl="/webmail/tools/m2kctrl"
hostname=`uname -n | awk -F. '{print $1}'`
webmail_process=`/webmail/tools/m2kctrl -s all -c status | awk '{print $1}' | egrep -v "cav_srv|m2kidxd"`

if [ $$ -ne $(pgrep -fo "$0") ]; then
  echo "You can't run this script."
  exit 1
fi


makeBackup(){
  echo -n "patch num : "
  read num
  for i in `seq 1 ${num}`
  do
    echo -n "input patch date : "
    read date
    tar ztf ${work_dir}/${cm_patch}_${date}.tgz | egrep -v "/$|m2kpatch" | sed "s/${cm_patch}_${date}/\/webmail/g" >> ${tmp_list}
    wait
    echo "make backup list ${cm_patch}_${date}"
    echo
  done
  cat ${tmp_list} | sort | uniq > ${backup_list}
  tar zcf ${backup_file} -T ${backup_list}
  wait
  tar zftv ${backup_file}
  menu
}


stopProcess(){
  sudo -u webmail ${m2kctrl} -s all -c stop
  wait
  killall mailerd2 smtpd2
  wait
  menu
}


startProcess(){
  sudo -u webmail ${m2kctrl} -s all -c start
  wait
  /webmail/mqueue2/bin/mailerd2 /webmail/mqueue2/conf/mailerd2.conf
  wait
  /webmail/mqueue2/bin/smtpd2 /webmail/mqueue2/conf/smtpd2.conf
  wait
  menu
}


checkStop(){
  for process in ${webmail_process}
  do
    process_num=`ps -ef | grep ${process} | egrep -v 'mailerd2|smtpd2|grep' | wc -l`

    if [ ${process_num} != 0 ]; then
      killall ${process}
      wait
      process_num=`ps -ef | grep ${process} | egrep -v 'mailerd2|smtpd2|grep' | wc -l`
    fi

    echo -e ${process_num} \\t ${process}
  done
  echo -e `ps -ef | grep mailerd2 | grep -v grep | wc -l` \\t mailerd2
  echo -e `ps -ef | grep smtpd2 | grep -v grep | wc -l` \\t smtpd2
  menu
}


checkStart(){
  for process in ${webmail_process}
  do
    process_num=`ps -ef | grep ${process} | egrep -v 'mailerd2|smtpd2|grep' | wc -l`
    echo -e ${process_num} \\t ${process}
  done
  echo -e `ps -ef | grep mailerd2 | grep -v grep | wc -l` \\t mailerd2
  echo -e `ps -ef | grep smtpd2 | grep -v grep | wc -l` \\t smtpd2
  menu
}


installPatch(){
  echo -n "input patch date : "
  read date
  word_num=`echo ${date} | wc -l`
  if [ ${word_num} -ne 6 ]; then
    echo "invalid patch date"
    exit 1
  fi

  cp -p ${work_dir}/${cm_patch}_${date}.tgz ${home_dir}/${cm_patch}_${date}.tgz
  wait
  cd ${home_dir}
  sudo -u webmail tar zxvf ${home_dir}/${cm_patch}_${date}.tgz
  wait
  cd ${home_dir}/${cm_patch}_${date}.tgz
  ./patch_installer.pl
  wait
  menu
}


menu(){
echo "=========================================="
echo " ${HOST} CM Hotfix Install tool MENU      "
echo "=========================================="
echo " 1. make backup                           "
echo " 2. stop webmail process                  "
echo " 3. check webmail process                 "
echo " 4. install patch                         "
echo " 5. start webmail process                 "
echo " 6. check webmail process                 "
echo " q. quit                                  "
echo "------------------------------------------"
echo -n "input number : "
read INPUT

case ${INPUT} in
  1) makeBackup           ;;
  2) stopProcess          ;;
  3) checkStop            ;;
  4) installPatch         ;;
  5) startProcess         ;;
  6) checkStart           ;;
  q) exit 0               ;;
  *) invalid number       ;;
esac
}


## tool start position
menu
