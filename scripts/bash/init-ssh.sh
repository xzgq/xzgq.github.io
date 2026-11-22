#!/usr/bin/env bash
# set et ts=4 sts=4 sw=4 ai ci

HOST=$(hostname | sed 's/sh\./sh1./')
COMMENT="$USER@$HOST"
echo $COMMENT
exit
PEM=~/.ssh/id_ed25519 
[ -f $PEM ] || ssh-keygen -q -N "" -C "$COMMENT" -b 4096 -t ed25519 -f $PEM
cat ~/.ssh/id_ed25519.pub

cat >> ~/.ssh/config << EOF
Host gitee
    HostName gitee.com
    User xzgq
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/id_ed25519

Host github
    HostName github.com
    PreferredAuthentications publickey
    User git
    IdentityFile ~/.ssh/id_ed25519
EOF

cat >> ~/.ssh/config << EOF
Host sh0
    HostName sh0.p-inv.cn
    PreferredAuthentications publickey
    User $USER
    IdentityFile ~/.ssh/id_ed25519

Host sh1
    HostName sh1.p-inv.cn
    PreferredAuthentications publickey
    User $USER
    IdentityFile ~/.ssh/id_ed25519

Host sh1v6
    HostName sh1.p-inv.cn
    PreferredAuthentications publickey
    AddressFamily inet6
    User $USER
    Port 9922
    IdentityFile ~/.ssh/id_ed25519
EOF
