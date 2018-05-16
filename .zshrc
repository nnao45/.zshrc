########################################
# 環境変数
export LANG=ja_JP.UTF-8
export LSCOLORS=gxfxcxdxbxegedabagacad
export PATH=/usr/local/bin:$PATH

# Go言語の設定

if [ "$(uname)" = 'Darwin' ]; then
    export GOBIN=/Users/s02435/go/bin
    export GOROOT=/Users/s02435/go
    export GOPATH=/Users/s02435/go-third-party
    export PATH=$PATH:/Users/s02435/.nodebrew/current/bin
else
    export GOBIN=/usr/src/go/bin
    export GOROOT=/usr/src/go
    export GOPATH=/usr/src/go-third-party
fi

export PATH=$GOPATH/bin:$PATH
export PATH=$GOROOT/bin:$PATH
export PATH=$HOME/.nodebrew/current/bin:$PATH

########################################
# プロンプトなどの設定

# 色を使用出来るようにする
autoload -Uz colors
colors

# emacs 風キーバインドにする
#bindkey -e

# ヒストリの設定
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

# プロンプト

# エスケープシーケンスを通すオプション
setopt prompt_subst

PROMPT=$'%{\e[38;5;083m%}%n@%m%{\e[0m%} %{\e[$[32+$RANDOM % 5]m%}=>%{\e[0m%} %{\e[38;5;051m%}%~%{\e[0m%}
%{\e[$[32+$RANDOM % 5]m%}>%{\e[0m%}%{\e[$[32+$RANDOM % 5]m%}>%{\e[0m%}%{\e[$[32+$RANDOM % 5]m%}>%{\e[0m%} '

# 単語の区切り文字を指定する
autoload -Uz select-word-style
select-word-style default
# ここで指定した文字は単語区切りとみなされる
# / も区切りと扱うので、^W でディレクトリ１つ分を削除できる
zstyle ':zle:*' word-chars " /=;@:{},|"
zstyle ':zle:*' word-style unspecified

########################################
# 補完
# 補完機能を有効にする
autoload -Uz compinit
compinit

# 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ../ の後は今いるディレクトリを補完しない
zstyle ':completion:*' ignore-parents parent pwd ..

# sudo の後ろでコマンド名を補完する
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
                   /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

# ps コマンドのプロセス名補完
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'

# 選択中の候補を塗りつぶす
zstyle ':completion:*' menu select

########################################
# vcs_info
autoload -Uz vcs_info
autoload -Uz add-zsh-hook

zstyle ':vcs_info:*' formats '%F{green}(%s)-[%b]%f'
zstyle ':vcs_info:*' actionformats '%F{red}(%s)-[%b|%a]%f'

function _update_vcs_info_msg() {
    LANG=en_US.UTF-8 vcs_info
    RPROMPT="${vcs_info_msg_0_}"
}
add-zsh-hook precmd _update_vcs_info_msg


########################################
# オプション
# 日本語ファイル名を表示可能にする
setopt print_eight_bit

# beep を無効にする
setopt no_beep

# フローコントロールを無効にする
setopt no_flow_control

# Ctrl+Dでzshを終了しない
#setopt ignore_eof

# '#' 以降をコメントとして扱う
setopt interactive_comments

# ディレクトリ名だけでcdする
setopt auto_cd

# cd したら自動的にpushdする
setopt auto_pushd
# 重複したディレクトリを追加しない
setopt pushd_ignore_dups

# 同時に起動したzshの間でヒストリを共有する
setopt share_history

# 同じコマンドをヒストリに残さない
setopt hist_ignore_all_dups

# スペースから始まるコマンド行はヒストリに残さない
setopt hist_ignore_space

# ヒストリに保存するときに余分なスペースを削除する
setopt hist_reduce_blanks

# 高機能なワイルドカード展開を使用する
setopt extended_glob

########################################
# キーバインド

# ^R で履歴検索をするときに * でワイルドカードを使用出来るようにする
#bindkey '^R' history-incremental-pattern-search-backward
bindkey '^D' exit

########################################
# エイリアス

alias l='ls -CF'
alias la='ls -a'
alias ll='ls -l'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias mkdir='mkdir -p'

alias t='tmux -2'

if [ "$(uname)" = 'Darwin' ]; then
        alias vi='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
        alias vim='env_LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
else
        alias vi='/usr/bin/vi'
        alias vim='/usr/bin/vim'
fi

alias nkf8='nkf -w --overwrite ./*'

# sudo の後のコマンドでエイリアスを有効にする
alias sudo='sudo '

# グローバルエイリアス
alias -g L='| less'
alias -g G='| grep'

# C で標準出力をクリップボードにコピーする
# mollifier delta blog : http://mollifier.hatenablog.com/entry/20100317/p1
if which pbcopy >/dev/null 2>&1 ; then
    # Mac
    alias -g C='| pbcopy'
elif which xsel >/dev/null 2>&1 ; then
    # Linux
    alias -g C='| xsel --input --clipboard'
elif which putclip >/dev/null 2>&1 ; then
    # Cygwin
    alias -g C='| putclip'
fi


########################################
# OS 別の設定
case ${OSTYPE} in
    darwin*)
        #Mac用の設定
        export CLICOLOR=1
        alias ls='ls -G -F'
        ;;
    linux*)
        #Linux用の設定
        alias ls='ls -F --color=auto'
        ;;
esac

# vim:set ft=zsh:

########################################
# tmuxの設定

# 自動ロギング
if [[ $TERM = screen ]] || [[ $TERM = screen-256color ]] ; then
    LOGDIR=$HOME/Documents/term_logs
    LOGFILE=$(hostname)_$(date +%Y-%m-%d_%H%M%S_%N.log)
    [ ! -d $LOGDIR ] && mkdir -p $LOGDIR
    tmux  set-option default-terminal "screen" \; \
    pipe-pane        "cat >> $LOGDIR/$LOGFILE" \; \
    display-message  "💾Started logging to $LOGDIR/$LOGFILE"
fi

########################################
# 自作関数の設定
function sk() {
    mkdir "$1" ; touch "$1"/"$1.scala"
}

function tkill() {
    tmux kill-session -t "$1"
}

function tkillall() {
    tmux kill-server
}

function adssh() {
    ssh -i ~/Documents/keys/ca_perman yokoyama_naoya@"$1"
}

function ciassh() {
    ssh cia_infra@"$1"
}

function xssh() {
    cat /etc/hosts | peco | awk '{print $1}' | xpanes adssh
}

function itsmine() {
    chown 1051436384:1796141739 "$1"
}

function who() {
    tail -n +5 /etc/hosts | grep --color "$1"
}

function see() {
    local HOST=`tail -n +5 /etc/hosts | peco | awk '{print $1}'`
    [[ -z $HOST ]] && return 1

    #commentout imple
    if echo "${HOST}" | grep '^#' > /dev/null; then
        echo "it's comment out"
    else
        adssh ${HOST}
    fi
}

function pane() {
    ## get options ##
    while getopts :s opt
    do
    case $opt in
	    "s" ) readonly FLG_S="TRUE" ;;
	    * ) usage; exit 1 ;;
    esac
    done

    shift `expr $OPTIND - 1`

    ## tmux pane split ##
    if [ $1 ]; then
    cnt_pane=1
    while [ $cnt_pane -lt $1 ]
    do
    if [ $(( $cnt_pane & 1 )) ]; then
 	    tmux split-window -h
    else
 	    tmux split-window -v
    fi
    tmux select-layout tiled 1>/dev/null
    cnt_pane=$(( $cnt_pane + 1 ))
    done
    fi

    #OPTION: start session with "synchronized-panes"
    if [ "$FLG_S" = "TRUE" ]; then
        tmux set-window-option synchronize-panes 1>/dev/null
    fi
}

function peco-select-history() {
    local tac
    if which tac > /dev/null; then
        tac="tac"
    else
        tac="tail -r"
    fi
    BUFFER=$(history -n 1 | \
        eval $tac | \
        peco --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history

########################################
# 外部プラグイン

# zplug
source ~/.zplug/init.zsh

# 構文のハイライト(https://github.com/zsh-users/zsh-syntax-highlighting)
zplug "zsh-users/zsh-syntax-highlighting"
# タイプ補完
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions", use:'src/_*', lazy:true
zplug "chrissicool/zsh-256color"
# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
  printf "Install? [y/N]: "
  if read -q; then
    echo; zplug install
  fi
fi
# Then, source plugins and add commands to $PATH
zplug load
