#!/bin/bash

#===============================================================>
#=====>		NAME:		auto_install_netbox.sh
#=====>		VERSION:	1.0
#=====>		DESCRIPTION:	Auto Instalação Netbox
#=====>		CREATE DATE:	28/12/2022
#=====>		WRITTEN BY:	Ivan da Silva Bispo Junior
#=====>		E-MAIL:		contato@ivanjr.eti.br
#=====>		DISTRO:		Debian GNU/Linux 11 (Bullseye)
#===============================================================>
echo "========Informe os dados abaixo========"
echo""
read -p "Digite o nome do usuário do banco de dados: " NOME_USUARIO
read -p "Digite a senha do usuário do banco de dados: " SENHA_USUARIO
read -p "Digite o nome do banco de dados: " NOME_BANCO
read -p "digite o ip do servidor: " IP

apt update && apt upgrade -y

apt install sudo -y

apt install apt-transport-https lsb-release ca-certificates wget -y

wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg

echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/sury-php.list

apt update && apt upgrade -y

apt install acl curl fping git graphviz imagemagick mariadb-client mariadb-server mtr-tiny nginx-full nmap python3-dotenv python3-pymysql python3-redis python3-setuptools python3-systemd python3-pip rrdtool snmp snmpd whois -y

wget -qO - https://packages.sury.org/php/apt.gpg | sudo apt-key add -

echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list

apt update && apt upgrade -y

sudo apt install php8.1-cli php8.1-curl php8.1-fpm php8.1-gd php8.1-gmp php8.1-phpdbg php8.1-cgi php8.1-mbstring php8.1-mysql php8.1-snmp php8.1-xml php8.1-zip -y

sudo sed -i "s/;date.timezone =/date.timezone =America\/Bahia/" /etc/php/8.1/fpm/php.ini
sudo sed -i "s/;date.timezone =/date.timezone =America\/Bahia/" /etc/php/8.1/cli/php.ini

timedatectl set-timezone Etc/UTC

useradd librenms -d /opt/librenms -M -r -s "$(which bash)"

cd /opt
git clone https://github.com/librenms/librenms.git

chown -R librenms:librenms /opt/librenms
chmod 771 /opt/librenms
setfacl -d -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/
setfacl -R -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/

if [ hostname=librenms]; then
    ./scripts/composer_wrapper.php install --no-dev
    exit
else
    su - librenms
    ./scripts/composer_wrapper.php install --no-dev
exit

sed -i '/skip-external-locking/a\innodb_file_per_table=1' /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i '/innodb_file_per_table=1/a\lower_case_table_names=0' /etc/mysql/mariadb.conf.d/50-server.cnf

systemctl enable mariadb
systemctl restart mariadb

clear
echo "Criando o banco de dados e o usuário do banco de dados..."
sleep 3
SQL="create database $NOME_BANCO; GRANT ALL PRIVILEGES ON $NOME_BANCO.* TO $NOME_USUARIO@'localhost' IDENTIFIED BY '$SENHA_USUARIO'; flush privileges;"
mysql -u root -psenha -e "$SQL" mysql
clear
echo "Banco de dados criado com sucesso!"
sleep 3

cp /etc/php/8.1/fpm/pool.d/www.conf /etc/php/8.1/fpm/pool.d/librenms.conf
sudo sed -i "s/www-data/librenms/" /etc/php/8.1/fpm/pool.d/librenms.conf
sudo sed -i "s/user = www-data/user = librenms/" /etc/php/8.1/fpm/pool.d/librenms.conf
sudo sed -i "s/group = www-data/group = librenms/" /etc/php/8.1/fpm/pool.d/librenms.conf
sudo sed -i "/listen = /run/php-fpm-librenms.sock/c\listen = /run/php/php8.1-fpm-librenms.sock" /etc/php/8.1/fpm/pool.d/librenms.conf

echo EOF > /etc/nginx/sites-available/librenms.conf
server {
    listen      80;
    server_name $IP;
    root        /opt/librenms/html;
    index       index.php;

    charset utf-8;
    gzip on;
    gzip_types text/css application/javascript text/javascript application/x-javascript image/svg+xml text/plain text/xsd text/xsl text/xml image/x-icon;
    location / {
    try_files $uri $uri/ /index.php?$query_string;
    }
    location ~ [^/]\.php(/|$) {
    fastcgi_pass unix:/run/php-fpm-librenms.sock;
    fastcgi_split_path_info ^(.+\.php)(/.+)$;
    include fastcgi.conf;
    }
    location ~ /\.(?!well-known).* {
    deny all;
    }
}
EOF

rm /etc/nginx/sites-enabled/default
systemctl reload nginx
systemctl restart php8.1-fpm

ln -s /opt/librenms/lnms /usr/bin/lnms
cp /opt/librenms/misc/lnms-completion.bash /etc/bash_completion.d/

cp /opt/librenms/snmpd.conf.example /etc/snmp/snmpd.conf

echo "rocommunity public" >> /etc/snmp/snmpd.conf

curl -o /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro
chmod +x /usr/bin/distro
systemctl enable snmpd
systemctl restart snmpd

chown librenms:librenms /opt/librenms/config.php

sudo apt install bash-completion fzf grc -y

clear

=========
echo '' >> /etc/bash.bashrc
echo '# Autocompletar extra' >> /etc/bash.bashrc
echo 'if ! shopt -oq posix; then' >> /etc/bash.bashrc
echo '  if [ -f /usr/share/bash-completion/bash_completion ]; then' >> /etc/bash.bashrc
echo '    . /usr/share/bash-completion/bash_completion' >> /etc/bash.bashrc
echo '  elif [ -f /etc/bash_completion ]; then' >> /etc/bash.bashrc
echo '    . /etc/bash_completion' >> /etc/bash.bashrc
echo '  fi' >> /etc/bash.bashrc
echo 'fi' >> /etc/bash.bashrc
sed -i 's/"syntax on/syntax on/' /etc/vim/vimrc
sed -i 's/"set background=dark/set background=dark/' /etc/vim/vimrc
cat <<EOF >/root/.vimrc
set showmatch " Mostrar colchetes correspondentes
set ts=4 " Ajuste tab
set sts=4 " Ajuste tab
set sw=4 " Ajuste tab
set autoindent " Ajuste tab
set smartindent " Ajuste tab
set smarttab " Ajuste tab
set expandtab " Ajuste tab
"set number " Mostra numero da linhas
EOF
sed -i "s/# export LS_OPTIONS='--color=auto'/export LS_OPTIONS='--color=auto'/" /root/.bashrc
sed -i 's/# eval "`dircolors`"/eval "`dircolors`"/' /root/.bashrc
sed -i "s/# export LS_OPTIONS='--color=auto'/export LS_OPTIONS='--color=auto'/" /root/.bashrc
sed -i 's/# eval "`dircolors`"/eval "`dircolors`"/' /root/.bashrc
sed -i "s/# alias ls='ls \$LS_OPTIONS'/alias ls='ls \$LS_OPTIONS'/" /root/.bashrc
sed -i "s/# alias ll='ls \$LS_OPTIONS -l'/alias ll='ls \$LS_OPTIONS -l'/" /root/.bashrc
sed -i "s/# alias l='ls \$LS_OPTIONS -lA'/alias l='ls \$LS_OPTIONS -lha'/" /root/.bashrc
echo '# Para usar o fzf use: CTRL+R' >> ~/.bashrc
echo 'source /usr/share/doc/fzf/examples/key-bindings.bash' >> ~/.bashrc
echo "alias grep='grep --color'" >> /root/.bashrc
echo "alias egrep='egrep --color'" >> /root/.bashrc
echo "alias ip='ip -c'" >> /root/.bashrc
echo "alias diff='diff --color'" >> /root/.bashrc
echo "alias tail='grc tail'" >> /root/.bashrc
echo "alias ping='grc ping'" >> /root/.bashrc
echo "alias ps='grc ps'" >> /root/.bashrc
echo "PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;31m\]\u\[\033[01;34m\]@\[\033[01;33m\]\h\[\033[01;34m\][\[\033[00m\]\[\033[01;37m\]\w\[\033[01;34m\]]\[\033[01;31m\]\\$\[\033[00m\] '" >> /root/.bashrc
echo "echo;echo 'SXZhbiBKciAtIENvbnN1bHRvcmlhIGVtIFRJQy4NCg0KV2Vic2l0ZSAuLi4uLi4uLi4uLjogaXZhbmpyLmV0aS5icg0KQ29udGF0byAuLi4uLi4uLi4uLi46IGNvbnRhdG9AaXZhbmpyLmV0aS5icg=='|base64 --decode; echo;" >> /root/.bashrc
=========
cat << EOF > /etc/issue
- Hostname do sistema ............: \n
- Data do sistema ................: \d
- Hora do sistema ................: \t
- IPv4 address ...................: \4
- Acess Web ......................: http://\4
- Contato ........................: contato@ivanjr.eti.br
- Ivan Jr - Consultoria em TIC.

EOF
clear

IPVAR=`ip addr show | grep global | grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' | sed -n '1p'
`
echo http://$IPVAR