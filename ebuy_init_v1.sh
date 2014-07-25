
#!/bin/sh
#init-package 20140724 by bughe

echo -e "\033[32;40;1m Start Init System.Please wait...\033[0m "

#Test Is initialized
if [ -e "/tmp/rf.pid" ];then
   echo -e "\033[40;45;1m This system is initialized!! If you want initialize again please del /tmp/rf.pid \033[0m "    
	exit
fi

#route


## HostName
hostip=`ifconfig|egrep "'inet addr'|Bcast"|head -n 1 |awk '{print $2}'|awk -F ":" '{print $2}'|awk -F "." '{print $3"-"$4}'`
sed -i '/HOSTNAME/d' /etc/sysconfig/network && echo "HOSTNAME=$hostip">>/etc/sysconfig/network
hostname $hostip


## DNS
cat >/etc/resolv.conf <<EOFF
nameserver 202.96.209.133
nameserver 202.96.209.5
nameserver 8.8.8.8
EOFF

## mirror
version=$(awk '/CentOS/{print $3}' /etc/issue | cut -b 1)
if [ $version = 5 ]; then
      rpm -ivh http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
      rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-5.rpm
      sed -i ':a;N;$!ba;s/enabled=0/enabled=1/' /etc/yum.repos.d/remi.repo
elif [ $version = 6 ];then
      rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
      rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
      sed -i ':a;N;$!ba;s/mirrorlist/#mirrorlist/' /etc/yum.repos.d/epel.repo && sed -i ':a;N;$!ba;s/#baseurl/baseurl/' /etc/yum.repos.d/epel.repo 
      sed -i ':a;N;$!ba;s/enabled=1/enabled=0/' /etc/yum.repos.d/epel.repo
      sed -i ':a;N;$!ba;s/enabled=0/enabled=1/' /etc/yum.repos.d/remi.repo
fi

yum clean all

yum makecache
yum -y install gcc gcc-c++ bison patch unzip mlocate flex wget automake autoconf gd cpp gettext readline-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel libidn libidn-devel openldap openldap-devel openldap-clients openldap-servers nss_ldap expat-devel libtool libtool-ltdl-devel bison lsof openssh-clients openssl-devel ntpdate scp


## Close service except "syslog rsyslog network sshd crond snmpd"
NAME=`chkconfig --list | grep 3:on | awk '{print $1}'`
WHITELIST='syslog rsyslog network sshd crond'
for SRV in $NAME;
do
        chkconfig --level 12345 $SRV off
done

## Open needed service
for SRV in $WHITELIST;do chkconfig --level 2345 $SRV on;done


sed -i '/LC_ALL/d' /etc/profile && echo 'export LC_ALL' >> /etc/profile
sed -i 's/HISTSIZE=1000/HISTSIZE=10000/' /etc/profile
sed  -i 's/10000/&\nHISTTIMEFORMAT="%F %T "/;s/export/&\tHISTTIMEFORMAT/' /etc/profile

## ulimit 
if [ `grep '65535' /etc/profile|wc -l` -eq 0 ]
then
sed -i '/65535/d' /etc/profile && echo 'ulimit -SHn 65535' >> /etc/profile
source /etc/profile
fi

if [ `grep '65535' /etc/security/limits.conf|wc -l` -eq 0 ]
then
sed '/# End of file/i\*        soft    nofile          65535\n*        hard    nofile          65535' -i /etc/security/limits.conf
fi

## sys sshd


## ntp update
cat > /var/spool/cron/root <<EOFF
00 23 * * *  /usr/sbin/ntpdate 192.168.2.56 >> /root/ntp.log 2>&1;/sbin/hwclock -w
EOFF
/etc/init.d/crond restart


touch /tmp/rf.pid

echo -e "\033[32;35;1m Mission Completed.Check /etc/ssh/sshd_config.The System Will Be Work After Reboot! \033[0m "

