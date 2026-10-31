# Тема «Hacker»: зелёный терминал из фильмов.

parse_git_branch() {
  git branch 2>/dev/null | grep '\*' | sed 's/* / /'
}
exit_status() {
  local s=$?
  if [ $s -ne 0 ]; then
    echo -e "\e[38;5;196m[$s]\e[0m "
  fi
}
PS1='\[\e[38;5;46m\]┌[\[\e[38;5;208m\]\u\[\e[38;5;46m\]@\[\e[38;5;208m\]\h\[\e[38;5;46m\]]-[\[\e[38;5;46m\]\w\[\e[38;5;46m\]]\[\e[38;5;214m\]$(parse_git_branch)\[\e[0m\]
\[\e[38;5;46m\]└$(exit_status)\[\e[38;5;46m\]▶\[\e[0m\] '

__theme_not_found() {
  local cmd="$1"
  echo ""
  echo -e "\e[38;5;196m  ╔═══ ERROR ═══════════════════════════════════╗\e[0m"
  echo -e "\e[38;5;196m  ║\e[0m \e[38;5;46m[SYSTEM]\e[0m Компонент '\e[38;5;208m$cmd\e[0m' не найдено в \$PATH   \e[0m"
  echo -e "\e[38;5;196m  ║\e[0m \e[38;5;46m[HINT]\e[0m   nix-shell -p $cmd                  \e[0m"
  echo -e "\e[38;5;196m  ║\e[0m \e[38;5;46m[HINT]\e[0m   nix search nixpkgs#$cmd             \e[0m"
  echo -e "\e[38;5;196m  ╚═════════════════════════════════════════════╝\e[0m"
  echo ""
}

__theme_wrong_layout() {
  echo ""
  echo -e "\e[38;5;214m  ╔═══ LAYOUT ══════════════════════════════════╗\e[0m"
  echo -e "\e[38;5;214m  ║\e[0m \e[38;5;46m[INPUT]\e[0m  '\e[38;5;208m$1\e[0m' — раскладка RU"
  echo -e "\e[38;5;214m  ║\e[0m \e[38;5;46m[FIX]\e[0m    $2"
  echo -e "\e[38;5;214m  ╚═════════════════════════════════════════════╝\e[0m"
  echo ""
}

alias matrix="echo -e '\e[38;5;46mПроснись, Нео...\e[0m'"
alias hack="echo -e '\e[38;5;196m[ACCESS DENIED]\e[0m Шучу...'"

echo ""
echo -e "\e[38;5;46m  ┌─────────────────────────────────────────────┐\e[0m"
echo -e "\e[38;5;46m  │\e[0m  \e[38;5;46m█▀▀ █▀█ █▀▄ █▀▀   █ █▀   █   █▀█ █ █\e[0m  \e[38;5;46m     │\e[0m"
echo -e "\e[38;5;46m  │\e[0m  \e[38;5;46m█▄▄ █▄█ █▄▀ ██▄   █ ▄█   █▄▄ █▀█ ▀▄▀\e[0m  \e[38;5;46m     │\e[0m"
echo -e "\e[38;5;46m  ├─────────────────────────────────────────────┤\e[0m"
echo -e "\e[38;5;46m  │\e[0m                                             \e[38;5;46m│\e[0m"
echo -e "\e[38;5;46m  │\e[0m  \e[38;5;46m[SYS]\e[0m Kernel: \e[38;5;208m$(uname -r)\e[0m            \e[38;5;46m│\e[0m"
echo -e "\e[38;5;46m  │\e[0m  \e[38;5;46m[SYS]\e[0m User:   \e[38;5;208m$USER@$(hostname)\e[0m                \e[38;5;46m│\e[0m"
echo -e "\e[38;5;46m  │\e[0m  \e[38;5;46m[SYS]\e[0m Shell:  \e[38;5;208m$BASH_VERSION\e[0m             \e[38;5;46m│\e[0m"
echo -e "\e[38;5;46m  │\e[0m  \e[38;5;46m[SYS]\e[0m Time:   \e[38;5;208m$(date '+%H:%M:%S')\e[0m                     \e[38;5;46m│\e[0m"
echo -e "\e[38;5;46m  │\e[0m                                             \e[38;5;46m│\e[0m"
echo -e "\e[38;5;46m  │\e[0m  \e[38;5;240m> Система в вашем распоряжении.\e[0m            \e[38;5;46m│\e[0m"
echo -e "\e[38;5;46m  │\e[0m  \e[38;5;240m> Используйте её с умом.                   \e[38;5;46m│\e[0m"
echo -e "\e[38;5;46m  │\e[0m                                             \e[38;5;46m│\e[0m"
echo -e "\e[38;5;46m  └─────────────────────────────────────────────┘\e[0m"
echo ""
