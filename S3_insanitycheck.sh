#!/bin/bash
az=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
sg=`curl -s http://169.254.169.254/latest/meta-data/security-groups`
ami=`curl -s http://169.254.169.254/latest/meta-data/ami-id`
role=`curl -s http://169.254.169.254/latest/meta-data/iam/info`
instancetype=`curl -s http://169.254.169.254/latest/meta-data/instance-type`
pip install awscli -q
echo "==========Instance Details================="
echo ""
echo $(hostname)
ip addr show eth0 | grep 'inet ' | awk '{print $2;}' | cut -d '/' -f1
echo -n "Cores: "
grep processor /proc/cpuinfo | wc -l
echo -n "Ram: "
free -h | grep Mem | awk '{print $2;}'
echo "instance type is $instancetype"
echo ""
echo "======Instance Id=============="
instanceid=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
echo $instanceid 
echo "======================="
echo "========Instnace Details===============" 
echo "AZ is $az"
echo "sg are $sg"
echo "ami is $ami"
echo $role | grep InstanceProfileArn | awk -F '/' '{print $2}' | awk -F '"' '{print $1}' 

echo "======================="
REGION=`echo $az | sed 's/.\{1\}$//'`

echo "======Local Host file check======"
[[ $(cat /etc/hosts | sed '/^\s*$/d' | wc -l) > 3 ]] && echo "=*NOT OK*=Hosts file is Touched. Content pasted below==" && cat /etc/hosts || echo "==*OK*==Local Host file is not touched=="
echo ""
echo "=======SELINUX status check=============="
echo ""
[[ $(getenforce) !=  "Disabled" ]] && echo "=*NOT OK*=SElinux is NOT Disabled" || echo "==*OK*=SElinux is Disabled"
echo "================================="
echo ""
echo "=======NFS4 status check=============="
[[ $(mount | grep nfs4) ]] && echo "=*NOT OK*==NFS4 fs is mounted. Filesystems are below==" && mount | grep nfs4 || echo "=*OK*==NFS4 is NOT mounted=="
echo "================================="
echo ""
[[ $(cat /etc/fstab | grep -v '^#' | grep nfs4) ]] && echo "=*NOT OK*==NFS4 fs is enabled in fstab. Content pasted below==" && cat /etc/fstab | grep -v '^#' | grep nfs4 || echo "=*OK*==NFS4 is NOT enabled in fstab=="
echo "================================="
echo ""
echo "======Mcafee Checks======"
[[ $(ps -edf | grep mac | wc -l) > 1 ]] && echo "=*NOT OK*=Macafee is RUNNING==" && ps -edf | grep mac || echo "==*OK*==Macafee is NOT Running=="
echo "================================="
echo ""
echo "======Mcafee package installation======"
[[ $(rpm -qa | egrep -i 'ISec|MFEcma') ]] && echo "=*NOT OK*=macafee is installed. Remove below packages" && rpm -qa | egrep -i 'ISec|MFEcma'  || echo "==*OK*=Mcafee is NOT installed=="
echo "================================="
echo ""

echo "======Opsramp/Vistara installation======"
echo ""
[[ $(ps -edf| grep -E 'opsramp|vistara' | grep -v grep) ]] && echo "=*OK*=Opsramp/Vistara is running"  || echo "==*NOT OK*=Opsramp/Vistara is NOT running=="
echo "================================="
echo ""

echo "======ENA Support ======"
[[ $(lsmod| grep ena | grep -v grep) ]] && echo "=*OK*=ENA kernel Module is enabled"  || echo "==*NOT OK*=ENA is NOT enabled=="
echo "================================="
echo ""

echo "======Network interface Driver ENA Status ======"
[[ $(ethtool -i eth0| grep ena | grep -v grep) ]] && echo "=*OK*=eth0 Network interface Driver is using ENA as enabled"  || echo "==*NOT OK*=eth0 Network interface Driver is NOT using ENA as enabled"
echo "================================="
echo ""

echo "======Join Domain status======"
[[ $(pbis status | grep 'Status: .*Online') ]] && echo "=*OK*=Join Domain was fine"  || echo "==*NOT OK*=Join domain did not happen=="
echo "================================="
echo ""

echo "======EBS optimized check======"

[[ $(aws ec2 describe-instances --instance-id $instanceid --region=$REGION | grep '"EbsOptimized"\: true' | grep -v grep) ]] && echo "=*OK*=EBS optimized is enabled=" || echo "==*NOT OK*=EBS optimzied is NOT enabled"
echo "================================="
echo ""
echo "=========EBS Volumes==========="
aws ec2 describe-volumes  --filters Name=attachment.instance-id,Values=$instanceid --region=$REGION --query "Volumes[*].{Size:Size,IOPS:Iops,Type:VolumeType}" --output table

echo "==================="

if ps -ef | grep ssm-agent | grep -v grep > /dev/null; then
	echo "- SSM Agent running."
else
	echo "- SSM Agent NOT RUNNING!"
fi

echo ""
echo "resolv.conf:"
cat /etc/resolv.conf

echo ""
if [[ -n "$(swapon -s)" ]]; then swapon -s; else echo "No swap configured."; fi

echo -n "Root drive size: "
df -Th | grep /$ | awk '{print $3;}'

echo "=======Ulimit settings=============="
echo "================================="
ulimit -a
echo "================================="
echo ""
echo "=======Server reboot =============="
echo "================================="
last reboot | head -1
echo "================================="
echo ""
echo ""
echo "client.rb"
cat /etc/chef/client.rb

echo "node.json"
cat /etc/chef/node.json

echo ""
echo "==========================="
echo ""

echo ""
echo "==========================="
echo "pbis status output"
pbis status
echo "==========="

