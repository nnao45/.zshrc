#######################################
# コマンドのインストール管理
# zplug
if [ ! -d ~/.zplug ]; then
  curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
fi

########################################
# 外部プラグイン
# zplug
source ~/.zplug/init.zsh

# 構文のハイライト(https://github.com/zdharma/fast-syntax-highlighting)
zplug "zdharma/fast-syntax-highlighting", defer:2
# タイプ補完
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions", use:'src/_*', lazy:true
zplug "chrissicool/zsh-256color"

# simple trash tool that works on CLI, written in Go(https://github.com/b4b4r07/gomi)
zplug 'b4b4r07/gomi', as:command, from:gh-r

# 略語を展開する
zplug "momo-lab/zsh-abbrev-alias"

# dockerコマンドの補完
zplug "docker/cli", use:"contrib/completion/zsh/_docker" lazy:true

# kubectlコマンドの補完
zplug "nnao45/zsh-kubectl-completion", lazy:true

## kubectlコマンドの補完リストをグループ化しない
zstyle ':completion:*:*:kubectl:*' list-grouped false

# Tracks your most used directories, based on 'frecency'.
zplug "rupa/z", use:"*.sh" lazy:true

# zsh内のtmuxでペイン単位で、SSHなど特定のコマンドが終わるまでだけタイムスタンプ付きのログを取る
# zplug "nnao45/ztl", use:'src/_*' lazy:true

# コマンドラインで絵文字
# zplug "b4b4r07/emoji-cli", lazy:true

# Install plugins if there are plugins that have not been installed
#if ! zplug check --verbose; then
#  printf "Install? [y/N]: "
#  if read -q; then
#  echo; zplug install
#  fi
#fi
# Then, source plugins and add commands to $PATH
zplug load

########################################
# 環境変数

# tmuxでなんども読み込まない為に。
if [ -z $TMUX ]; then
  export LANG=ja_JP.UTF-8
  export PATH=/usr/local/bin:$PATH

  # Docker
  ## WSLからDocker Desktopを触る
  # export DOCKER_HOST=tcp://localhost:2375 
  ## Docker Build Kitを使う
  export DOCKER_BUILDKIT=1

  # GO系
  export GOPATH=~/go
  export PATH=$GOPATH/bin:$PATH

  #エディタをvimに設定
  export EDITOR=vim

  #tmuxinaotrの為に
  export SHELL=zsh

  # zshrcをコンパイル確認
  if [ ~/.zshrc -nt ~/.zshrc.zwc ]; then
    zcompile ~/.zshrc
  fi

  # krewの為に
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

  # fzfのオプション
  export FZF_DEFAULT_OPTS='
    --height 50% --reverse 
    --color=bg+:161,pointer:7,spinner:227,info:227,prompt:161,hl:199,hl+:227,marker:227
    --no-mouse -m
  '

  # rustのPATH
  source ${HOME}/.cargo/env
  if [[ "$(uname)" = 'Darwin' ]] ; then
    fpath=("${HOME}/.rustup/toolchains/stable-x86_64-apple-darwin/share/zsh/site-functions" $fpath) 
  elif [[ "$(uname)" = 'Linux' ]] ; then
    fpath=("${HOME}/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/share/zsh/site-functions" $fpath)
  fi
  autoload -Uz +X "_cargo"
fi
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

#カレントディレクトリ/コマンド記録
local _cmd=''
local _lastdir=''
#gitブランチ名表示
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{magenta}+"
zstyle ':vcs_info:*' formats '%F{green}%c%u{%r}-[%b]%f'
zstyle ':vcs_info:*' actionformats '%F{red}%c%u{%r}-[%b|%a]%f'

preexec_gitupdate() {
  _cmd="$1"
  _lastdir="$PWD"
}
preexec_functions=($preexec_functions preexec_gitupdate)
#git情報更新
update_vcs_info() {
  psvar=()
  LANG=en_US.UTF-8 vcs_info
  [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"
}
#同一dir内でシェル外でgitのHEADが更新されていたら情報更新
check_gitinfo_update() {
  if [ -n "$_git_info_dir" -a -n "$_git_info_check_date" ]; then
    if [ -f "$_git_info_dir"/HEAD(ms-$((EPOCHSECONDS-$_git_info_check_date))) ]; then
      _git_info_check_date=$EPOCHSECONDS
      update_vcs_info
    fi 2>/dev/null
  fi
}
#カレントディレクトリ変更時/git関連コマンド実行時に情報更新
precmd_gitupdate() {
  local _r=$?
  local _git_used=0
  case "${_cmd}" in
    git*|stg*) _git_used=1
  esac
  if [ $_git_used = 1 -o "${_lastdir}" != "$PWD" ]; then
    local cwd="./"
    _git_info_dir=
    _git_info_check_date=
    while [ "$(echo $cwd(:a))" != / ]; do
      if [ -f .git/HEAD ]; then
        _git_info_dir="$PWD/.git"
        _git_info_check_date=$EPOCHSECONDS
        break
      fi
      cwd="../$cwd"
    done
    update_vcs_info
  else
    check_gitinfo_update
  fi
  return $_r
}
precmd_functions=($precmd_functions precmd_gitupdate)

# 頑張って両方にprmptを表示させるヤツ https://qiita.com/zaapainfoz/items/355cd4d884ce03656285
precmd() {
  local left=$'%{\e[38;5;083m%}%n%{\e[0m%} %{\e[$[32+$RANDOM % 5]m%}➜%{\e[0m%} %{\e[38;5;051m%}%d%{\e[0m%}'
  local right="${vcs_info_msg_0_} "

  # スペースの長さを計算
  # テキストを装飾する場合、エスケープシーケンスをカウントしないようにします
  local invisible='%([BSUbfksu]|([FK]|){*})'
  local leftwidth=${#${(S%%)left//$~invisible/}}
  local rightwidth=${#${(S%%)right//$~invisible/}}
  local padwidth=$(($COLUMNS - ($leftwidth + $rightwidth) % $COLUMNS))
  print -P $left${(r:$padwidth:: :)}$right
}

PROMPT=$'%{\e[$[32+$RANDOM % 5]m%}❯%{\e[0m%}%{\e[$[32+$RANDOM % 5]m%}❯%{\e[0m%}%{\e[$[32+$RANDOM % 5]m%}❯%{\e[0m%} '

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
  [ "$WIDGET" = "fzf-completion" ] && [[ "$_lastcomp[insert]" =~ "^automenu$|^menu:" ]] || zle reset-prompt
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

########################################
# 補完
# 補完数が多い場合に表示されるメッセージの表示を1000にする。
LISTMAX=1000

# 単語の区切り文字を指定する
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# 補完候補の色づけ
export LSCOLORS=gxfxcxdxbxegedabagacad
export LS_COLORS='di=36:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'

# 補完の表示方法を変更する
# http://zsh.sourceforge.net/Doc/Release/Completion-System.html#Standard-Styles

## コマンドのオプションの説明を表示
zstyle ':completion:*' verbose yes

## 補完のリストについてはlsと同じ表示色を使う
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

## 補完するときのフォーマットを拡張し指定する(http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#Prompt-Expansion)
zstyle ':completion:*' format '%B%d%b'

## 補完グループのレイアウトをいい感じにする。
zstyle ':completion:*' group-name ''

## 補完のキャッシュを有効にする
zstyle ':completion:*' use-cache true
## kubectlのキャッシュは有効にする
zstyle ':completion:*:*:kubectl:*' use-cache false

# 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ../ の後は今いるディレクトリを補完しない
zstyle ':completion:*' ignore-parents parent pwd ..

# sudo の後ろでコマンド名を補完する
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
           /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

#kill の候補にも色付き表示
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'

# ps コマンドのプロセス名補完
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'

# awscli コマンドの補完機能有効化
autoload bashcompinit && bashcompinit
complete -C '/usr/local/bin/aws_completer' aws
#source /usr/local/bin/aws_completer
#elif which /usr/bin/aws >/dev/null 2>&1; then
#  source /usr/bin/aws_completer
#elif which ~/.local/bin/aws >/dev/null 2>&1; then
#  source ~/.local/bin/aws_completer
#fi

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

# 一個前とホームディレクトリと/repoの配下のディレクトリにはその名前だけで移動できるようにする。
#cdpath=(.. ~ /repo ~/go-third-party/src/github.com)

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
#setopt correct

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

# Aでバッファの一番前
bindkey '^A' beginning-of-line

# Eでバッファの一番後ろ
bindkey "^E" end-of-line

# ヒストリー検索をfzfで。
fzf-select-history() {
  BUFFER=$(history 1 | sort -k1,1nr | perl -ne 'BEGIN { my @lines = (); } s/^\s*\d+\*?\s*//; $in=$_; if (!(grep {$in eq $_} @lines)) { push(@lines, $in); print $in; }' | fzf --no-sort --query "$LBUFFER")
  CURSOR=${#BUFFER}
  zle reset-prompt
}
zle -N fzf-select-history
bindkey '^R' fzf-select-history

# zをfzfで。
fzf-z-search() {
  if ! which fzf z >/dev/null 2>&1; then
    echo "Please install fzf and z"
    return 1
  fi
  local res=$(z | sort -rn | cut -c 12- | fzf --no-sort)
  if [ -n "$res" ]; then
    BUFFER+="$res"
    zle accept-line
  else
    return 1
  fi
}
#zle -N fzf-z-search
#bindkey '^F' fzf-z-search

# cd up
cd-up() {
  #zle push-line && LBUFFER='builtin cd ..' && zle accept-line
  zle push-line && LBUFFER='..' && zle accept-line
}
zle -N cd-up
bindkey "^Q" cd-up

# cd-down
cd-down() {
  zle push-line && LBUFFER='pd' && zle accept-line
}
zle -N cd-down
bindkey "^S" cd-down

# word forward
bindkey "^N" forward-word
bindkey "^B" backward-word

# comp-clean
comp-clean() {
  rm -f ~/.zcompdump; compinit
}
zle -N comp-clean
bindkey "^G" comp-clean

########################################
# エイリアス

abbrev-alias l='ls'
abbrev-alias ls='ls -G'

abbrev-alias la='ls -la'
abbrev-alias ll='ls -l'

abbrev-alias rm='rm -i'
abbrev-alias cp='cp -i'
abbrev-alias mv='mv -i'

abbrev-alias mkdir='mkdir -p'

abbrev-alias t='tmux'
if [ -z $TMUX ]; then
  alias tmux="tmux -2 attach || tmux -2 new-session \; source-file ~/.tmux/new-session"
fi

if [[ "$(uname)" = 'Darwin' ]] ; then
  alias vi='env LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
  alias vim='env_LANG=ja_JP.UTF-8 /Applications/MacVim.app/Contents/MacOS/Vim "$@"'
  abbrev-alias ls='ls -G'
else
  alias vi='/usr/bin/vim'
  alias vim='/usr/bin/vim'
  if which dircolors > /dev/null 2>&1; then
    test -r ~/.dir_colors && eval "$(dircolors -b ~/.dir_colors)"
    abbrev-alias ls='ls --color=auto'
    abbrev-alias dir='dir --color=auto'
    abbrev-alias vdir='vdir --color=auto'
    abbrev-alias grep='grep --color=auto'
    abbrev-alias fgrep='fgrep --color=auto'
    abbrev-alias egrep='egrep --color=auto'
  fi
fi

abbrev-alias purevi='/usr/bin/vi'
abbrev-alias nkf8='nkf -w --overwrite ./*'
abbrev-alias tailf='tail -f'
abbrev-alias diff='colordiff -u'
abbrev-alias m='make'
abbrev-alias tf='terraform'
abbrev-alias less='less -R'
abbrev-alias tree="tree -NC"


# sudo の後のコマンドでエイリアスを有効にする
abbrev-alias sudo='sudo '

# グローバルエイリアス
#abbrev-alias -g L='| less'
#abbrev-alias -g G='| grep'
#abbrev-alias -g B='| bc'
#abbrev-alias -g E='| emojify'
#abbrev-alias tree="tree -NC"

# パイプをandで書く。
abbrev-alias -g and="|"

# gomi
abbrev-alias gm='gomi'

# git command
abbrev-alias gct='git commit -a -m "$(date +%Y-%m-%d_%H-%M-%S)"'

# docker
alias dps='docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"'
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
autoload -Uz zmv
alias zmv='noglob zmv -W'

# popd
abbrev-alias pd='popd > /dev/null'

# kubectl
abbrev-alias k='kubectl'
abbrev-alias kga='kubectl get all --all-namespaces -o wide'

# just
abbrev-alias j='just'

# fzf
abbrev-alias f='fzf'
abbrev-alias fp="fzf --preview 'cat {}'"

#if [ -n $TMUX ]; then
#  abbrev-alias fzf='fzf-tmux -d 30%'
#fi

########################################
# 自作関数の設定
tkill() {
  tmux kill-session -t "$1"
}

tkillall() {
  tmux kill-server
}

g() {
  local REPO=$(ghq root)/$(ghq list | fzf)
  if [ ! "${REPO}" = "$(ghq root)/" ]; then
    cd ${REPO}
  fi 
}

gc() {
  local REPO=$(ghq root)/$(ghq list | fzf)
  if [ ! "${REPO}" = "$(ghq root)/" ]; then
    code ${REPO}
  fi
}

gi() {
  local REPO=$(ghq root)/$(ghq list | fzf)
  if [ ! "${REPO}" = "$(ghq root)/" ]; then
    /Applications/IntelliJ\ IDEA.app/Contents/MacOS/idea ${REPO}
  fi
}

gg() {
  if [ -z ${1} ]; then
    echo "Usage: ${0} <github repo URL>"
    return 1
  fi
  ghq get ${1}
}

ggc() {
  if [ -z ${1} ]; then
    echo "Usage: ${0} <github repo URL>"
    return 1
  fi
  local RESULT=""
  ghq get ${1}
  if echo ${1} | grep 'https://' >/dev/null 2>&1 ; then
    RESULT=$(echo ${1} | cut -c 9-)
  elif echo ${1} | grep 'git@' >/dev/null 2>&1 ; then
    RESULT=$(echo ${1} | sed  "s&git@github.com:&github.com/&") 
  fi

  if echo ${RESULT} | grep '.git' >/dev/null 2>&1 ; then
    RESULT=$(echo ${RESULT} | rev | cut -c 5- | rev)
  fi

  code $(ghq root)/${RESULT}
}

ggi() {
  if [ -z ${1} ]; then
    echo "Usage: ${0} <github repo URL>"
    return 1
  fi
  local RESULT=""
  ghq get ${1}
  if echo ${1} | grep 'https://' >/dev/null 2>&1 ; then
    RESULT=$(echo ${1} | cut -c 9-)
  elif echo ${1} | grep 'git@' >/dev/null 2>&1 ; then
    RESULT=$(echo ${1} | sed  "s&git@github.com:&github.com/&") 
  fi

  if echo ${RESULT} | grep '.git' >/dev/null 2>&1 ; then
    RESULT=$(echo ${RESULT} | rev | cut -c 5- | rev)
  fi

  /Applications/IntelliJ\ IDEA.app/Contents/MacOS/idea $(ghq root)/${RESULT}
}


gh() {
  local REPO=$(ghq list | fzf)
  if [ ! -z "${REPO}"  ]; then
    hub browse $(echo ${REPO} | cut -d "/" -f 2,3)
  fi
}

see() {
  local HOST_LINE=`tail -n +5 /etc/hosts | fzf | awk '{print $1, $2}'`
  local HOST_IP=`echo ${HOST_LINE} | awk '{print $1}'`
  local HOST_NAME=`echo ${HOST_LINE} | awk '{print $2}'`
  local HIS_LINE=`echo ${HOST_NAME} \#${HOST_IP}`
  [[ -z ${HOST_LINE} ]] && return 1

  local SSH_CMD="ssh -o ConnectTimeout=5"

  #commentout imple
  if echo "${HOST_LINE}" | grep '^#' >/dev/null 2>&1; then
    echo "it's comment out"
  else
    eval ${SSH_CMD} ${HOST_NAME}
    echo ${SSH_CMD} ${HIS_LINE} >> ~/.zsh_history
  fi
}

xssh() {
  if [ -z $TMUX ]; then
    echo "Sorry, xssh is only support on the tmux"
    return 1
  fi

  if ! which xpanes >/dev/null 2>&1; then
    echo 'xpanes is not found, Please install'
    return 1
  fi
  local HOST_LINE=`cat /etc/hosts | fzf -m | awk '{print $1, $2}'`
  if [ -z ${HOST_LINE} ]; then
    return 1
  fi
  local HOST_NAME=`echo ${HOST_LINE} | awk '{print $2}'`
  local SSH_CMD=`echo ${HOST_NAME} | xpanes ssh`

  #commentout imple
  if echo "${HOST_LINE}" | grep '^#' >/dev/null 2>&1; then
    echo "it's comment out"
  else
    eval ${SSH_CMD}
    echo ssh ${HOST_NAME} >> ~/.zsh_history
  fi
}

kexec-tmux(){
  # set vars
  local -A KEXEC_OPTHASH
  integer ret=1
  zparseopts -D -A KEXEC_OPTHASH -- \
    n: -namespace:=n \
    -kubeconfig: \
    -context: \
    -cluster: \
    -user: \
    s: -server: \
    f: -fuzzy-finder:=f \
    h -help=h
  local KEXEC_FLAG=""
  local FUZZY_FINDER_CMD="fzf"
  local KEXEC_CMD="/bin/sh"

  # parse flag
  if [[ -n "${KEXEC_OPTHASH[(i)-n]}" ]]; then 
    KEXEC_FLAG+=" --namespace ${KEXEC_OPTHASH[-n]}"
  fi
  if [[ -n "${KEXEC_OPTHASH[(i)--kubeconfig]}" ]]; then
    KEXEC_FLAG+=" --kubeconfig ${KEXEC_OPTHASH[--kubeconfig]}"
  fi
  if [[ -n "${KEXEC_OPTHASH[(i)--context]}" ]] then
    KEXEC_FLAG+=" --context ${KEXEC_OPTHASH[--context]}"
  fi
  if [[ -n "${KEXEC_OPTHASH[(i)--user]}" ]]; then
    KEXEC_FLAG+=" --user ${KEXEC_OPTHASH[--user]}"
  fi
  if [[ -n "${KEXEC_OPTHASH[(i)-s]}" ]]; then
    KEXEC_FLAG+=" --server ${KEXEC_OPTHASH[-s]}"
  fi
  if [[ -n "${KEXEC_OPTHASH[(i)-f]}" ]]; then
    FUZZY_FINDER_CMD="${KEXEC_OPTHASH[-f]}"
  fi
  if [[ -n "${KEXEC_OPTHASH[(i)-h]}" ]]; then
    echo "Usage:"
    echo "  $0 [flags] [options] [command]"
    echo ''
    echo 'Flags:'
    echo '  -n, --namespace string        Kubernetes namespace to use. Default to namespace configured in Kubernetes context'
    echo '  --kubeconfig string           Path to kubeconfig file to use'
    echo '  --context string              Kubernetes context to use. Default to current context configured in kubeconfig.'
    echo '  --user string                 The name of the kubeconfig user to use'
    echo '  -s, --server string           The address and port of the Kubernetes API server'
    echo '  -f, ---fuzzy-finder string    The name of the fuzzy finfer(peco, fzf, fzy...etc) to use, default: fzf'
    echo '  -h, --help                    Print this'
    return 1
  fi

  if [ ! -z ${1} ]; then
    KEXEC_CMD=${@}
  fi

  # must use tmux
  # https://github.com/tmux/tmux
  if [ -z $TMUX ]; then
    echo "Sorry, xssh is only support on the tmux"
    return 1
  fi

  # must use xpanes 
  # https://github.com/greymd/tmux-xpanes 
  if ! which xpanes >/dev/null 2>&1; then
    echo 'xpanes is not found, Please install'
    return 1
  fi

  # must use kubectl
  # https://github.com/kubernetes/kubectl
  if ! which kubectl >/dev/null 2>&1; then
    echo 'xpanes is not found, Please install'
    return 1
  fi

  # check excutable to select fuzzy finder (peco, fzf, ) 
  if ! which ${FUZZY_FINDER_CMD} >/dev/null 2>&1; then
    echo "${FUZZY_FINDER_CMD} is not found, Please install"
    return 1
  fi

  # if using fzf, add multi select flag
  if [ ${FUZZY_FINDER_CMD} = "fzf" ]; then
    FUZZY_FINDER_CMD+=" -m"
  fi


  # collect exec host
  local HOST_LINE=$(eval kubectl ${KEXEC_FLAG} get pods | tail +2 | eval ${FUZZY_FINDER_CMD} ) || return 1
  if [ -z ${HOST_LINE} ]; then
    return 1
  fi

  # do exec 
  local HOST_NAME=($(echo ${HOST_LINE} | awk '{print $1}')) || return ret
  xpanes -c "kubectl ${KEXEC_FLAG} exec {} -it -- ${KEXEC_CMD}" ${HOST_NAME[@]} && ret = 1
  return ret
}

pane() {
  local -A PANE_OPTHASH
  zparseopts -D -A PANE_OPTHASH -- -sync s
  local PANE_FLAG=""
  if [[ -n "${PANE_OPTHASH[(i)-s]}" ]] || [[ -n "${PANE_OPTHASH[(i)--sync]}" ]]; then
    # --syncが指定された場合
    PANE_FLAG="true"
  fi

  ## tmux pane split ##
  if [ $1 ]; then
    local COUNT=1
    while [ $COUNT -lt $1 ]
    do
    if [ $(( $COUNT & 1 )) ]; then
      tmux split-window -h
    else
            tmux split-window -v
    fi
    tmux select-layout tiled 1>/dev/null
    COUNT=$(( $COUNT + 1 ))
    done
  fi

  #OPTION: start session with "synchronized-panes"
  if [ ! -z "$PANE_FLAG" ]; then
    tmux set-window-option synchronize-panes 1>/dev/null
  fi
}

delete-zcomdump() {
  rm -f ~/.zcomdump
  rm -f ~/.zplug/zcomdump
}

calc-zsh() {
  time (zsh -i -c exit)
}

bench-zsh() {
  for i in $(seq 1 10); do time zsh -i -c exit; done
}

zload() {
  if [[ "${#}" -le 0 ]]; then
    echo "Usage: $0 PATH..."
    echo 'Load specified files as an autoloading function'
    return 1
  fi

  local file function_path function_name
  for file in "$@"; do
    if [[ -z "$file" ]]; then
      continue
    fi

    function_path="${file:h}"
    function_name="${file:t}"

    if (( $+functions[$function_name] )) ; then
      # "function_name" is defined
      unfunction "$function_name"
    fi
    FPATH="$function_path" autoload -Uz +X "$function_name"

    if [[ "$function_name" == _* ]]; then
      # "function_name" is a completion script

      # fpath requires absolute path
      # convert relative path to absolute path with :a modifier
      fpath=("${function_path:a}" $fpath) compinit
    fi
  done
}

zshrc-pull(){
  wget https://raw.githubusercontent.com/nnao45/.zshrc/master/.zshrc -P ${HOME}/
  cd ${HOME}
  exec zsh
}

zshrc-push(){
  ZSHRC_DIR=$(ghq root)/github.com/nnao45/.zshrc
  cp ${HOME}/.zshrc ${ZSHRC_DIR}
  cd ${ZSHRC_DIR}
  git add ./.zshrc
  git commit -m $(date +%Y/%m/%d_%H:%M:%S)
  git push -f origin master
  cd ${HOME}
}

hyperjs-pull(){
  wget https://raw.githubusercontent.com/nnao45/.hyper.js/master/.hyper.js -P ${HOME}/
  cd ${HOME}
  exec zsh
}

hyperjs-push(){
  HYPERJS_DIR=$(ghq root)/github.com/nnao45/.hyper.js
  cp ${HOME}/.hyper.js ${HYPERJS_DIR}
  cd ${HYPERJS_DIR}
  git add ./.hyper.js
  git commit -m $(date +%Y/%m/%d_%H:%M:%S)
  git push -f origin master
  cd ${HOME}
}

microk8s-init(){
  if ! which multipass >/dev/null 2>&1; then
    echo "Please intall multipass"
    return 1
  fi

  # Set the VM Name.
  local MICROK8S_VM_NAME="nnao45-k8s-vm"

  # Setup the VM.
  multipass launch --name ${MICROK8S_VM_NAME} --mem 4G --disk 40G --cpus 2

  # Echo the VM IP
  local MICROK8S_VM_IP=$(multipass list | tail -n1 | awk '{print $3}')
  echo ${MICROK8S_VM_NAME}"'s" IP is ${MICROK8S_VM_IP}
  
  # Sleep
  sleep 10

  # Install the Kubernetes.
  multipass exec ${MICROK8S_VM_NAME} -- sudo snap install microk8s --classic

  # Wait during wake up the microk8s.
  echo "Initial Setup is Starting"

  multipass exec ${MICROK8S_VM_NAME} -- sh -c 'while [ ! $(/snap/bin/microk8s.status > /dev/null; echo $?) -eq 0 ]; do echo -n .; sleep 1; done'

  echo "Initial Setup is Done."
  
  # Install & Setup the dns metrics-server addons.
  multipass exec ${MICROK8S_VM_NAME} -- /snap/bin/microk8s.enable dns

  # Install & Setup the kubectl
  multipass exec ${MICROK8S_VM_NAME} -- sudo snap install kubectl --classic
  multipass exec ${MICROK8S_VM_NAME} -- sh -c '/snap/bin/microk8s.config > /home/multipass/.kube/kubeconfig'
  multipass exec ${MICROK8S_VM_NAME} -- cat /home/multipass/.kube/kubeconfig > ./${MICROK8S_VM_NAME}-kubeconfig

 # Enable IPtables FORWARD policy
  multipass exec ${MICROK8S_VM_NAME} -- sudo iptables -P FORWARD ACCEPT

  echo "microk8s-init is done."
}

kubeconfig-update(){
  if [ -z ${1} ]; then
    echo "Usage: ${0} <new kubeconfig path>"
    return 1
  fi
  KUBECONFIG=~/.kube/config:${1} kubectl config view --flatten > ~/new-kubeconfig
  mv ~/.kube/config ~/.kube/config_bak
  cp ~/new-kubeconfig ~/.kube/config
  rm -f ~/new-kubeconfig
}

term-logs-archive(){
  local LOGDIR=${HOME}/term_logs
  local LAST_MONTH_DATE=$(date -v -1m +'%Y-%m')
  local LAST_MONTH_LOGDIR=${LOGDIR}/${LAST_MONTH_DATE}
  local LAST_MONTH_LOGARCHIVE=${LAST_MONTH_LOGDIR}.tar.gz
  local LAST_MONTH_LOGLIST=($(ls -1d ${LOGDIR}/* | grep ${LAST_MONTH_DATE}))

  if [ -e ${LAST_MONTH_LOGARCHIVE} ]; then
    echo 'Last month archive is existed. exit.'
    return 1
  fi
  mkdir ${LAST_MONTH_LOGDIR}
  mv ${LAST_MONTH_LOGLIST} ${LAST_MONTH_LOGDIR}
  tar cvfz ${LAST_MONTH_LOGARCHIVE} -C ${LOGDIR} ${LAST_MONTH_DATE}
  rm -rf ${LAST_MONTH_LOGDIR}
}

docker-rmi-all(){
  if [ -z ${1} ]; then
    echo "Usage: ${0} <docker image name>"
    return 1
  fi
  docker images | grep ${1} | tr -s ' ' | cut -d ' ' -f 2 | xargs -I {} docker rmi ${1}:{}
}

rust_start(){
  cat ~/.gitconfig | tail -n17 > ./.git/config
}

########################################
# その他
# ローカルの設定を見る
if [ -e　~/.zshrc_local ]; then
  source ~/.zshrc_local
fi

# fzfのパス
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# added by travis gem
[ -f /Users/s02435/.travis/travis.sh ] && source /Users/s02435/.travis/travis.sh
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/home/nnao45/.sdkman"
[[ -s "/home/nnao45/.sdkman/bin/sdkman-init.sh" ]] && source "/home/nnao45/.sdkman/bin/sdkman-init.sh"


