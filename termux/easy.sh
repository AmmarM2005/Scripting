#!/data/data/com.termux/files/usr/bin/bash
pkg install -y nano < /dev/null

# ---- note: create a dated note, edit it, push it ----
cat > $PREFIX/bin/note << 'EOF1'
#!/data/data/com.termux/files/usr/bin/bash
BASE=~/storage/shared/Git
subj=$1; title=$2
if [ -z "$subj" ]; then
  PS3="Subject number: "
  select subj in Physics Mathematics Chemistry Other; do [ -n "$subj" ] && break; done
  [ "$subj" = Other ] && read -p "Repo folder name: " subj
fi
[ -d "$BASE/$subj/.git" ] || { echo "No repo named $subj"; exit 1; }
[ -z "$title" ] && read -p "Title: " title
slug=$(echo "$title" | tr 'A-Z' 'a-z' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')
f="$BASE/$subj/$(date +%F)-$slug.md"
[ -f "$f" ] || printf '# %s\n\n_%s_\n\n' "$title" "$(date '+%d %b %Y')" > "$f"
nano "$f"
~/push.sh "$subj" "notes: $title"
EOF1

# ---- g: tap-through menu ----
cat > $PREFIX/bin/g << 'EOF2'
#!/data/data/com.termux/files/usr/bin/bash
BASE=~/storage/shared/Git
while true; do
  clear
  echo "====== GIT MENU ======"
  echo " 1  Push everything"
  echo " 2  New note"
  echo " 3  What changed?"
  echo " 4  Pull / sync all"
  echo " 5  Get new repos"
  echo " 6  Quit"
  read -p "> " c
  case $c in
    1) ~/push.sh ;;
    2) note ;;
    3) for d in "$BASE"/*/.git; do r=${d%/.git}; n=$(git -C "$r" status --porcelain | wc -l); [ "$n" -gt 0 ] && echo "$(basename "$r"): $n changed"; done; echo "(end)" ;;
    4) for d in "$BASE"/*/.git; do r=${d%/.git}; echo "== $(basename "$r")"; git -C "$r" pull --rebase --autostash -q; done ;;
    5) ~/clone-all.sh 2>&1 | grep -v "^have" ;;
    6|q) exit ;;
  esac
  read -p "Press Enter..." _
done
EOF2
chmod +x $PREFIX/bin/note $PREFIX/bin/g

# ---- shortcuts + startup banner ----
sed -i '/# >>> easygit >>>/,/# <<< easygit <<</d' ~/.bashrc 2>/dev/null
cat >> ~/.bashrc << 'EOF3'
# >>> easygit >>>
alias p='~/push.sh'
alias n='note'
cd ~/storage/shared/Git 2>/dev/null
for d in ~/storage/shared/Git/*/.git; do r=${d%/.git}; c=$(git -C "$r" status --porcelain 2>/dev/null | wc -l); [ "$c" -gt 0 ] && echo "! $(basename "$r"): $c uncommitted"; done
echo "g = menu | n = new note | p = push all"
# <<< easygit <<<
EOF3

# ---- handy extra-keys row ----
mkdir -p ~/.termux
cat > ~/.termux/termux.properties << 'EOF4'
extra-keys = [['ESC','TAB','CTRL','ALT','UP','DOWN'],['/','-','~','|','LEFT','RIGHT']]
EOF4
termux-reload-settings 2>/dev/null

# ---- home-screen widget buttons (needs Termux:Widget app) ----
mkdir -p ~/.shortcuts
printf '#!/data/data/com.termux/files/usr/bin/bash\n~/push.sh\necho; read -p "Done. Press Enter to close" _\n' > ~/.shortcuts/Push-All.sh
printf '#!/data/data/com.termux/files/usr/bin/bash\nnote\necho; read -p "Done. Press Enter to close" _\n' > ~/.shortcuts/New-Note.sh
chmod +x ~/.shortcuts/*.sh

# ---- back up to Scripting repo so a new phone gets it too ----
cp ~/easy.sh ~/storage/shared/Git/Scripting/termux/easy.sh
~/push.sh Scripting "add easy-use Termux commands"
echo "EASY SETUP DONE - close and reopen Termux"
