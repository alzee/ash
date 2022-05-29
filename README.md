# ash

Restore your dotfiles, bash environment and configurations.

## Build your directory structure.
* Fork it, clone, copy your dotfiles to ash/conf/home/ without leading dot.
	```bash
    # Fork this repo
    # Clone forked repo
    git clone git@github.com:username/ash
	# Choose dotfiles you want to backup.
    # For example, .fun, .env, .screenrc, .inputrc, .gitconfig, .vimrc, etc.
    dotfiles='.fun .env .screenrc .inputrc .gitconfig .vimrc'
	for i in dotfiles
	do
		cp -a ~/$i ash/conf/home/${i#.}
	done
	```
* Write your envs in ash/conf/home/env
* Write you functions in ash/conf/home/fun
* Write your local envs in ~/.env.local
* Write your secret envs in ~/.env.sec 
* Write you local functions in ~/.fun.local
* Commit and push

## Restore on other linux.
```bash
# For brand new
$ git clone https://github.com/username/ash
# Hard link all files in ash/conf/home to your home dir
$ ash/a.sh -L

# For updating
$ cd ash
$ git pull
# githook post-merge will do the rest
```

## Have modified your dotfiles?
```bash
# Let's say ~/.fun
# Don't forget it's a hark link to ash/conf/home/fun
$ cd ash
# Commit change
$ git add conf/home/fun
$ git commit -m 'added foo() in fun'
$ git push

# New codes in ~/.{env,fun,ali} need to be exported
$ # exit screen or tmux
$ rl
$ screen # tmux
```

## Suggestion
```bash
# Change dir of githooks so git can track them
$ g config --global  core.hooksPath .githooks/
```
