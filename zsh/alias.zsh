#! /usr/bin/zsh
NETWORK_NAME="Hey_Beaches"
onedotipv4="192.168.1.171 1.1.1.1 9.9.9.9"
network_uuid=""
net_device_uuid=""
if command -v nmcli >/dev/null 2>&1 && nmcli connection show 2>/dev/null | grep -q "$NETWORK_NAME"; then
  network_uuid="$(nmcli connection show | grep "$NETWORK_NAME" | awk '{print $2}')"
  net_device_uuid="$(nmcli connection show | grep "$NETWORK_NAME" | awk '{print $4}')"
fi


function qedit() {

	case $1 in
	  zsh)
		  nvim $HOME/.config/zsh/
		  ;;
	  zshrc)
		  nvim $HOME/.zshrc
		  ;;
	  nvim)
		  nvim $HOME/.config/nvim/init.lua
		  ;;

	  config | conf)
		  nvim $HOME/.config 
		  ;;
	  *)
		  echo "Availavle options: zsh | zshrc | config"
		  ;;
	esac
}

function qssh() {
	echo "connecting $@"
	kitty +kitten ssh $@
}


function flash-usb() {
	source_iso=${1:-""}
	mount_device=${2:-"/dev/sda"}

	if [[ -z $source_iso ]]; then
		echo "Need source ISO"
		return
	fi

	echo "Source: ${source_iso}"
	echo "Mounted Device: ${mount_device}"
	echo "Everything look good?"
	read continue_flash
	if [[ "$continue_flash" == "y" || "$continue_flash" == "Y" ]]; then
		echo "Proceeding: $continue_flash"
		sudo dd bs=4M if=$source_iso of=$mount_device status=progress oflag=sync
	fi
	echo "Exiting..."

}

# function lazygit() {
# 	case $1 in 
# 		show-remote) # Show remotes
# 			git remote -v
# 			;;
# 		undo-commit)
# 			git reset --soft HEAD~1
# 			;;
# 		push) # Assume we just want to commit and push some changes
# 			git add . && git commit -m "$1" && git push
# 			;;
# 		*)
# 			echo "push | show-remote | undo-commit"
# 	esac
# }

function lazynet() {
	case $1 in
		show) # Show available networks
			nmcli dev wifi list
			;;
		connect)
			nmcli dev wifi connect $2 -a
			;;
		*)
			echo "Available options: show | connect"
			printf "example: lazynet connect myNetwork"
			nmcli --help
			;;
	esac
}

if [[ -r /etc/arch-release ]] && command -v pacman >/dev/null 2>&1; then
  alias archer-refresh-keyring="sudo pacman -Sy archlinux-keyring"
  alias archer-full-upgrade="archer-refresh-keyring && sudo pacman -Syu" # Full System Upgrade, prepare your...evening, could get messy
  alias archer-refresh-package-lists="archer-refresh-keyring && sudo pacman -Syyu"
fi


if [[ -n $network_uuid && -n $net_device_uuid ]]; then
  alias dns-set-custom="nmcli con show ${network_uuid} | grep ipv | grep .dns  && sudo nmcli con mod ${network_uuid} ipv4.dns '$onedotipv4' ipv4.ignore-auto-dns yes && sudo nmcli connection modify ${network_uuid} connection.dns-over-tls 1 && sudo nmcli general reload dns-full && sudo nmcli dev reapply ${net_device_uuid} && nmcli con show ${network_uuid} | grep ipv | grep .dns  && nslookup google.com "

  alias dns-set-default="nmcli con show ${network_uuid} | grep ipv | grep .dns  && nmcli con mod ${network_uuid} ipv4.dns '' ipv4.ignore-auto-dns no ipv6.dns '' ipv6.ignore-auto-dns no connection.dns-over-tls 0 && nmcli general reload dns-full && nmcli dev reapply ${net_device_uuid} && nmcli con show ${network_uuid} | grep ipv | grep .dns && nslookup google.com "
  alias dns-test="nmcli con show ${network_uuid} | grep ipv | grep .dns && nslookup google.com "
fi

alias dot-venv-activate="source .venv/bin/activate"
alias dot-ssh-seedbox="qssh mehays@192.168.1.148"
alias dot-tmux="tmux new-session -A -s main"
alias dot-ls-local-ports="sudo ss -tulpn"
#alias hey-git-mirror-this-repo="git clone --bare ${1} && cd $(basename ${1}) && git push --mirror ${2}"
#alias hey-git-mirror-this-repo="echo $1 && echo $2"
alias codium="flatpak run com.vscodium.codium "
alias zed="flatpak run dev.zed.Zed "

function dev() {
    if [[ -z "$1" ]]; then
        echo "Usage: dev <directory_path>"
        return 1
    fi

    local dir_path="$(realpath "$1")"
    if [[ ! -d "$dir_path" ]]; then
        echo "Error: Directory '$dir_path' does not exist."
        return 1
    fi

    local session_name="$(basename "$dir_path")"

    # Create session if it doesn't exist
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -c "$dir_path"
    fi
    
    # KILL all panes except one, to ensure a clean slate
    tmux kill-pane -a -t "$session_name:0"
    
    # CREATE the layout from scratch with exactly 3 panes:
    # 1. Split the first pane (pane 0) horizontally (40% for right pane)
    tmux split-window -h -p 40 -t "$session_name:0" -c "$dir_path"
    
    # 2. Split the right pane (pane 1) vertically (50% for bottom pane)
    tmux split-window -v -p 50 -t "$session_name:0.1" -c "$dir_path"
    
    # SEND commands to specific panes in correct order
    # Pane layout (after splits): 0.0=left (nvim), 0.1=top-right (clear), 0.2=bottom-right (opencode)
    # Use explicit pane targeting with session:window.pane format
    tmux send-keys -t "$session_name:0.0" "nvim" C-m
    tmux send-keys -t "$session_name:0.1" "clear" C-m
    tmux send-keys -t "$session_name:0.2" "opencode" C-m
    
    # SELECT the left pane for initial focus
    tmux select-pane -t "$session_name:0.0"

    # ATTACH to the session
    if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$session_name"
    else
        tmux attach-session -t "$session_name"
    fi
}

