# Тема «Minimal»: только промпт, без приветствия.

parse_git_branch() {
  git branch 2>/dev/null | grep '\*' | sed 's/* / /'
}
PS1='\[\e[38;5;245m\][\[\e[38;5;75m\]\u\[\e[38;5;245m\]@\[\e[38;5;75m\]\h\[\e[38;5;245m\]]\[\e[0m\] \[\e[38;5;252m\]\w\[\e[38;5;114m\]$(parse_git_branch)\[\e[0m\] \$ '

__theme_not_found() {
  echo ""
  echo "  ✗ Команда не найдена: $1"
  echo "    → nix-shell -p $1"
  echo "    → nix search nixpkgs#$1"
  echo ""
}

__theme_wrong_layout() {
  echo ""
  echo "  ⌨ Не та раскладка: $1"
  echo "    → $2"
  echo ""
}
