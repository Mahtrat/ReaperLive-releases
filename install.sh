#!/bin/zsh
# Asentaa tai päivittää Reaper Liven: sovellus /Applications-kansioon, sivu ja apuskripti REAPERiin.
# Ensiasennus koneelle (Pääte-ohjelmassa):
#   curl -fsSL https://raw.githubusercontent.com/Mahtrat/ReaperLive-releases/main/install.sh | zsh
# Sovellus ajaa saman skriptin, kun sitä pyydetään päivittämään. tools/release.sh julkaisee tämän tiedoston.
set -euo pipefail
repo=Mahtrat/ReaperLive-releases
app="/Applications/Reaper Live.app"
tmp=$(mktemp -d); trap 'rm -rf $tmp' EXIT
echo "$(date '+%F %T') haetaan uusin Reaper Live"
# curl ei merkitse latausta karanteeniin, joten macOS avaa sovelluksen ilman Applen allekirjoitusta
curl -fsSL "https://github.com/$repo/releases/latest/download/ReaperLive.zip" -o $tmp/r.zip
ditto -x -k $tmp/r.zip $tmp/x
[[ -x "$tmp/x/Reaper Live.app/Contents/MacOS/ReaperLive" && -f $tmp/x/reaper/reaperlive.html ]] || { echo "paketti on rikki, mitään ei muutettu"; exit 1; }

osascript -e 'quit app id "fi.musiikkitalo.reaperlive"' >/dev/null 2>&1 || true
for i in {1..20}; do pgrep -x ReaperLive >/dev/null || break; sleep 0.5; done
pkill -x ReaperLive 2>/dev/null || true
rm -rf "$app" /Applications/ReaperLive.app "$HOME/Applications/ReaperLive.app"
ditto "$tmp/x/Reaper Live.app" "$app"
xattr -cr "$app"

res="$HOME/Library/Application Support/REAPER"
if [[ -d $res ]]; then
  mkdir -p "$res/reaper_www_root" "$res/Scripts"
  cp $tmp/x/reaper/reaperlive.html "$res/reaper_www_root/"
  cp $tmp/x/reaper/reaperlive_bridge.lua $tmp/x/reaper/reaperlive_install.lua "$res/Scripts/"
  grep -q reaperlive_bridge.lua "$res/Scripts/__startup.lua" 2>/dev/null || echo "Ensiasennus: aja REAPERissa kerran Scripts/reaperlive_install.lua (Actions > Load ReaScript)."
  echo "Uusi apuskripti otetaan käyttöön, kun REAPER käynnistetään seuraavan kerran."
else
  echo "REAPERia ei löytynyt: sivu ja apuskripti jäivät asentamatta."
fi
open "$app"
echo "$(date '+%F %T') valmis: $(defaults read "$app/Contents/Info" CFBundleShortVersionString)"
