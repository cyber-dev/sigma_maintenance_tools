#!/bin/bash

###################################################
#
#  CYBERMAIL∑ Maintenance Script
#
###################################################


readonly HOME_DIR="/home/webmail"
readonly WORK_DIR="/mnt/storage/workdir/module/patch/201606xx_add"
readonly TMP_LIST=`mktemp`
readonly BACKUP_LIST="${WORK_DIR}/backup.list"
readonly BACKUP_FILE="${WORK_DIR}/backup.tgz"
readonly CM_PATCH="hotfix_sigma_v6sp4c004"
readonly M2KCTRL="/webmail/tools/m2kctrl"
readonly HOSTNAME=`uname -n | awk -F. '{print $1}'`
readonly WEBMAIL_PROC=`/webmail/tools/M2KCTRL -s all -c status | awk '{print $1}' | egrep -v "cav_srv|m2kidxd"`


function make_backup(){
  echo -n "patch num : "
  read local _num
  for i in `seq 1 ${_num}`
  do
    echo -n "input patch date : "
    read local _date
    tar ztf ${WORK_DIR}/${CM_PATCH}_${_date}.tgz | egrep -v "/$|m2kpatch" | sed "s/${CM_PATCH}_${_date}/\/webmail/g" >> ${TMP_LIST}
    wait
    echo "make backup list ${CM_PATCH}_${_date}"
    echo
  done
  cat ${TMP_LIST} | sort | uniq > ${BACKUP_LIST}
  tar zcf ${BACKUP_FILE} -T ${BACKUP_LIST}
  wait
  tar zftv ${BACKUP_FILE}
  menu
}


function stop_process(){
  sudo -u webmail ${M2KCTRL} -s all -c stop
  wait
  killall mailerd2 smtpd2
  wait
  menu
}


function start_process(){
  sudo -u webmail ${M2KCTRL} -s all -c start
  wait
  /webmail/mqueue2/bin/mailerd2 /webmail/mqueue2/conf/mailerd2.conf
  wait
  /webmail/mqueue2/bin/smtpd2 /webmail/mqueue2/conf/smtpd2.conf
  wait
  menu
}


function check_process(){
  for process in ${WEBMAIL_PROC}
  do
    local _process_num=`ps -ef | grep ${process} | egrep -v 'mailerd2|smtpd2|grep' | wc -l`
    echo -e ${_process_num} \\t ${process}
  done

  echo -e `ps -ef | grep mailerd2 | grep -v grep | wc -l` \\t mailerd2
  echo -e `ps -ef | grep smtpd2 | grep -v grep | wc -l` \\t smtpd2
  menu
}


function install_patch(){
  echo -n "input patch date : "
  read local _date
  word_num=`echo ${_date} | wc -l`
  if [ ${word_num} -ne 6 ]; then
    echo "invalid patch date"
    exit 1
  fi

  cp -p ${WORK_DIR}/${CM_PATCH}_${_date}.tgz ${HOME_DIR}/${CM_PATCH}_${_date}.tgz
  wait
  cd ${HOME_DIR}
  sudo -u webmail tar zxvf ${HOME_DIR}/${CM_PATCH}_${_date}.tgz
  wait
  cd ${HOME_DIR}/${CM_PATCH}_${_date}.tgz
  ./patch_installer.pl
  wait
  menu
}


function menu(){
  echo "=========================================="
  echo " ${HOSTNAME} CM Hotfix Install tool MENU  "
  echo "=========================================="
  echo " 1. make backup                           "
  echo " 2. stop webmail process                  "
  echo " 3. check webmail process                 "
  echo " 4. install patch                         "
  echo " 5. start webmail process                 "
  echo " q. quit                                  "
  echo "------------------------------------------"
  echo -n "input number : "
  read INPUT

  case ${INPUT} in
    1) make_backup           ;;
    2) stop_process          ;;
    3) check_process         ;;
    4) install_patch         ;;
    5) start_process         ;;
    q) exit 0                ;;
    *) invalid number        ;;
  esac
}


## tool start position
menu
