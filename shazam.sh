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
  local hash_to_check="$(gen_pw "$2" "$3" "$4" "$5")"
  if [[ $original_hash == $hash_to_check ]]; then
    echo "✅ $original_hash = $hash_to_check" && return 0
  else
    echo "❌ $original_hash != $hash_to_check" && return 1
  fi
}

#Note this is the easiest case because all parameters for gen_pw are known except $3, because $3 has fixed limits (56 due to length of sha256 hash), and can therefore be guessed the quickest
#Also note this function assumes that all parameters are known besides $4 (cut-off-var)
find_pw_cut_off_var() { #same parameters as match_pw, but $4 in this case varies by loop iteration number, so $5 replaces $4.
  local i=0
  while [[ $i -le 56 ]]; do
    match_pw $1 $2 $3 $i $4 > /dev/null
    if [[ $? == 0 ]]; then
      echo "Iteration $i: ✅ Success!"
      return 0
    else
      echo "Iteration $i: ❌"
      i=$((i + 1))
    fi
  done
  echo "no successful matches were found :("
  return 1
}

find_pw_it_1() { #$1 = original hash; $2 = pw test name; $3 = cut-off-var; $4 = iteration 2 shan;
  local i=1
  while [[ $i -lt 1000 ]]; do
    match_pw "$1" "$2" "$i" "$3" "$4" > /dev/null
    if [[ $? == 0 ]]; then
      echo "Iteration $i: ✅ Success!"
      return 0
    else
      echo "Iteration $i: ❌"
      i=$((i + 1))
    fi
    if (( $i % 100 == 0 )); then
      echo "iteration $i was passed"
    fi
  done
}
