## a.sh - Bring back your dotfiles, automate your bash environment configuration.
### Fork it, commit your dotfiles to ash/conf/home/, like .screenrc, .inputrc, .gitconfig, .vimrc, etc.
* Put your vars in ash/conf/home/env
* Put your functions in ash/conf/home/fun
* Put your aliases in ash/conf/home/ali

```bash
### On a new linux.

$ git clone https://github.com/username/ash

# run a.sh to hard link all the files in ash/conf/home to your home dir
$ ash/a.sh

### Now your bash environment is back, like phoenix arise from the ashes.

# Have changed your .vimrc?
$ cd ash
$ git add conf/home/vim/vimrc
$ git commit -m 'vimrc changed'
```

