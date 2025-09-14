#!/bin/bash
shan() { #stdin = password seed; $1 = number of iterations through sha1 algorithm
  read hash_in
  if [[ $1 ]]; then
    n="$1"
  else
    n=1
  fi
  for i in $(seq 1 $n); do
    hash_in="$(echo $hash_in | sha1)"
  done
  echo $hash_in
}

cut_at_n() { #stdin = input; $1 = cut-off-point
  read input
  local cut_off_point="$1"
  echo "${input:$cut_off_point:40}"
}

gen_pw() { #$1 = password seed; $2 = number of iterations for shan func; $3 = cut-off-var (0 <= $3 <= 56); $4 = number of iterations on round 2
  echo "$1" | shan "$2" | sha384 | cut_at_n "$3" | shan "$4" | sha256
}

match_pw() { #$1 = original hash; $2 = password to check; $3 = iterations round 1 for check; $4 = cut-off-var for check; $5 = iterations round 2 for check
  local original_hash="$1"
  local pw_to_check="$2"
  local hash_to_check="$(gen_pass "$2" "$3" "$4" "$5")"
  if [[ $original_hash == $hash_to_check ]]; then
    echo "✅ $original_hash = $hash_to_check"
  else
    echo "❌ $original_hash != $hash_to_check"
  fi
}
