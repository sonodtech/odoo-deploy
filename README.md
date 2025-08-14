# odoo-deploy
Ansible project for deploying Odoo

This playbook copies the release folder to server and deploys Odoo.

To use the image, please add a **hosts.yml** file with this information:

```yaml
all:
  hosts:
    odoo-test.opsivist.io:
      dbname: opsivist # Odoo DB name
      deploy_folder: /opt/odoo # Folder where to deploy odoo
      deploy_user: odoo # Sudoer user to connect to the server
      nginx_enabled_conf: odoo-test-opsivist.conf # Symbolic link to Nginx configuration
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
