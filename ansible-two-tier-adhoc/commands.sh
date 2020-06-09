#make sure Vagrant configured the VMs with the right hostnames
ansible multi -a "hostname"

#add the argument -f 1 to tell Ansible to use only one fork
ansible multi -a "hostname" -f 1

#make sure the servers have disk space available for our application
ansible multi -a "df -h"

#make sure there is enough memory on our servers
ansible multi -a "free -m"

#make sure the date and time on each server is in sync
ansible multi -a "date"

#install the NTP daemon
ansible multi -b -m yum -a "name=ntp state=present"

#make sure the NTP daemon is started and set to run on boot
ansible multi -b -m service -a "name=ntpd state=started enabled=yes"

#make sure our servers are synced closely to the official time on the NTP server
ansible multi -b -a "service ntpd stop"
ansible multi -b -a "ntpdate -q 0.rhel.pool.ntp.org"
ansible multi -b -a "service ntpd start"

#Configure the Application servers
ansible app -b -m yum -a "name=MySQL-python state=present"
ansible app -b -m yum -a "name=python-setuptools state=present"
ansible app -b -m easy_install -a "name=django<2 state=present"

#Check to make sure Django is installed and working correctly
ansible app -a "python -c 'import django; print django.get_version()'"

#install MariaDB, start it, and configure the server’s firewall to allow access on MariaDB’s default port, 3306
ansible db -b -m yum -a "name=mariadb-server state=present"
ansible db -b -m service -a "name=mariadb state=started enabled=yes"
ansible db -b -a "iptables -F"
ansible db -b -a "iptables -A INPUT -s 192.168.60.0/24 -p tcp -m tcp --dport 3306 -j ACCEPT"

#install mysql-python module on the managed server
ansible db -b -m yum -a "name=MySQL-python state=present"

#create user and assign password
ansible db -b -m mysql_user -a "name=django host=% password=12345 priv=*.*:ALL state=present"

#restart the service on the affected app server
ansible app -b -a "service ntpd restart" --limit "*.4"

#add an admin group on the app servers for the server administrators
ansible app -b -m group -a "name=admin state=present"

#add the user johndoe to the app servers with the group just created
ansible app -b -m user -a "name=johndoe group=admin createhome=yes"

#install packages "universally"
ansible app -b -m package -a "name=git state=present"

#get information about a file
ansible multi -m stat -a "path=/etc/environment"

#Copy a file to the servers
ansible multi -m copy -a "src=/etc/hosts dest=/tmp/hosts"

#Retrieve a file from the servers
ansible multi -b -m fetch -a "src=/etc/hosts dest=/tmp"

#create a directory
ansible multi -m file -a "dest=/tmp/test mode=664 state=directory"

#create a symlink
ansible multi -m file -a "src=/tmp/dest dest=/tmp/dest state=link"

#delete a directory
ansible multi -m file -a "dest=/tmp/test state=absent"

#update servers async
ansible multi -b -B 3600 -P 0 -a "yum -y update"

#check status
ansible multi -b -m async_status -a "ID"

#check logs
ansible multi -b -a "tail /var/log/messages"

#filter log messages with grep
ansible multi -b -a shell -a "tail /var/log/messages | grep ansible-command | wc -l"

#manage cron jobs
#create a job at 4am
ansible multi -b -m cron -a "name='daily-cron-all-servers' hour=4 job='/path/job.sh'"
#delete the job
ansible multi -b -m cron -a "name='daily-cron-all-servers' state=absent"
