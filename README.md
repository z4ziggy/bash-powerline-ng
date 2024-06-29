# bash-powerline-ng

Minimalist, lightweight, usable and themable Powerline in pure Bash script.


![bash-powerline-ng](https://raw.github.com/z4ziggy/bash-powerline-ng/master/screenshots/terminal.png)

## Features

* Fast execution
* Git branch: display branch symbol and current git branch name, or short SHA1 hash when the head is detached
* Git branch: foreground color reflects uncommitted changes
* Git branch: display "⇡" or "⇣" symbols plus the difference in the number of commits when the current branch is ahead or behind of remote (see screenshot)
* Colored error for the previously failed command
* Local/Network symbols for path visualization
* Folder symbol's color reflects write permissions for user


## Installation

Download the Bash script

    wget -O ~/.bash-powerline-ng.sh https://raw.github.com/z4ziggy/bash-powerline-ng/master/bash-powerline-ng.sh

And source it in your `.bashrc`

    source ~/.bash-powerline-ng.sh

To use a different theme, colors, or setting, override the variable before the `source` cmd. eg:

    POWERLINE_THEME=slant source ~/.bash-powerline-ng.sh


Sources should be easy enough to change and adapt to your liking - it's one file with less than 300 lines of code, modestly commented.


## Why

Because [bash-powerline](https://github.com/riobard/bash-powerline) is great, 
but I wanted it to look nicer.

For everything else, please check the original [bash-powerline](https://github.com/riobard/bash-powerline) project

