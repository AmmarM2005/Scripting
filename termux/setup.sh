#!/data/data/com.termux/files/usr/bin/bash
pkg update -y && pkg install -y git openssh gh jq curl

# SSH key + alias
mkdir -p ~/.ssh && chmod 700 ~/.ssh
KEY=~/.ssh/id_ed25519_github
[ -f $KEY ] || ssh-keygen -t ed25519 -C "termux-$(getprop ro.product.model 2>/dev/null | tr ' ' '-')" -f $KEY -N ""
sed -i '/^Host github-ammarm2005$/,/^$/d' ~/.ssh/config 2>/dev/null
cat >> ~/.ssh/config << EOF

Host github-ammarm2005
  HostName github.com
  User git
  IdentityFile $KEY
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new

EOF
chmod 600 ~/.ssh/config $KEY

echo; echo "=== COPY THIS PUBLIC KEY ==="; cat $KEY.pub; echo "============================"
echo "Add it at: github.com/settings/ssh/new  (any title, key type: Authentication)"
read -p "Press Enter after you've added it on GitHub... " _

# Git identity
git config --global user.name "AmmarM2005"
git config --global user.email "itsammarm52@gmail.com"
git config --global --add safe.directory '*'
mkdir -p ~/storage/shared/Git

cat > ~/clone-all.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
cd ~/storage/shared/Git || exit 1
if gh auth status >/dev/null 2>&1; then
  repos=$(gh repo list AmmarM2005 --limit 200 --json name -q '.[].name')
else
  echo "gh not logged in: listing public repos only"
  repos=$(curl -s "https://api.github.com/users/AmmarM2005/repos?per_page=100" | jq -r '.[].name')
fi
for r in $repos; do
  if [ -d "$r/.git" ]; then echo "have   $r"; continue; fi
  if [ -d "$r" ]; then echo "SKIP   $r (folder exists, not a git repo)"; continue; fi
  git clone "git@github-ammarm2005:AmmarM2005/$r.git" && git -C "$r" config core.fileMode false
done
EOF

cat > ~/push.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
BASE=~/storage/shared/Git
repos=${1:-$(ls -d "$BASE"/*/.git 2>/dev/null | xargs -n1 dirname | xargs -n1 basename)}
for r in $repos; do
  cd "$BASE/$r" || continue
  [ -z "$(git status --porcelain)" ] && continue
  echo "== $r =="
  git pull --rebase --autostash
  git add -A
  git commit -m "${2:-notes: $(date '+%Y-%m-%d %H:%M')}"
  git push
done
EOF
chmod +x ~/clone-all.sh ~/push.sh

ssh -T github-ammarm2005
gh auth login
~/clone-all.sh 2>&1 | grep -E "^(have|SKIP|fatal|error)"
echo "SETUP COMPLETE"
