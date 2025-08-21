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
		remote) # Show remotes
			git remote -v
			;;
		*) # Assume we just want to commit and push some changes
			git add . && git commit -m "$1" && git push
			;;
	esac
}

alias pacup="sudo pacman -Syu" # Full System Upgrade, prepare your...evening, could get messy
