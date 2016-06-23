#!/bin/bash

###################################################
#
#  CYBERMAIL∑ Maintenance Script
#
###################################################


readonly HOME_DIR="/home/webmail"
readonly WORK_DIR="/mnt/storage/workdir/module/patch/20160723_add"
readonly CUSTOMIZE_FILE="${WORK_DIR}/customize_file.tgz"
readonly TMP_LIST=`mktemp`
readonly BACKUP_LIST="${WORK_DIR}/backup.list"
readonly BACKUP_FILE="${WORK_DIR}/backup.tgz"
readonly BACKUP_MD5SUM="${WORK_DIR}/backup.md5sum"
readonly AFTER_MD5SUM="${WORK_DIR}/after.md5sum"
readonly CM_HOTFIX="hotfix_sigma_v6sp4c004"
readonly M2KCTRL="/webmail/tools/m2kctrl"
readonly HOSTNAME=`uname -n | awk -F. '{print $1}'`
readonly WEBMAIL_PROC=`${M2KCTRL} -s all -c status | awk '{print $1}' | egrep -v "cav_srv|m2kidxd"`


function make_backup(){
  # make backup list
  for hotfix in `ls ${WORK_DIR}/${CM_HOTFIX}*`
  do
    local _hotfix=`ls ${hotfix} | awk -F/ '{print $NF}' | awk -F. '{print $1}'`
    tar ztf ${hotfix} | egrep -v "/$|patch.info|installer|m2kpatch" | sed "s/${_hotfix}/\/webmail/g" >> ${TMP_LIST}
    wait
  done

  # make backup
  cat ${TMP_LIST} | sort | uniq > ${BACKUP_LIST}
  tar zcf ${BACKUP_FILE} -T ${BACKUP_LIST} > /dev/null 2>&1
  wait

  # make backup file md5sum list
  for file in `cat ${BACKUP_LIST}`
  do
    md5sum ${file} >> ${BACKUP_MD5SUM}
  done

  # check backup
  echo
  echo "########## BACKUP FILE ##########"
  ls -al ${BACKUP_LIST} ${BACKUP_FILE} ${BACKUP_MD5SUM}
  echo "#################################"
  echo

  menu
}


function stop_process(){
  # stop process
  sudo -u webmail ${M2KCTRL} -s all -c stop
  wait
  killall mailerd2 smtpd2
  wait

  # check process
  check_process
  menu
}


function start_process(){
  # start process
  sudo -u webmail ${M2KCTRL} -s all -c start
  wait
  /webmail/mqueue2/bin/mailerd2 /webmail/mqueue2/conf/mailerd2.conf
  wait
  /webmail/mqueue2/bin/smtpd2 /webmail/mqueue2/conf/smtpd2.conf
  wait

  # check process
  check_process
  menu
}


function check_process(){
  for process in ${WEBMAIL_PROC}
  do
    local _processnum=`ps -ef | grep ${process} | egrep -v 'mailerd2|smtpd2|grep' | wc -l`
    echo -e ${_processnum} \\t ${process}
  done

  echo -e `ps -ef | grep mailerd2 | grep -v grep | wc -l` \\t mailerd2
  echo -e `ps -ef | grep smtpd2 | grep -v grep | wc -l` \\t smtpd2
  menu
}


function install_patch(){
  echo -n "patch num : "
  read num

  for i in `seq 1 ${num}`
  do
    echo -n "input patch date : "
    read date
    word_num=`echo ${#date}`
    if [ ${word_num} -ne 6 ]; then
      echo "invalid patch date"
      exit 1
    fi
    cp -p ${WORK_DIR}/${CM_HOTFIX}_${date}.tgz ${HOME_DIR}/${CM_HOTFIX}_${date}.tgz
    wait
    cd ${HOME_DIR}
    sudo -u webmail tar zxvf ${HOME_DIR}/${CM_HOTFIX}_${date}.tgz
    wait
    cd ${HOME_DIR}/${CM_HOTFIX}_${date}
    ./patch_installer.pl
    wait
    echo
  done

  for file in `cat ${BACKUP_LIST}`
  do
    md5sum ${file} >> ${AFTER_MD5SUM}
  done

  diff ${BACKUP_MD5SUM} ${AFTER_MD5SUM}

  menu
}


function sigma_customize(){
  cd /
  sudo -u webmail tar zxvf ${CUSTOMIZE_FILE}
  sudo -u webmail /webmail/tools/restartshm
  sudo -u webmail /webmail/tools/reloadini
  ldconfig
  menu
}


function switch_back(){
  cd /
  sudo -u webmail tar zxvf ${BACKUP_FILE}
  sudo -u webmail /webmail/tools/restartshm
  sudo -u webmail /webmail/tools/reloadini
  ldconfig
  menu
}


function menu(){
  echo "=========================================="
  echo " ${HOSTNAME} CM Hotfix Install tool MENU  "
  echo "=========================================="
  echo " 1. make backup                           "
  echo " 2. stop webmail process                  "
  echo " 3. install patch                         "
  echo " 4. sigma customize                       "
  echo " 5. start webmail process                 "
  echo " 6. switch back                           "
  echo " q. quit                                  "
  echo "------------------------------------------"
  echo -n "input number : "
  read INPUT

  case ${INPUT} in
    1) make_backup           ;;
    2) stop_process          ;;
    3) install_patch         ;;
    4) sigma_customize       ;;
    5) start_process         ;;
    6) switch_back           ;;
    q) exit 0                ;;
    *) invalid number        ;;
  esac
}


## tool start position
menu
