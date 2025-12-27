#! /usr/bin/zsh

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

function lazygit() {
	case $1 in 
		show-remote) # Show remotes
			git remote -v
			;;
		undo-commit)
			git reset --soft HEAD~1
			;;
		push) # Assume we just want to commit and push some changes
			git add . && git commit -m "$1" && git push
			;;
		*)
			echo "push | show-remote | undo-commit"
	esac
}

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

alias pacup="sudo pacman -Syu" # Full System Upgrade, prepare your...evening, could get messy
alias pyactivate="source .venv/bin/activate"
