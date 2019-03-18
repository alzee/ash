# ash

Restore your dotfiles, bash environment and configurations.

## Build your directory structure.
* Fork it, clone, copy your dotfiles to ash/conf/home/ without starting dot.
	```bash
	# For example, .screenrc, .inputrc, .gitconfig, .vimrc, etc.
	for dotfile in screenrc inputrc gitconfig vimrc
	do
		cp ~/.${dotfile} ash/conf/home/
	done
	```
* Replace ash/conf/home/env with your own vars. 
* Replace ash/conf/home/fun with your own functions.
* Replace ash/conf/home/ali with your own aliases. 
* Commit and push.

## Restore on a new linux.
Phoenix arising from the ashes.
```bash
$ git clone https://github.com/username/ash

# run a.sh to hard link all the files in ash/conf/home to your home dir
# ~/.{env,fun,ali} will be added to ~/.bashrc
$ ash/a.sh
```

## Have changed you dotfiles?
```bash
## Let's say ~/.fun
## Don't forget it's a hark link to conf/home/fun
$ cd ash
## Commit change
$ git add conf/home/fun
$ git commit -m 'added foo() in fun'

## New codes in ~/.{env,fun,ali} need to be exported
$ # exit screen or tmux
$ rl
$ screen # tmux
```
