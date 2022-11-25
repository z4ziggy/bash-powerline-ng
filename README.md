# bash-powerline-ng

Powerline for Bash in pure Bash script.
Forked from https://github.com/riobard/bash-powerline


![bash-powerline-ng](https://raw.github.com/z4ziggy/bash-powerline-ng/old/screenshots/terminal1.png)

## Features

* Git branch: display current git branch name, or short SHA1 hash when the head
  is detached
* Git branch: background color reflects uncommited changes
* Git branch: display "⇡" symbol and the difference in the number of commits when the current branch is ahead of remote (see screenshot)
* Git branch: display "⇣" symbol and the difference in the number of commits when the current branch is behind of remote (see screenshot)
* ~~Platform-dependent prompt symbol for OS X and Linux (see screenshots)~~
* Color code for the previously failed command
* Fast execution (no noticable delay)
* No need for patched fonts


## Installation

Download the Bash script

    wget -O ~/.bash-powerline-ng.sh https://raw.github.com/z4ziggy/bash-powerline-ng/master/bash-powerline-ng.sh

And source it in your `.bashrc`

    source ~/.bash-powerline-ng.sh

## Why

Because [bash-powerline](https://github.com/riobard/bash-powerline) is great, 
but I wanted it to look nicer.

For everything else, please check the original [bash-powerline](https://github.com/riobard/bash-powerline) project
