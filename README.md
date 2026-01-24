# odoo-deploy
Ansible project for deploying Odoo

This playbook copies the release folder to server and deploys Odoo.

**Note**: This project has been updated to support Odoo 19.0's new CLI structure. For Odoo 19.0 CLI command reference, see `ODOO_19_CLI_NOTES.txt`.

To use the image, please add a **hosts.yml** file with this information:

```yaml
all:
  hosts:
    odoo-test.sonod.tech:
      dbname: sonod # Odoo DB name
      deploy_folder: /opt/odoo # Folder where to deploy odoo
      deploy_user: odoo # Sudoer user to connect to the server
      nginx_enabled_conf: odoo-test-sonod.conf # Symbolic link to Nginx configuration
      nginx_maintenance_conf: maintenance.conf # Nginx maintenance configuration
      nginx_odoo_conf: odoo.conf # Nginx Odoo configuration
      odoo_conf: /etc/odoo-ci.conf # Odoo configuration file
      odoo_service: odoo # Odoo service name
      python_version: "python3.8" # Python version
      release_folder: release # Folder where to find wheel files
```

Then run the ansible playbook:

```shell
ansible-playbook -i hosts.yml deploy.yml
```
