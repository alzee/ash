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
* Put your vars in ash/conf/home/env
* Put your functions in ash/conf/home/fun
* Put your aliases in ash/conf/home/ali

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
$ git commit -m 'fun changed'

## reload ~/.{env,fun.ali}
# exit screen or tmux
$ rl
$ screen # tmux
```

