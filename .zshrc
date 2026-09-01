typeset -U path

export ANDROID_HOME="/mnt/data/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export CARGO_HOME=/mnt/data/.cargo
export RUSTUP_HOME=/mnt/data/.rustup

path=(
  $HOME/bin
  $HOME/.local/bin
  /usr/local/bin
  $CARGO_HOME/bin
  $RUSTUP_HOME/toolchains/stable-x86_64-unknown-linux-gnu/bin
  $HOME/.kotlinc/bin
  $HOME/.pub-cache/bin
  $HOME/.devcontainers/bin
  /opt/android-sdk/platform-tools
  $ANDROID_HOME/cmdline-tools/latest/bin
  $ANDROID_HOME/platform-tools
  $ANDROID_HOME/emulator
  $ANDROID_HOME/build-tools/36.0.0
  /mnt/data/Android/flutter/bin
  $path
)

export PATH

export ZSH="$HOME/.oh-my-zsh"

export NVM_DIR="$HOME/.nvm"

ZSH_THEME="robbyrussell"

CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder
plugins=(git sudo web-search archlinux copyfile fzf-tab copybuffer dirhistory)

source $ZSH/oh-my-zsh.sh

export MANPATH="/usr/local/man:$MANPATH"

export LANG=en_US.UTF-8

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nano'
else
  export EDITOR='nvim'
fi

export ARCHFLAGS="-arch $(uname -m)"

for f in ~/.config/zsh/*.sh(N); do
    source "$f"
done
