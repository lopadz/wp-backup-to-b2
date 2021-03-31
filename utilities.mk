# ===================
#   COLORS
# ===================
# Define standard colors
ifneq (,$(findstring xterm,${TERM}))
	RED          := $(shell tput -Txterm setaf 1)
	GREEN        := $(shell tput -Txterm setaf 2)
	YELLOW       := $(shell tput -Txterm setaf 3)
	LIGHTPURPLE  := $(shell tput -Txterm setaf 4)
	PURPLE       := $(shell tput -Txterm setaf 5)
	BLUE         := $(shell tput -Txterm setaf 6)
	RESET_COLOR  := $(shell tput -Txterm sgr0)
else
	RED          := ""
	GREEN        := ""
	YELLOW       := ""
	LIGHTPURPLE  := ""
	PURPLE       := ""
	BLUE         := ""
	RESET_COLOR  := ""
endif

# ===================
#   MISC
# ===================
SEPARATOR         = ===============================
CHECK             = ${GREEN}✔${RESET_COLOR}
CURRENT_DATE     ?= $(shell date +'%Y-%m-%d-%H%M%S')
BACKUP_TIMESTAMP := ${CURRENT_DATE}
BACKUP_DATE       = $(shell date +'%Y-%m-%d')