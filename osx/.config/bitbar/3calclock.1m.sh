#!/usr/bin/env bash

vpad() {
  tmp="$(mktemp)"
  cat >"$tmp"

  len="$(wc -l < "$tmp")"
  if [ $len -gt 0 ]; then
    pad="$(echo $(($1 - $len)))"
    above="$(echo $(($pad / 2)))"
    below="$(echo $((($pad + 1) / 2)))"
    [ $above -gt 0 ] && yes ' ' | head -n $above
    cat "$tmp"
    [ $below -gt 0 ] && yes ' ' | head -n $below
  fi

  rm -f "$tmp"
}

pad_cal() {
  cat - <(echo ' ') |
    sed 's/.//g' |
    tr '\n' '\0' |
    xargs -0 printf '  %-20s\n'
}

# http://unix.stackexchange.com/a/182545
m=$(date +%m) y=$(date +%Y)
m=${m#"${m%%[!0]*}"}
if ((m == 1)); then
  pm=12       py=$((y-1))
else
  pm=$((m-1)) py=$y
fi
if ((m == 12)); then
  nm=1        ny=$((y+1))
else
  nm=$((m+1)) ny=$y
fi
cal="$(paste -d ' '\
  <(cal $pm $py | pad_cal) \
  <(cal | pad_cal) \
  <(cal $nm $ny | pad_cal) |
  awk 'NF {print $0 "|trim=false font=Menlo size=12"}' | cut -c2-)"

wtr="$(curl -sf 'wttr.in?m' | head -n7 | awk 'NF' |
  vpad "$(wc -l <<< "$cal")" |
  awk 'length {print $0 "|alternate=true trim=false font=Menlo size=12"}')"

LANG='ja_JP.UTF-8' date '+%a %-m/%-d %-H:%M'
echo '---'
paste -d '\n' <(echo "$cal") <(echo "$wtr")
