echo -en "\nEnter Master IP & Hostname :"
read master
echo $master >> /etc/hosts
echo -e "Enter Node-1 IP & Hostname :"
read node1
echo $node1 >> /etc/hosts
echo -e "Enter Node-2 IP & Hostname :"
read node2
echo $node2 >> /etc/hosts

echo "MASTER IP & HOSTNAME=[$master]"
echo "NODE-1 IP & HOSTNAME=[$node1]"
echo "NODE-2 IP & HOSTNAME=[$node2]"

ssh-keygen
ssh-copy-id root@node1
ssh-copy-id root@node2
scp /etc/hosts root@node1:/etc/hosts
scp /etc/hosts root@node2:/etc/hosts
yum update -y
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
modprobe overlay
modprobe br_netfilter
tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
tee /etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
yum clean all &&  yum -y makecache
yum -y install epel-release git curl wget kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl start kubelet
systemctl enable kubelet
OS=CentOS_7
VERSION=1.22
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/devel:kubic:libcontainers:stable.repo
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo
yum install cri-o -y
systemctl daemon-reload
systemctl start crio
systemctl enable crio
lsmod | grep br_netfilter
kubeadm config images pull
kubeadm init --pod-network-cidr=10.85.0.0/16 --upload-certs --control-plane-endpoint=master
