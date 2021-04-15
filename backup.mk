# Specify the shell
SHELL := bash

# Get path of current Makefile
MAKEFILE_PATH :=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# Get name of this Makefile
MAKEFILE := $(lastword $(MAKEFILE_LIST))

# Include utilities like colors & dates
include ${MAKEFILE_PATH}/utilities.mk

# Include App details
include ${MAKEFILE_PATH}/${APP}.mk
# endif

# Frequency of the backups
FREQUENCY = $(shell \
	if [ -z ${FREQ} ]; then \
		echo "daily"; \
	elif [ ${FREQ} = weekly ]; then \
		echo "weekly"; \
	elif [ ${FREQ} = monthly ]; then \
		echo "monthly"; \
	elif [ ${FREQ} = yearly ]; then \
		echo "yearly"; \
	else \
		echo "daily"; \
	fi)

# Backup options
BACKUPS_DIR = $(shell \
	if [ ! -z ${BACKUPS_DIRECTORY} ]; then \
		echo "${BACKUPS_DIRECTORY}"; \
	elif [ ${BACKUPS_DIRECTORY} ]; then \
		echo "/backups"; \
	else \
		echo "/backups"; \
	fi)
CUSTOM_BACKUPS_DIR= $(shell \
	if [ -z ${BACKUPS_DIRECTORY} ]; then \
		echo "false"; \
	elif [ ! ${BACKUPS_DIRECTORY} ]; then \
		echo "false"; \
	else \
		echo "true"; \
	fi)

BACKUP_USER_DIR = $(shell if [ ${CUSTOM_BACKUPS_DIR} = true ]; then echo "${BACKUPS_DIR}"; else echo "${BACKUPS_DIR}/${USERNAME}"; fi)
BACKUP_APP_DIR  = ${BACKUP_USER_DIR}/${APP_NAME}
BACKUP_FREQ_DIR = ${BACKUP_APP_DIR}/${FREQUENCY}
BACKUP_DIR      = ${BACKUP_FREQ_DIR}/${BACKUP_DATE}

# DB options
DB_NAME         = $(shell sudo -u ${USERNAME} -i -- wp --path="${APP_PATH}/${WP_CORE_PATH}" config get DB_NAME)
DATABASE_BACKUP = ${BACKUP_DIR}/${DB_PREFIX}-${DB_NAME}-${BACKUP_TIMESTAMP}.sql

# Codebase options
CODE_PATH       = ${APP_PATH}/${CODE_DIR}
CODEBASE_BACKUP = ${BACKUP_DIR}/${CODE_PREFIX}-${APP_NAME}-${BACKUP_TIMESTAMP}.tar.gz

# Log options
LOG_PATH  = ${MAKEFILE_PATH}/${LOG_DIR}
LOG_FILE ?= ${LOG_PATH}/backup-${USERNAME}-${APP_NAME}-${BACKUP_TIMESTAMP}.log

# Sync to B2 options
B2_ENABLE = $(shell \
	if [ -z ${B2_SYNC} ]; then \
		echo "true"; \
	elif [ ${B2_SYNC} = false ]; then \
		echo "false"; \
	else \
		echo "true"; \
	fi)
B2_KEEP_DAYS = $(shell \
	if [ ${FREQUENCY} = daily ]; then \
		if [ ! -z ${B2_KEEP_DAILY} ]; then echo ${B2_KEEP_DAILY}; else echo "7"; fi\
	elif [ ${FREQUENCY} = weekly ]; then \
		if [ ! -z ${B2_KEEP_WEEKLY} ]; then echo ${B2_KEEP_WEEKLY}; else echo "30"; fi\
	elif [ ${FREQUENCY} = monthly ]; then \
		if [ ! -z ${B2_KEEP_MONTHLY} ]; then echo ${B2_KEEP_MONTHLY}; else echo "90"; fi\
	elif [ ${FREQUENCY} = yearly ]; then \
		if [ ! -z ${B2_KEEP_YEARLY} ]; then echo ${B2_KEEP_YEARLY}; else echo "365"; fi\
	else \
		echo "7"; \
	fi)

SYNC_FROM = ${BACKUP_FREQ_DIR}/
SYNC_TO   = b2://${B2_BUCKET_PATH}/${FREQUENCY}/

# Local backup retention
BACKUP_CLEANUP_ENABLE = $(shell \
	if [ -z ${CLEANUP_OLD_BACKUPS} ]; then \
		echo "false"; \
	elif [ ${CLEANUP_OLD_BACKUPS} = true ]; then \
		echo "true"; \
	else \
		echo "false"; \
	fi)
KEEP_LOCAL_BACKUPS_FOR = $(shell \
	if [ ${FREQUENCY} = daily ]; then \
		if [ ! -z ${DELETE_DAILY} ]; then echo $(shell ((${DELETE_DAILY} + 1))); else echo "8"; fi\
	elif [ ${FREQUENCY} = weekly ]; then \
		if [ ! -z ${DELETE_WEEKLY} ]; then echo $(shell ((${DELETE_WEEKLY} + 1))); else echo "31"; fi\
	elif [ ${FREQUENCY} = monthly ]; then \
		if [ ! -z ${DELETE_MONTHLY} ]; then echo $(shell ((${DELETE_MONTHLY} + 1))); else echo "91"; fi\
	elif [ ${FREQUENCY} = yearly ]; then \
		if [ ! -z ${DELETE_YEARLY} ]; then echo $(shell ((${DELETE_YEARLY} + 1))); else echo "366"; fi\
	else \
		echo "8"; \
	fi)

#---------------------------------------------
# Order of the sync steps
#---------------------------------------------
.PHONY: execute
execute: setup database codebase secure b2_sync cleanup

setup:
	@echo "${LIGHTPURPLE}Starting Backup Setup ...${RESET_COLOR}"
	@if [ ! -d ${LOG_PATH} ]; then mkdir -p ${LOG_PATH}; fi
	@if [ ! -d ${BACKUP_DIR} ]; then mkdir -p ${BACKUP_DIR}; fi
	@if [ ${CUSTOM_BACKUPS_DIR} = false ]; then \
		if [ -d ${BACKUP_USER_DIR} ]; then chown -R ${USERNAME}:${USERNAME} "${BACKUP_USER_DIR}/"; fi \
	elif [ ${CUSTOM_BACKUPS_DIR} = true ]; then \
		if [ -d ${BACKUP_APP_DIR} ]; then chown -R ${USERNAME}:${USERNAME} "${BACKUP_APP_DIR}/"; fi \
	fi
	@echo "${GREEN}Completed ${CHECK}${RESET_COLOR}"

database:
	@echo "${LIGHTPURPLE}Preparing Database ...${RESET_COLOR}"
	@echo "${SEPARATOR}" >> ${LOG_FILE}
	@echo "Repairing Database" >> ${LOG_FILE}
	@echo "${SEPARATOR}" >> ${LOG_FILE}
	@sudo -u ${USERNAME} -i -- wp --path="${APP_PATH}/${WP_CORE_PATH}" db repair >> ${LOG_FILE}
	@echo "${SEPARATOR}" >> ${LOG_FILE}
	@echo "Optimizing Database" >> ${LOG_FILE}
	@echo "${SEPARATOR}" >> ${LOG_FILE}
	@sudo -u ${USERNAME} -i -- wp --path="${APP_PATH}/${WP_CORE_PATH}" db optimize >> ${LOG_FILE}
	@echo "${SEPARATOR}" >> ${LOG_FILE}
	@echo "Exporting Database" >> ${LOG_FILE}
	@echo "${SEPARATOR}" >> ${LOG_FILE}
	@sudo -u ${USERNAME} -i -- wp --path="${APP_PATH}/${WP_CORE_PATH}" db export "${DATABASE_BACKUP}" >> ${LOG_FILE}
	@echo "${SEPARATOR}" >> ${LOG_FILE}
	@echo "Compressing Database" >> ${LOG_FILE}
	@echo "${SEPARATOR}" >> ${LOG_FILE}
	@gzip ${DATABASE_BACKUP} >> ${LOG_FILE}
	@echo "Success: Database compressed using Gzip." >> ${LOG_FILE}
	@echo "${GREEN}Completed ${CHECK}${RESET_COLOR}"

codebase:
	@echo "${LIGHTPURPLE}Preparing Codebase ...${RESET_COLOR}"
	@echo "${SEPARATOR}" >> ${LOG_FILE}
	@echo "Compressing Codebase" >> ${LOG_FILE}
	@echo "${SEPARATOR}" >> ${LOG_FILE}
	@tar -cvz --absolute-names --file=${CODEBASE_BACKUP} ${CODE_PATH} >> ${LOG_FILE}
	@echo "Success: Codebase compressed using TAR." >> ${LOG_FILE}
	@echo "${GREEN}Completed ${CHECK}${RESET_COLOR}"

secure:
	@echo "${LIGHTPURPLE}Securing Backup ...${RESET_COLOR}"
	@if [ ${CUSTOM_BACKUPS_DIR} = false ]; then \
		chown -R root:root "${BACKUP_USER_DIR}/"; \
	elif [ ${CUSTOM_BACKUPS_DIR} = true ]; then \
		chown -R root:root "${BACKUP_APP_DIR}/"; \
	fi
	@echo "${GREEN}Completed ${CHECK}${RESET_COLOR}"

b2_sync:
	@if [ ${B2_ENABLE} = true ]; then \
		echo "${LIGHTPURPLE}Syncing to B2 bucket ...${RESET_COLOR}"; \
		echo "${SEPARATOR}" >> ${LOG_FILE}; \
		echo "Syncing to B2 bucket" >> ${LOG_FILE}; \
		echo "${SEPARATOR}" >> ${LOG_FILE}; \
		echo "FROM: ${SYNC_FROM}" >> ${LOG_FILE}; \
		echo "TO: ${SYNC_TO}" >> ${LOG_FILE}; \
		b2 sync --keepDays ${B2_KEEP_DAYS} --replaceNewer ${SYNC_FROM} ${SYNC_TO} >> ${LOG_FILE}; \
		echo "${GREEN}Completed ${CHECK}${RESET_COLOR}"; \
	else \
		echo "Syncing to B2 bucket skipped!" >> ${LOG_FILE}; \
		echo "${YELLOW}Syncing to B2 bucket skipped!${RESET_COLOR}"; \
	fi
	@echo "${GREEN}BACKUP COMPLETE!${RESET_COLOR}"

cleanup:
	@if [ ${BACKUP_CLEANUP_ENABLE} = true ]; then \
		echo "${LIGHTPURPLE}Cleaning old backups ...${RESET_COLOR}"; \
		echo "${SEPARATOR}" >> ${LOG_FILE}; \
		echo "Cleaning old backups" >> ${LOG_FILE}; \
		echo "${SEPARATOR}" >> ${LOG_FILE}; \
		find ${BACKUP_FREQ_DIR} \
			-type d -newerct "$(date -d -${KEEP_LOCAL_BACKUPS_FOR}days)" -not -newerct "$(date)" \
			-not -name ${BACKUP_DATE} \
			-not -wholename ${BACKUP_FREQ_DIR} \
			-exec rm -rf {} + >> ${LOG_FILE}; \
		echo "${GREEN}OLD BACKUPS CLEANED!${RESET_COLOR}"; \
	else \
		echo "${YELLOW}Old backups were not cleaned!${RESET_COLOR}"; \
	fi

test:
	@echo "Backup Cleanup Enable: ${BACKUP_CLEANUP_ENABLE}"
