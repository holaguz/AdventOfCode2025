DAY        ?= $(shell date '+%-d')
URL        := https://adventofcode.com/2025/day/$(DAY)/input
SUBPATH    := src/day$(DAY)
INPUT_PATH := $(SUBPATH)/input
TEST_PATH  := $(SUBPATH)/test
USER_AGENT := holaguz/AdventOfCode2025 (acatellani@proton.me)

BOLD := \033[36m
NORM := \033[0m

run: default ## Run the current day solution using the real input
	@zig build run -Dday=$(DAY) -- $(INPUT_PATH)

test: default ## Run the current day solution using the test case
	@zig build run -Dday=$(DAY) -- $(TEST_PATH)

default: ## Bootstrap the challenge directory
	@mkdir -p "$(SUBPATH)"
	@cp -u src/template.zig "$(SUBPATH)/main.zig"
	@if [[ -n "$(AOC_SESSION_COOKIE)" ]] && [[ ! -f "$(SUBPATH)/input" ]]; then curl "$(URL)" \
		-H "Cookie: session=$(AOC_SESSION_COOKIE)" \
		-H "User-Agent: $(USER_AGENT)" > "$(SUBPATH)/input"; \
	fi

help: ## This help
	@printf 'Usage:\n'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "    $(BOLD)%-12s$(NORM) %s\n", $$1, $$2}'
	@printf '\n$(BOLD)Hint$(NORM): you can override the target day using the DAY environment variable.\n'
	@printf '$(BOLD)Hint$(NORM): you can download the input for the current day by setting the AOC_SESSION_COOKIE environment variable.\n'

.PHONY: default run test help
.DEFAULT_GOAL = help
