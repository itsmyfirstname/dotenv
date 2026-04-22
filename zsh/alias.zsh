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


function archer-flash-usb() {
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

alias archer-py-activate="source .venv/bin/activate"

if [[ -n $network_uuid && -n $net_device_uuid ]]; then
  alias archer-set-custom-dns="nmcli con show ${network_uuid} | grep ipv | grep .dns  && sudo nmcli con mod ${network_uuid} ipv4.dns '$onedotipv4' ipv4.ignore-auto-dns yes && sudo nmcli connection modify ${network_uuid} connection.dns-over-tls 1 && sudo nmcli general reload dns-full && sudo nmcli dev reapply ${net_device_uuid} && nmcli con show ${network_uuid} | grep ipv | grep .dns  && nslookup google.com "

  alias archer-set-default-dns="nmcli con show ${network_uuid} | grep ipv | grep .dns  && nmcli con mod ${network_uuid} ipv4.dns '' ipv4.ignore-auto-dns no ipv6.dns '' ipv6.ignore-auto-dns no connection.dns-over-tls 0 && nmcli general reload dns-full && nmcli dev reapply ${net_device_uuid} && nmcli con show ${network_uuid} | grep ipv | grep .dns && nslookup google.com "
  alias archer-dns-test="nmcli con show ${network_uuid} | grep ipv | grep .dns && nslookup google.com "
fi

alias archer-seedbox="qssh mehays@192.168.1.148"

alias qtmux="tmux new-session -A -s main"
alias archer-ls-used-local-ports="sudo ss -tulpn"
