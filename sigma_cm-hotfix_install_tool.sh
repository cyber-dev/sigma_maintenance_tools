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
  sudo -u webmail ${M2KCTRL} -s all -c stop > /dev/null 2>&1
  wait
  killall mailerd2 smtpd2 > /dev/null 2>&1
  wait
  sleep 5

  # check process
  check_process
  menu
}


function start_process(){
  # start process
  sudo -u webmail ${M2KCTRL} -s all -c start > /dev/null 2>&1
  wait
  /webmail/mqueue2/bin/mailerd2 /webmail/mqueue2/conf/mailerd2.conf > /dev/null 2>&1
  wait
  /webmail/mqueue2/bin/smtpd2 /webmail/mqueue2/conf/smtpd2.conf > /dev/null 2>&1
  wait
  sleep 5

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
}


function install_patch(){
  # install hotfix
  for hotfix in `ls ${WORK_DIR}/${CM_HOTFIX}* | awk -F/ '{print $NF}' | sed "s/.tgz//g"`
  do
    echo
    echo -n "Do you apply the ${hotfix} ? (y/n) :"
    read answer
    if [ ${answer} == "y" ]; then
      continue
    else
      exit 1
    fi

    cp -p ${WORK_DIR}/${hotfix}.tgz ${HOME_DIR}/${hotfix}.tgz
    wait
    cd ${HOME_DIR}
    sudo -u webmail tar zxvf ${HOME_DIR}/${hotfix}.tgz
    wait
    cd ${HOME_DIR}/${hotfix}
    ./patch_installer.pl
    wait
  done

  # make after md5sum
  for file in `cat ${BACKUP_LIST}`
  do
    md5sum ${file} >> ${AFTER_MD5SUM}
  done

  # diff md5sum
  diff ${BACKUP_MD5SUM} ${AFTER_MD5SUM}
  mv ${AFTER_MD5SUM} ${AFTER_MD5SUM}_${HOSTNAME}
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
