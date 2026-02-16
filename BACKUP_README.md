# Backup and Rollback System

## Overview
This ansible project includes automated backup and rollback functionality for Odoo databases and filestores using AWS S3.

## Structure

```
odoo-deploy/
├── backup.yml                    # Main backup playbook
├── rollback.yml                  # Main rollback playbook
├── deploy.yml                    # Main deployment playbook
└── tasks/
    ├── backup-db.yml             # Backup tasks (DB + filestore → S3)
    ├── restore-db.yml            # Restore tasks (S3 → DB + filestore)
    ├── db-check.yml              # Database config parsing (reused)
    ├── db-init.yml               # Database initialization
    ├── before-symlink.yml        # Pre-deployment tasks
    ├── after-update-code.yml     # Post-code-update tasks
    └── after-cleanup.yml         # Post-cleanup tasks
```

## Features

### Backup (`tasks/backup-db.yml`)
- ✅ Reuses existing `db-check.yml` for database config parsing
- ✅ Creates dual-format database dumps (`.dump` + `.sql`)
- ✅ Archives filestore from `data_dir`
- ✅ Uploads to S3: `s3://{bucket}/{customer}/backups/{db}_YYYY-MM-DD_HH-MM-SS.zip`
- ✅ Verifies S3 upload
- ✅ Automatic cleanup

### Restore (`tasks/restore-db.yml`)
- ✅ Finds latest backup from S3
- ✅ Downloads and extracts backup
- ✅ Stops Odoo service
- ✅ Drops and recreates database
- ✅ Restores filestore with correct permissions
- ✅ Starts Odoo service
- ✅ Dry-run mode support (`DRY_RUN=true`)

## Usage

### Backup Database
```bash
ansible-playbook -i hosts.yml odoo-deploy/backup.yml
```

### Rollback to Latest Backup
```bash
# Dry run first (recommended)
DRY_RUN=true ansible-playbook -i hosts.yml odoo-deploy/rollback.yml

# Actual rollback
ansible-playbook -i hosts.yml odoo-deploy/rollback.yml
```

### Deploy with Backup
```bash
ansible-playbook -i hosts.yml odoo-deploy/deploy.yml
```

## Requirements

### Ansible Collections
```bash
ansible-galaxy collection install amazon.aws
ansible-galaxy collection install community.general
```

### Environment Variables
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_REGION` - AWS region (default: `me-south-1`)
- `S3_BUCKET` - S3 bucket name (default: `sonodcustomersbackup`)
- `CI_PROJECT_NAME` - Customer identifier (used for S3 path)
- `DRY_RUN` - Set to `true` for dry-run mode (restore only)

### Host Variables (from `hosts.yml`)
Required variables per host:
- `dbname` - Database name
- `odoo_conf` - Path to odoo config file
- `odoo_service` - Systemd service name
- `deploy_user` - Deployment user
- `deploy_folder` - Deployment folder

## S3 Structure
```
s3://sonodcustomersbackup/
└── {customer-name}/
    └── backups/
        ├── {dbname}_2026-02-16_09-00-00.zip
        ├── {dbname}_2026-02-15_12-30-00.zip
        └── ...
```

Each backup contains:
- `{dbname}_{timestamp}.dump` - PostgreSQL custom format (for pg_restore)
- `{dbname}_{timestamp}.sql` - Plain SQL format (for viewing/editing)
- `filestore/` - Odoo filestore directory (if exists)

## CI/CD Integration

See [.gitlab-ci.yml](file:///../.gitlab-ci.yml) for integration examples:

```yaml
backup:prod:
  script:
    - ansible-playbook -i hosts.yml odoo-deploy/backup.yml

deploy:prod:
  needs: [backup:prod]
  script:
    - ansible-playbook -i hosts.yml odoo-deploy/deploy.yml

rollback:prod:
  script:
    - ansible-playbook -i hosts.yml odoo-deploy/rollback.yml
```

## How It Works

### Backup Flow
1. Parse `odoo_conf` to extract DB credentials and `data_dir`
2. Check database exists
3. Create `pg_dump` in both custom and SQL formats
4. Copy filestore (if exists)
5. Create zip archive
6. Upload to S3
7. Verify upload
8. Cleanup temporary files

### Restore Flow
1. List S3 backups and find latest
2. Download backup
3. Extract archive
4. Stop Odoo service
5. Drop existing database
6. Create new database
7. Restore from `.dump` file
8. Restore filestore
9. Start Odoo service
10. Cleanup temporary files

## Troubleshooting

### Backup fails with "Database does not exist"
- Check `dbname` in hosts.yml matches actual database name
- Verify database credentials in `odoo_conf`

### Restore fails with "No backup found"
- Check S3 bucket and customer name
- Verify AWS credentials have S3 read permissions

### Filestore not restored
- Check `data_dir` is correctly set in `odoo_conf`
- Verify filestore exists in backup zip

### Permission errors on filestore
- Task automatically sets `odoo:odoo` ownership
- Ensure `odoo` user exists on the system

## Best Practices

1. **Always dry-run first**: Test rollback with `DRY_RUN=true`
2. **Verify backups**: Check S3 after backup jobs
3. **Test on staging**: Run rollback on staging before production
4. **Monitor disk space**: Backups can be large, ensure sufficient space
5. **Retention policy**: Consider implementing S3 lifecycle rules for old backups
