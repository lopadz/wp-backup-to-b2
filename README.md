# WP Backup to S3
> WordPress Backup & Sync to Blackblaze S3 Bucket Makefile Recipe

***This recipe is a proof-of-concept to automate backing up and uploading to a remote destination set up as a cronjob***. It will create a backup of your WP app, sync it to a Blackblaze S3 bucket, add a basic retention policy, and clean any old local backups.

## Requirements

1. Root access. You could do it with sudo access, but you won't be able to run this as a cron job.
2. LAMP/LEMP stack with Bash shell installed.
3. [WP CLI](https://wp-cli.org/): Used to export the DB and generate filenames among other actions.
4. [Blackblaze S3](https://www.backblaze.com/b2/docs/quick_command_line.html) key and bucket(s) set up & configured to sync your files.

## Usage

### 1. Clone Repo 
Put this in a folder like ```/root/cron/``` or ```home/user/webapps/``` if you just want to run it manually.
   ```sh
   $ git clone https://github.com/lopadz/wp-backup-to-s3
   ```
The script can be called from anywhere as long as you pass the correct path to where the Makefile is located. See below for instructions.

### 2. Configure App Settings
Duplicate ```apps/app-example.mk``` and configure the settings for the app you want to backup and sync.
- Rename the file to the name of your app to keep things organized.
- Pay attention to the paths and comments. The variables are pretty self explanatory, but see "App Settings & Options" below for more details.

### 3. Running The Recipe
To run the ```backup.mk``` recipe, it requires:
   - The **absolute path** *(if running as a cron job)* or **relative path** *(if running manually)* where the makefile is located.
   - The **```FREQ```** variable with a value of 'daily', 'weekly', 'monthly', or 'yearly'. If nothing is set or empty, it will default to daily.
   
Here's an example of a weekly backup run:
   ```sh
   $ make -f /root/cron/backup.mk FREQ=weekly
   ```

## File Structure
- ```backup.mk```: Main recipe to start the backup and sync process.
- ```apps/app-example.mk```: These are the settings *(per app)* the ```backup.mk``` recipe needs in order to create a backup and sync to a B2 S3 bucket.
- ```utilities.mk```: Defines colors and variables needed for naming files/directories.

## App Settings & Options
-  ```LOG_DIR``` = Name of the directory where the logs are saved.
-  ```DB_PREFIX``` & ```CODE_PREFIX ```= Prefix added to the filename to the database and codebase respectively.
-  ```CLEANUP_OLD_BACKUPS``` = If set to true, the script will find the backups created between now and:
   -  7 days in the past for backups with a value of ```FREQ=daily```
   -  31 days in the past for backups with a value of ```FREQ=weekly```
   -  91 days in the past for backups with a value of ```FREQ=monthly```
   -  366 days in the past for backups with a value of ```FREQ=yearly```

	Once found, it will delete them *before* syncing to the S3 bucket and have a simple retention policy. You can customize these values if needed.

- ```S3_SYNC``` = If set to false, this won't sync the backups to the S3 bucket. It defaults to ```true```.s
- ```S3_KEEP...``` = These are the days that are passed in the --keepDays flag when syncing to the B2 S3 bucket.

## Optional Recommendations
Paths in the ```apps/app-example.mk``` file resemble an app running on:
- [Bedrock](https://roots.io/bedrock/) by Roots
- [RunCloud.io](https://runcloud.io/) server control management

If you are not running these, simply update the path structure to match your host and app paths.

