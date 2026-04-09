# bash-powerline-ng

Minimalist, lightweight, usable and themable Powerline in pure Bash script.


![bash-powerline-ng](https://raw.github.com/z4ziggy/bash-powerline-ng/master/screenshots/terminal.png)

## Features

* Pure Bash, single-file, lightweight prompt
* Built-in themes and color schemes
* Path breadcrumbs, segment-based truncation, and permission-aware folder coloring
* Optional Git integration with branch, detached HEAD, dirty state, caching, and ahead/behind counts
* Optional host segment with SSH-aware icons
* Optional Python/Conda environment display
* Optional background jobs counter
* Optional command timing with configurable threshold
* Clear exit-status indicator for failed commands

## Installation

Download the script and source it from your `.bashrc`:
```bash
curl -fsSL https://raw.githubusercontent.com/z4ziggy/bash-powerline-ng/main/bash-powerline-ng.sh -o ~/.bash-powerline-ng.sh
echo 'source ~/.bash-powerline-ng.sh' >> ~/.bashrc
```

Override settings before sourcing, for example:
```bash
POWERLINE_THEME=slant source ~/.bash-powerline-ng.sh
```

## Why

Because [bash-powerline](https://github.com/riobard/bash-powerline) is great, but I wanted it to look nicer.

---
_I'd tell you a UDP joke, but you probably wouldn't get it._
