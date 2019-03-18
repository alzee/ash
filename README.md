## a.sh - Restore your dotfiles, bash environment and configurations.

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
$ ash/a.sh # Now the phoenix reborn from the ashes.

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
