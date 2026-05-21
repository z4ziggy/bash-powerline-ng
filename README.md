# bash-powerline-ng

Minimalist, lightweight, usable and themable Powerline in pure Bash script.


![bash-powerline-ng](https://raw.github.com/z4ziggy/bash-powerline-ng/main/screenshots/terminal.png)

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

Clone the repo and source `bash-powerline-ng` into your `.bashrc`:
```bash
git clone https://github.com/z4ziggy/bash-powerline-ng.git
cd bash-powerline-ng
echo "source $PWD/bash-powerline-ng.sh" >> ~/.bashrc
```

You can use the `configure.sh` script to select theme, colors or change settings:

![configure](https://raw.github.com/z4ziggy/bash-powerline-ng/main/screenshots/configure.png)

Or manually override settings before sourcing, for example:
```bash
POWERLINE_THEME=slant source $PWD/bash-powerline-ng.sh
```

## Why

Because [bash-powerline](https://github.com/riobard/bash-powerline) is great, but I wanted it to look nicer.

---
_Q. How did the first program die?_
_A. It was executed._
