# ============
# APP DETAILS
# ============
USERNAME    = username
# Normally the domain of the site. Only use lowercase letters and dashes.
APP_NAME    = app-name
# Absolute root path of the app. IMPORTANT: Don't add a trailing slash!
APP_PATH    = /home/${USERNAME}/webapps/${APP_NAME}
# Specify where the wp-config.php file is located so that the script can run the WP CLI commands. Path is relative to the root app path. IMPORTANT: Must end with a trailing slash!
WP_CORE_PATH = web/wp/
# Directory that will be backed up and synced. IMPORTANT: Must end with a trailing slash!
CODE_DIR     = web/app/

# ===============
# BACKUP OPTIONS
# ===============
# ---
# Optional custom directory for all the app backups. Defaults to "/backups".
# Must be an absolute path (ex. /home/${USERNAME}/backups)
# IMPORTANT: Don't add a trailing slash!
# ---
# BACKUPS_DIRECTORY = 
# ---
# Name of the 'logs' directory
LOG_DIR         = logs
# Prefix for the database filename.
DB_PREFIX       = db
# Prefix for the codebase filename.
CODE_PREFIX     = code
# Set to true if you would like to delete old backups
CLEANUP_OLD_BACKUPS = false
# Number of days to look in the past to delete old local backups
# Defaults to:
# DELETE_DAILY   = 8
# DELETE_WEEKLY  = 31
# DELETE_MONTHLY = 91
# DELETE_YEARLY  = 366

# ==================
# S3 BUCKET OPTIONS
# ==================
# Defaults to true
# S3_SYNC = false
# IMPORTANT: Don't add a trailing slash!
S3_BUCKET_NAME = Bucket-Name
# IMPORTANT: Don't add a trailing slash!
S3_BUCKET_PATH = ${S3_BUCKET_NAME}/backups/${USERNAME}/${APP_NAME}
# Number of days to keep backups in bucket. Defaults to 7, 30, 90, 365 respectively
S3_KEEP_DAILY   = 7
S3_KEEP_WEEKLY  = 30
S3_KEEP_MONTHLY = 90
S3_KEEP_YEARLY  = 365