# Security Policy

## 🔒 Security Considerations

The LAMP Auto-Installer script requires root privileges and installs system-wide software. Please review these security considerations before use.

## 🚨 Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| Latest  | ✅ Yes            |
| < 1.0   | ❌ No             |

## 🛡️ Security Features

### Default Security Measures
- **Database Security**: Automatically runs mysql_secure_installation equivalent
- **Default Passwords**: Sets temporary password that MUST be changed
- **Service Hardening**: Enables secure defaults where possible
- **Firewall Configuration**: Configures basic firewall rules

### What the Script Does
- Installs packages from official repositories only
- Sets secure file permissions
- Removes test databases and anonymous users
- Configures services with secure defaults

## ⚠️ Security Warnings

### Immediate Actions Required
1. **Change Default Password**: The script sets MySQL root password to `temp_password` - change this immediately
2. **Remove Test Files**: Delete `info.php` and `db-test.php` after testing
3. **Review Firewall**: Adjust firewall rules according to your needs
4. **Update Regularly**: Keep all installed packages updated

### Default Credentials
```
MySQL/MariaDB root password: temp_password
```
**⚠️ CRITICAL: Change this password immediately after installation!**

## 🔐 Post-Installation Security

### Essential Security Steps
1. **Change MySQL Password**:
   ```bash
   mysql -u root -ptemp_password
   ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_secure_password_here';
   ```

2. **Remove Test Files**:
   ```bash
   sudo rm /var/www/html/info.php
   sudo rm /var/www/html/db-test.php
   ```

3. **Configure SSL/TLS**:
   ```bash
   # Install Let's Encrypt
   sudo apt install certbot python3-certbot-apache  # Ubuntu/Debian
   sudo dnf install certbot python3-certbot-apache  # CentOS/RHEL
   
   # Get certificate
   sudo certbot --apache -d your-domain.com
   ```

4. **Secure Apache Configuration**:
   ```bash
   # Hide Apache version
   echo "ServerTokens Prod" >> /etc/apache2/conf-available/security.conf
   echo "ServerSignature Off" >> /etc/apache2/conf-available/security.conf
   sudo a2enconf security
   sudo systemctl reload apache2
   ```

5. **Configure Firewall Properly**:
   ```bash
   # Only allow necessary ports
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow ssh
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

## 🚨 Reporting Security Vulnerabilities

If you discover a security vulnerability, please follow responsible disclosure:

### For Script Vulnerabilities
1. **DO NOT** open a public issue
2. Email: [your-security-email@domain.com]
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline
- **24 hours**: Initial response
- **72 hours**: Vulnerability assessment
- **7 days**: Security patch (if confirmed)
- **14 days**: Public disclosure (after fix)

## 🔍 Security Checklist

### Before Running the Script
- [ ] Download from official repository only
- [ ] Verify script integrity (if checksums provided)
- [ ] Review script content for any suspicious commands
- [ ] Ensure you're running on a test system first
- [ ] Have backup strategy in place

### After Running the Script
- [ ] Change default MySQL password immediately
- [ ] Remove test files (info.php, db-test.php)
- [ ] Review installed packages
- [ ] Configure firewall appropriately
- [ ] Set up SSL certificates
- [ ] Configure regular security updates
- [ ] Review log files for any issues

## 🛠️ Security Best Practices

### System Security
```bash
# Enable automatic security updates (Ubuntu/Debian)
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Regular updates (manual)
sudo apt update && sudo apt upgrade  # Ubuntu/Debian
sudo dnf update                      # CentOS/RHEL/Fedora
```

### Database Security
```bash
# Secure MySQL installation manually
sudo mysql_secure_installation

# Create limited user instead of using root
mysql -u root -p
CREATE USER 'webuser'@'localhost' IDENTIFIED BY 'secure_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON webdb.* TO 'webuser'@'localhost';
FLUSH PRIVILEGES;
```

### Web Server Security
```bash
# Disable directory browsing
echo "Options -Indexes" > /var/www/html/.htaccess

# Set proper file permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 644 /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
```

## 📋 Security Resources

- [OWASP Security Guidelines](https://owasp.org/)
- [Apache Security Documentation](https://httpd.apache.org/docs/2.4/misc/security_tips.html)
- [MySQL Security Guide](https://dev.mysql.com/doc/refman/8.0/en/security.html)
- [PHP Security Best Practices](https://www.php.net/manual/en/security.php)

## 🚫 What NOT to Do

- Don't run the script on production systems without testing
- Don't keep default passwords
- Don't leave test files in place
- Don't ignore security updates
- Don't run unnecessary services
- Don't use root MySQL user for applications

## 📞 Security Support

For security-related questions:
- Review this security guide first
- Check official documentation
- Contact through official channels only
- Be cautious of unofficial "security advice"

---

**Remember**: Security is an ongoing process, not a one-time setup. Regularly review and update your security measures.
