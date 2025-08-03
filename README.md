# bydbash
byd
别想在别的发行版上使用它 I use arch btw
直接放/etc里头去就行了

详细解释:
# 请使用git命令行工具的clone子命令以```git clone https://github.com/hllRGB/bydbash.git``` 的方式将该仓库克隆到任意你喜欢的位置，并进入刚克隆下来的目录（通常直接名为bydbash/），执行其中的```deploy.sh```，或者直接提升到root权限后将文件bash.bashrc放进/etc下以替换原来存在在这里的文件bash.bashrc，并且清空你的主目录下的.bashrc文件中的默认存在的内容，如果你确定里面真的只有默认生成的内容，你可以使用```> ~/.bashrc```命令进行。如果你不确定，请手动删除具有```PS1="[\u@\h \w]\$ "```的那一行以及```alias ls='ls --color=auto'```,```alias grep='grep --color=auto'```.一旦使用了这个bashrc,他们就不再被需要了。
