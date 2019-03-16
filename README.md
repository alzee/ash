## a.sh - Bring back your dotfiles, automate your bash environment configuration.

### Build your directory structure.
* Fork it, commit your dotfiles to ash/conf/home/.
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

### Usage
```bash
### On a new linux.

$ git clone https://github.com/username/ash

# run a.sh to hard link all the files in ash/conf/home to your home dir
# ~/.{env,fun,ali} will be added to ~/.bashrc
$ ash/a.sh

### Now your bash environment is back, like phoenix arise from the ashes.

### Have added a new function to your .fun?
$ cd ash
## commit change
$ git add conf/home/fun
$ git commit -m 'added foo() in fun'

## new codes in ~/.{env,fun,ali} need to be exported
# exit screen or tmux
$ rl
$ screen # tmux
```

