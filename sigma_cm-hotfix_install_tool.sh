#!/bin/bash

###################################################
#
#  CYBERMAIL∑ Maintenance Script
#
###################################################


home_dir="/home/webmail"
work_dir="/mnt/storage/workdir/module/patch/yyyymmdd_add"
cm_patch="hotfix_sigma_v6sp4c004"
m2kctrl="/webmail/tools/m2kctrl"
hostname=`uname -n | awk -F. '{print $1}'`
webmail_process=`/webmail/tools/m2kctrl -s all -c status | awk '{print $1}' | egrep -v "cav_srv|m2kidxd"`

if [ $$ -ne $(pgrep -fo "$0") ]; then
  echo "You can't run this script."
  exit 1
fi

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
echo " 1. stop webmail process                  "
echo " 2. check webmail process                 "
echo " 3. install patche                        "
echo " 4. start webmail process                 "
echo " 5. check webmail process                 "
echo " q. quit                                  "
echo "------------------------------------------"
echo -n "input number : "
read INPUT

case ${INPUT} in
  1) stopProcess          ;;
  2) checkStop            ;;
  3) installPatch         ;;
  4) startProcess         ;;
  5) checkStart           ;;
  q) exit 0               ;;
  *) invalid number       ;;
esac
}


## tool start position
menu
