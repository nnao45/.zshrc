#######################################
# コマンドのインストール管理
# zplug
if [ ! -d ~/.zplug ]; then
  curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
fi

# fzf
#if ! which fzf >/dev/null 2>&1; then
#  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
#  ~/.fzf/install
#fi

# tmux
if ! which tmux >/dev/null 2>&1; then
  if [[ "$(uname)" = 'Darwin' ]] ; then
    brew install tmux
  elif [[ "$(uname)" = 'Linux' ]] ; then
    wget https://github.com/tmux/tmux/releases/download/2.8/tmux-2.8.tar.gz -P $HOME/tmux-2.8
    cd tmux-2.8
    tar xvfz tmux-2.8.tar.gz
    cd tmux-2.8
    ./configure && make
    make install
    cd ${HOME}
    rm -rf tmux-2.8 tmux-2.8.tar.gz
  fi
fi

# go
if ! which go >/dev/null 2>&1; then
  UNAME=""
  if [[ "$(uname)" = 'Darwin' ]] ; then
    UNAME="darwin"
#  elif [[ "$(uname)" = 'Linux' ]] ; then
#    UNAME="linux"
  fi
#  mkdir $HOME/go
#  mkdir $HOME/go-third-party
#  export GOPATH=$HOME/go-third-party
#  mkdir -p $GOPATH/src/github.com/
#  wget -qO- "https://dl.google.com/go/go1.11.2.${UNAME}-amd64.tar.gz" | tar -zx --strip-components=1 -C $HOME/go
fi

# rust
if ! which rustc >/dev/null 2>&1; then
  curl https://sh.rustup.rs -sSf | sh
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
zstyle ':completion:*:*:kubectl:*' list-grouped false

# Tracks your most used directories, based on 'frecency'.
zplug "rupa/z", use:"*.sh" lazy:true

# zsh内のtmuxでペイン単位で、SSHなど特定のコマンドが終わるまでだけタイムスタンプ付きのログを取る
zplug "nnao45/ztl", use:'src/_*' lazy:true

# コマンドラインで絵文字
zplug "b4b4r07/emoji-cli", lazy:true

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

  #エディタをvimに設定
  export EDITORP=vim

  #tmuxinaotrの為に
  export SHELL=zsh

  # zshrcをコンパイル確認
  if [ ~/.zshrc -nt ~/.zshrc.zwc ]; then
    zcompile ~/.zshrc
  fi

  # fzfのオプション
  export FZF_DEFAULT_OPTS='
    --height 30% --reverse
    --color=bg+:161,pointer:7,spinner:227,info:227,prompt:161,hl:199,hl+:227,marker:227
    --no-mouse
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

# 頑張って両方にprmptを表示させるヤツ https://qiita.com/zaapainfoz/items/355cd4d884ce03656285
precmd() {
  autoload -Uz vcs_info
  autoload -Uz add-zsh-hook

  zstyle ':vcs_info:git:*' check-for-changes true
  zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
  zstyle ':vcs_info:git:*' unstagedstr "%F{magenta}+"
  zstyle ':vcs_info:*' formats '%F{green}%c%u{%r}-[%b]%f'
  zstyle ':vcs_info:*' actionformats '%F{red}%c%u{%r}-[%b|%a]%f'

  local left=$'%{\e[38;5;083m%}%n%{\e[0m%} %{\e[$[32+$RANDOM % 5]m%}➜%{\e[0m%} %{\e[38;5;051m%}%d%{\e[0m%}'
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

PROMPT=$'%{\e[$[32+$RANDOM % 5]m%}❯%{\e[0m%}%{\e[$[32+$RANDOM % 5]m%}❯%{\e[0m%}%{\e[$[32+$RANDOM % 5]m%}❯%{\e[0m%} '
RPROMPT=$'%{\e[38;5;001m%}%(?..✘☝)%{\e[0m%} %{\e[30;48;5;237m%}%{\e[38;5;249m%} %D %* %{\e[0m%}'

# プロンプト自動更新設定
autoload -U is-at-least
# $EPOCHSECONDS, strftime等を利用可能に
zmodload zsh/datetime

reset_tmout() {
  TMOUT=$[30-EPOCHSECONDS%30]
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
#eval `dircolors`
export LSCOLORS=gxfxcxdxbxegedabagacad
export LS_COLORS='di=36:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
zstyle ':completion:*' verbose yes
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors 'di=36' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'
zstyle ':completion:*' format '%B%d%b'
zstyle ':completion:*' group-name

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
if which /usr/local/bin/aws >/dev/null 2>&1; then
  source /usr/local/bin/aws_zsh_completer.sh
elif which /usr/bin/aws >/dev/null 2>&1; then
  source /usr/bin/aws_zsh_completer.sh
elif which ~/.local/bin/aws >/dev/null 2>&1; then
  source ~/.local/bin/aws_zsh_completer.sh
fi

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
zle -N fzf-z-search
bindkey '^F' fzf-z-search

# cd up
cd-up() {
  #zle push-line && LBUFFER='builtin cd ..' && zle accept-line
  zle push-line && LBUFFER='..' && zle accept-line
}
zle -N cd-up
bindkey "^Q" cd-up

# word forward
bindkey "^N" forward-word
bindkey "^B" backward-word

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
abbrev-alias -g L='| less'
abbrev-alias -g G='| grep'
abbrev-alias -g B='| bc'
abbrev-alias -g E='| emojify'
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
autoload -Uz zmv
alias zmv='noglob zmv -W'

# popd
abbrev-alias pd='popd'

# kubectl
alias k='kubectl'
abbrev-alias ka='kubectl apply'
abbrev-alias kd='kubectl delete'
abbrev-alias kg='kubectl get'
abbrev-alias kga='kubectl get all --all-namespaces -o wide'
abbrev-alias ke='kubectl exec'

# fzf
abbrev-alias f='fzf'
abbrev-alias fp="fzf --preview 'cat {}'"

if [ -n $TMUX ]; then
  abbrev-alias fzf='fzf-tmux -d 30%'
fi

########################################
# 自作関数の設定
tkill() {
  tmux kill-session -t "$1"
}

tkillall() {
  tmux kill-server
}

see() {
  local -A SEE_OPTHASH
  zparseopts -D -A SEE_OPTHASH -- -log l
  local LOG_FLAG=""
  if [[ -n "${SEE_OPTHASH[(i)-l]}" ]] ||  [[ -n "${SEE_OPTHASH[(i)--log]}" ]]; then
    # --logが指定された場合
    LOG_FLAG="true"
  fi
  local HOST_LINE=`tail -n +5 /etc/hosts | fzf | awk '{print $1, $2}'`
  local HOST_IP=`echo ${HOST_LINE} | awk '{print $1}'`
  local HOST_NAME=`echo ${HOST_LINE} | awk '{print $2}'`
  local HIS_LINE=`echo ${HOST_NAME} \#${HOST_IP}`
  [[ -z ${HOST_LINE} ]] && return 1

  local SSH_CMD="ssh -o ConnectTimeout=5"
  if [[ ! -z ${LOG_FLAG}  ]]; then
    SSH_CMD="ztl ssh"
  fi

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

report-zsh() {
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
  rm -f ${HOME}/.zshrc
  wget https://raw.githubusercontent.com/nnao45/.zshrc/master/.zshrc -P ${HOME}/
  cd ${HOME}
  exec zsh
}

zshrc-push(){
  ZSH_TMPDIR=${HOME}/tmp-zshdir
  mkdir ${ZSH_TMPDIR}
  git clone https://github.com/nnao45/.zshrc.git ${ZSH_TMPDIR}
  rm -f ${ZSH_TMPDIR}/.zshrc
  cp ${HOME}/.zshrc ${ZSH_TMPDIR}
  cd ${ZSH_TMPDIR}
  git add .
  git commit -m $(date +%Y/%m/%d_%H:%M:%S)
  git push -f origin master
  rm -rf ${ZSH_TMPDIR}
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

  # Install the Kubernetes.
  multipass exec ${MICROK8S_VM_NAME} -- sudo snap install microk8s --classic
  multipass exec ${MICROK8S_VM_NAME} -- sudo iptables -P FORWARD ACCEPT

  # Wait during wake up the microk8s.
  echo "Initial Setup is Starting"

  multipass exec ${MICROK8S_VM_NAME} -- sh -c 'while [ ! $(/snap/bin/microk8s.status > /dev/null; echo $?) -eq 0 ]; do echo -n .; sleep 1; done'

  echo "Initial Setup is Done."
  
  # Install & Setup the dns metrics-server addons.
  multipass exec ${MICROK8S_VM_NAME} -- /snap/bin/microk8s.enable dns metrics-server

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
  local LAST_MONTH_LOGLIST=($(ls -1d ${LOGDIR}/* | grep ${LAST_MONTH_DATE}))

  mkdir ${LAST_MONTH_LOGDIR}
  mv ${LAST_MONTH_LOGLIST} ${LAST_MONTH_LOGDIR}
  tar cvfz ${LAST_MONTH_LOGDIR}.tar.gz -C ${LOGDIR} ${LAST_MONTH_DATE}
  rm -rf ${LAST_MONTH_LOGDIR}
}

########################################
# その他
# ローカルの設定を見る
if [ -e　~/.zshrc_local ]; then
  source ~/.zshrc_local
fi

# fzfのパス
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
