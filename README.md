### Fork it, and commit your dotfiles in home to ash/conf/home/, like .fun, .env, .ali, .vimrc, etc.

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

