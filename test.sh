#!/bin/bash

# Run this file to run all the tests, once
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

"${DIR}/tests/Bash-Automated-Testing-System/bats-core/bin/bats" "${DIR}/tests/"*".bats"
