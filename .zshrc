########################################
# 環境変数

# tmuxでなんども読み込まない為に。
if [ -z $TMUX ]; then
    export LANG=ja_JP.UTF-8
    export PATH=/usr/local/bin:$PATH

    #エディタをvimに設定
    export EDITORP=vim

    #tmuxinaotrの為に
    export SHELL=zsh

    # zshrcをコンパイル確認
    if [ ~/.zshrc -nt ~/.zshrc.zwc ]; then
        zcompile ~/.zshrc
    fi
fi

if [[ "$(uname)" = 'Darwin' ]] ; then
    export PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"
fi

#######################################
# 外部プラグイン
# zplug
source ~/.zplug/init.zsh

# 構文のハイライト(https://github.com/zsh-users/zsh-syntax-highlighting)
zplug "zsh-users/zsh-syntax-highlighting", defer:2
# タイプ補完
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions", use:'src/_*', lazy:true
zplug "chrissicool/zsh-256color"

# simple trash tool that works on CLI, written in Go(https://github.com/b4b4r07/gomi)
zplug 'b4b4r07/gomi', as:command, from:gh-r

# 略語を展開する
zplug "momo-lab/zsh-abbrev-alias"

# dockerコマンドの補完
zplug "felixr/docker-zsh-completion"

# Tracks your most used directories, based on 'frecency'.
zplug "rupa/z", use:"*.sh"

# Install plugins if there are plugins that have not been installed
#if ! zplug check --verbose; then
#  printf "Install? [y/N]: "
#  if read -q; then
#    echo; zplug install
#  fi
#fi
# Then, source plugins and add commands to $PATH
zplug load

#######################################
# プロンプトなどの設定
# 色を使用出来るようにする
autoload -Uz colors
colors

# ヒストリの設定
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# プロンプト

# エスケープシーケンスを通すオプション
setopt prompt_subst

# 改行のない出力をプロンプトで上書きするのを防ぐ
unsetopt promptcr

# 頑張って両方にprmptを表示させるヤツ https://qiita.com/zaapainfoz/items/355cd4d884ce03656285
precmd() {
  autoload -Uz vcs_info
  autoload -Uz add-zsh-hook

  if [ "$(uname)" = 'Darwin' ]; then
    zstyle ':vcs_info:git:*' check-for-changes true
    zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
    zstyle ':vcs_info:git:*' unstagedstr "%F{magenta}+"
    zstyle ':vcs_info:*' formats '%F{green}%c%u[✔ %b]%f'
    zstyle ':vcs_info:*' actionformats '%F{red}%c%u[✑ %b|%a]%f'
  else
    zstyle ':vcs_info:*' formats '%F{green}[%b]%f'
    zstyle ':vcs_info:*' actionformats '%F{red}[%b|%a]%f'
  fi

  if [ "$(uname)" = 'Darwin' ]; then
  	local left=$'%{\e[38;5;083m%}%n@%m%{\e[0m%} %{\e[$[32+$RANDOM % 5]m%}➜%{\e[0m%} %{\e[38;5;051m%}%d%{\e[0m%}'
  else
  	local left=$'%{\e[38;5;083m%}%n@%m%{\e[0m%} %{\e[$[32+$RANDOM % 5]m%}=>%{\e[0m%} %{\e[38;5;051m%}%~%{\e[0m%}'
  fi
  local right="${vcs_info_msg_0_} "

  LANG=en_US.UTF-8 vcs_info

  # スペースの長さを計算
  # テキストを装飾する場合、エスケープシーケンスをカウントしないようにします
  local invisible='%([BSUbfksu]|([FK]|){*})'
  local leftwidth=${#${(S%%)left//$~invisible/}}
  local rightwidth=${#${(S%%)right//$~invisible/}}
  local padwidth=$(($COLUMNS - ($leftwidth + $rightwidth) % $COLUMNS)) 
  print -P $left${(r:$padwidth:: :)}$right
}

if [ "$(uname)" = 'Darwin' ]; then
    PROMPT=$'%{\e[$[32+$RANDOM % 5]m%}❯%{\e[0m%}%{\e[$[32+$RANDOM % 5]m%}❯%{\e[0m%}%{\e[$[32+$RANDOM % 5]m%}❯%{\e[0m%} '
else
    PROMPT=$'%{\e[$[32+$RANDOM % 5]m%}>%{\e[0m%}%{\e[$[32+$RANDOM % 5]m%}>%{\e[0m%}%{\e[$[32+$RANDOM % 5]m%}>%{\e[0m%} '
fi

if [ "$(uname)" = 'Darwin' ]; then
    RPROMPT=$'%{\e[38;5;001m%}%(?..✘☝)%{\e[0m%} %{\e[30;48;5;237m%}%{\e[38;5;249m%} %D %* %{\e[0m%}'
else
    RPROMPT=$'%{\e[30;48;5;237m%}%{\e[38;5;249m%} %D %* %{\e[0m%}'
fi

# プロンプト自動更新設定
autoload -U is-at-least
# $EPOCHSECONDS, strftime等を利用可能に
zmodload zsh/datetime 

reset_tmout() { 
    TMOUT=$[1-EPOCHSECONDS%1]
}

precmd_functions=($precmd_functions reset_tmout reset_lastcomp)

reset_lastcomp() { 
    _lastcomp=() 
}

if is-at-least 5.1; then
    # avoid menuselect to be cleared by reset-prompt
    redraw_tmout() {
        [ "$WIDGET" = "expand-or-complete" ] && [[ "$_lastcomp[insert]" =~ "^automenu$|^menu:" ]] || zle reset-prompt
        reset_tmout
    }
else
    # evaluating $WIDGET in TMOUT may crash :(
    redraw_tmout() { 
        zle reset-prompt; reset_tmout 
    }
fi

TRAPALRM() { 
    redraw_tmout 
}

# 単語の区切り文字を指定する
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

## 補完候補の色づけ
eval `dircolors`
export LSCOLORS=gxfxcxdxbxegedabagacad
export LS_COLORS='di=36:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
zstyle ':completion:*' verbose yes
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors 'di=36' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'

########################################
# 補完
# 補完数が多い場合に表示されるメッセージの表示を1000にする。
LISTMAX=1000

# 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ../ の後は今いるディレクトリを補完しない
zstyle ':completion:*' ignore-parents parent pwd ..

# sudo の後ろでコマンド名を補完する
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
                   /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

# ps コマンドのプロセス名補完
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'

# awscli コマンドの補完機能有効化
source /usr/local/bin/aws_zsh_completer.sh

# 選択中の候補を塗りつぶす
zstyle ':completion:*:default' menu select=2

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

## zsh の開始, 終了時刻をヒストリファイルに書き込む
#setopt extended_history

# シェルの終了を待たずにファイルにコマンド履歴を保存
setopt inc_append_history

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

# コマンド訂正
setopt correct

# 補完候補を詰めて表示する
setopt list_packed 

# カーソル位置は保持したままファイル名一覧を順次その場で表示
setopt always_last_prompt

# カッコの対応などを自動的に補完
setopt auto_param_keys

# 語の途中でもカーソル位置で補完
setopt complete_in_word

# フロー制御をやめる
setopt no_flow_control

# バックグラウンドジョブが終了したらすぐに知らせる
setopt notify 

# remove file mark
unsetopt list_types

########################################
# キーバインド
# Windows風のキーバインド
# Deleteキー
bindkey "^[[3~" delete-char

# Homeキー
bindkey "^[[1~" beginning-of-line

# Endキー
bindkey "^[[4~" end-of-line

# ヒストリー検索をpecoで。
peco-select-history() {
    BUFFER=$(history 1 | sort -k1,1nr | perl -ne 'BEGIN { my @lines = (); } s/^\s*\d+\*?\s*//; $in=$_; if (!(grep {$in eq $_} @lines)) { push(@lines, $in); print $in; }' | peco --query "$LBUFFER")
    CURSOR=${#BUFFER}
    zle reset-prompt
}
zle -N peco-select-history
bindkey '^R' peco-select-history

# zをpecoで。
peco-z-search() {
    which peco z > /dev/null
    if [ $? -ne 0 ]; then
        echo "Please install peco and z"
        return 1
    fi
    local res=$(z | sort -rn | cut -c 12- | peco)
    if [ -n "$res" ]; then
        BUFFER+="cd $res"
        zle accept-line
    else
        return 1
    fi
}
zle -N peco-z-search
bindkey '^F' peco-z-search

# cd up
function cd-up() { 
    zle push-line && LBUFFER='builtin cd ..' && zle accept-line 
}
zle -N cd-up
bindkey "^P" cd-up

# clear command
bindkey "^S" clear-screen

# word forward
bindkey "^N" forward-word
bindkey "^B" backward-word

# kill line
bindkey "^Q" kill-whole-line

########################################
# エイリアス

if type dircolors > /dev/null 2>&1; then
    #test -r ~/.dir_colors && eval "$(dircolors -b ~/.dir_colors)" || eval "$(dir_colors -b)"
    abbrev-alias ls='ls --color=auto'
    abbrev-alias dir='dir --color=auto'
    abbrev-alias vdir='vdir --color=auto'

    abbrev-alias grep='grep --color=auto'
    abbrev-alias fgrep='fgrep --color=auto'
    abbrev-alias egrep='egrep --color=auto'
fi

abbrev-alias l='ls -CF'
abbrev-alias la='ls -la'
abbrev-alias ll='ls -l'

abbrev-alias rm='rm -i'
abbrev-alias cp='cp -i'
abbrev-alias mv='mv -i'

abbrev-alias mkdir='mkdir -p'

abbrev-alias t='tmux'

if [[ "$(uname)" = 'Darwin' ]] ; then
    alias vi='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
    alias vim='env_LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
else
    alias vi='/usr/bin/vim'
    alias vim='/usr/bin/vim'
fi

abbrev-alias purevi='/usr/bin/vi'
abbrev-alias nkf8='nkf -w --overwrite ./*'
abbrev-alias tailf='tail -f'
abbrev-alias diff='colordiff -u'
abbrev-alias m='make'
abbrev-alias tf='terraform'

# sudo の後のコマンドでエイリアスを有効にする
abbrev-alias sudo='sudo '

# グローバルエイリアス
alias less='less -R'
abbrev-alias -g L='| less'
abbrev-alias -g G='| grep'
abbrev-alias -g B='| bc'
abbrev-alias tree="tree -NC"

# パイプをandで書く。
abbrev-alias -g and="|"

# gomi
abbrev-alias gm='gomi'

# git command
abbrev-alias ga='git add'
abbrev-alias gaa='git add .'
abbrev-alias gb='git brach'
abbrev-alias gc='git commit -m'
abbrev-alias gca='git commit -a -m'
abbrev-alias gct='git commit -a -m "$(date +%Y-%m-%d_%H-%M-%S)"'
abbrev-alias gco='git checkout'
abbrev-alias gp='git push'

# docker
alias dps='docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"'
abbrev-alias dimg='docker images'
abbrev-alias drun='docker run'
abbrev-alias drm='docker rm'
abbrev-alias drmi='docker rmi'
abbrev-alias drrm='docker run -it --rm'

# C で標準出力をクリップボードにコピーする
# mollifier delta blog : http://mollifier.hatenablog.com/entry/20100317/p1
if which pbcopy >/dev/null 2>&1 ; then
    # Mac
    abbrev-alias -g C='| pbcopy'
elif which xsel >/dev/null 2>&1 ; then
    # Linux
    abbrev-alias -g C='| xsel --input --clipboard'
elif which putclip >/dev/null 2>&1 ; then
    # Cygwin
    abbrev-alias -g C='| putclip'
fi

# zmv
#autoload -Uz zmv
#alias zmv='noglob zmv -W'

########################################
# tmuxの設定
# 自動ロギング
if [[ -x ansifilter ]] && [[ "$(uname)" = 'Darwin' ]]; then
       brew install ansifilter
fi

if [[ $TERM = screen ]] || [[ $TERM = screen-256color ]]; then
    local LOGDIR=$HOME/Documents/term_logs
    local LOGFILE=$(hostname)_$(date +%Y-%m-%d_%H%M%S_%N.log)
    local FILECOUNT=0
    local MAXFILECOUNT=2000
    # zsh起動時に自動で$MAXFILECOUNTのファイル数以上ログファイルあれば消す
    for file in `\find "$LOGDIR" -maxdepth 1 -type f -name "*.log" | sort --reverse`; do
        FILECOUNT=`expr $FILECOUNT + 1`
        if [ $FILECOUNT -gt $MAXFILECOUNT ]; then
            rm -f $file
        fi
    done
    [ ! -d $LOGDIR ] && mkdir -p $LOGDIR
    tmux  set-option default-terminal "screen" \; \
    pipe-pane        "cat - | ansifilter >> $LOGDIR/$LOGFILE" \; \
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

function who() {
    tail -n +5 /etc/hosts | grep --color "$1"
}

function see() {
    local HOST_LINE=`tail -n +5 /etc/hosts | peco | awk '{print $1, $2}'`
    local HOST_IP=`echo $HOST_LINE | awk '{print $1}'`
    local HOST_NAME=`echo $HOST_LINE | awk '{print $2}'`
    local HIS_LINE=`echo ${HOST_IP} \#${HOST_NAME}`
    [[ -z $HOST ]] && return 1

    #commentout imple
    if echo "${HOST}" | grep '^#' > /dev/null; then
        echo "it's comment out"
    else
        if type adssh >/dev/null 2>&1; then
            adssh ${HOST_IP}
            echo adssh ${HIS_LINE} >> ~/.zsh_history
        else
            ssh ${HOST_IP}
            echo ssh ${HIS_LINE} >> ~/.zsh_history
        fi
    fi
}

function again() {
    local HOST=`cat ~/.ssh/known_hosts | awk '{print $1}' | awk 'BEGIN {FS=",";OFS=","} {print $1}'  | peco`
    [[ -z $HOST ]] && return 1

     #commentout imple
     if echo "${HOST}" | grep '^#' > /dev/null; then
        echo "it's comment out"
     else
        if type adssh >/dev/null 2>&1; then
            adssh ${HOST} 
        else
            ssh ${HOST}
        fi      
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

function change() {
    sed -i -e "s@$1@$2@g" $3
}

function rktrant() {
    local NOW_PATH=`pwd`
    local RKT_PATH="/repo/rktrant/rkt/"
    if [ -e　$RKT_PATH ]; then
        cd $RKT_PATH
        vagrant $1
        cd $NOW_PATH
    else
        echo Please, \"git clone https://github.com/rkt/rkt.git $RKT_PATH\"
    fi
}

########################################
# その他
# ローカルの設定を見る
if [ -e　~/.zshrc_local ]; then
    source ~/.zshrc_local
fi
