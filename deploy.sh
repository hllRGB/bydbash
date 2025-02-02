[ -z $TERMUX_VERSION ]&&not_termux=1||not_termux=0
[ $not_termux -eq 1 ]&&(echo "sudo cp bash.bashrc /etc/"&&sudo cp bash.bashrc /etc/)||(echo "cp bash.bashrc /data/data/com.termux/files/usr/etc/";cp bash.bashrc /data/data/com.termux/files/usr/etc/)
echo 宁得自己退出重进一下bash嗷
echo you should restart bash
