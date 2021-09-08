# My dot files

Here are my dot files I use on my Linux, Windows (and maybe one day, macOS) machines

See https://github.com/andyneff/dot for more info, including how to use this pattern for yourself.

# Setting up on a new computer

1. `git clone https://github.com/andyneff/dot_files.git ~/.dot`
2. `~/.dot/install.bsh`

# FAQ

1. Why do _you_ not just use `.bashrc` directly?
    - I've deployed this on enough computers that I don't administer, to know some admins do annoying things, like write `.bashrc` and `.ssh/config` (usually on ssh login, but not always) for you. I have thus far been able to get away with this additive approach, and not have to do anything special to the git repo
    - Also, this allows me to to have computer specific things in the actually `.bashrc`/`.ssh/config`/etc... files, and not worry about "ok, I don't want to commit that specific file"
