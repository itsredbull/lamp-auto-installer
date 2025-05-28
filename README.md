# LAMP Stack Auto-Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)

A robust, cross-platform bash script that automatically detects your Linux distribution and installs a complete LAMP (Linux, Apache, MySQL/MariaDB, PHP) stack with comprehensive error handling and logging.

## 🚀 Features

- **Cross-Platform Support**: Works on Ubuntu, Debian, CentOS, RHEL, Fedora, Rocky Linux, AlmaLinux
- **Intelligent OS Detection**: Automatically detects your Linux distribution and uses appropriate package managers
- **Comprehensive Error Handling**: Retry mechanism for failed installations with detailed logging
- **Security Configuration**: Automatically secures MySQL/MariaDB installation
- **Firewall Management**: Automatically opens necessary ports (80, 443)
- **Verification Testing**: Creates test files to verify PHP and database connectivity
- **Detailed Logging**: Complete installation log saved to `/LAMPinstallLOGS.text`
- **System Information Collection**: Gathers system specs and configuration details

## 📋 Prerequisites

- Linux-based operating system (Ubuntu, Debian, CentOS, RHEL, Fedora, Rocky, AlmaLinux)
- Root or sudo access
- Internet connection for package downloads

## 🔧 Installation

### Quick Install (One-liner)
```bash
# Download and run the script directly
curl -sSL https://raw.githubusercontent.com/itsredbull/lamp-auto-installer/main/install-lamp.sh | sudo bash
```

### Manual Installation
```bash
# Download the script
wget https://raw.githubusercontent.com/itsredbull/lamp-auto-installer/main/install-lamp.sh

# Make it executable
chmod +x install-lamp.sh

# Run the script as root
sudo ./install-lamp.sh
```

### Copy-Paste Method
1. Copy the script content from [`install-lamp.sh`](install-lamp.sh)
2. Save it to a file on your server (e.g., `install-lamp.sh`)
3. Make it executable: `chmod +x install-lamp.sh`
4. Run as root: `sudo ./install-lamp.sh`

## 📊 What Gets Installed

| Component | Description | Default Version |
|-----------|-------------|-----------------|
| **Apache** | Web server (apache2/httpd) | Latest available |
| **MySQL/MariaDB** | Database server | Latest available |
| **PHP** | Server-side scripting | Latest available |
| **PHP Modules** | Essential PHP extensions | mysql, cli, common, json, opcache, mbstring, xml, gd, curl |

## 🔍 Verification

After installation, the script creates test files to verify your LAMP stack:

- **PHP Info**: `http://your-server-ip/info.php`
- **Database Test**: `http://your-server-ip/db-test.php`

> ⚠️ **Security Note**: Remove these test files after verification for security reasons.

## 📝 Post-Installation Steps

1. **Change MySQL Root Password**:
   ```bash
   mysql -u root -p
   # Current password: temp_password
   ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_secure_password';
   ```

2. **Remove Test Files**:
   ```bash
   sudo rm /var/www/html/info.php /var/www/html/db-test.php
   ```

3. **Configure Virtual Hosts** (if needed)
4. **Set up SSL/TLS certificates**
5. **Configure backups**

## 📄 Log Files

The script generates comprehensive logs at `/LAMPinstallLOGS.text` including:
- Installation progress and errors
- System information
- Service status
- Network configuration
- Firewall settings

## 🛠️ Troubleshooting

### Common Issues

**Script fails with permission denied**
```bash
chmod +x install-lamp.sh
sudo ./install-lamp.sh
```

**Package installation fails**
- Check internet connection
- Verify repository configuration
- Review logs in `/LAMPinstallLOGS.text`

**Services not starting**
```bash
# Check service status
sudo systemctl status apache2  # or httpd
sudo systemctl status mysql    # or mariadb

# Check logs
sudo journalctl -u apache2 -f
sudo journalctl -u mysql -f
```

**Firewall blocking connections**
```bash
# For UFW (Ubuntu/Debian)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# For firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

## 🔧 Advanced Configuration

### Custom PHP Version
For specific PHP versions, modify the script or install manually:
```bash
# Ubuntu/Debian - PHP 8.1
sudo apt install php8.1 libapache2-mod-php8.1

# CentOS/RHEL - Enable specific module
sudo dnf module enable php:8.1
sudo dnf install php php-mysqlnd
```

### Multiple PHP Versions
The script installs the default PHP version. For multiple versions, use tools like `update-alternatives` or configure Apache virtual hosts.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Guidelines
- Follow bash best practices
- Add appropriate error handling
- Update documentation
- Test on multiple distributions

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Thanks to all contributors who have helped improve this script
- Inspired by the need for a universal LAMP installer across different Linux distributions

## 📞 Support

If you encounter any issues or have questions:

1. Check the [troubleshooting section](#troubleshooting)
2. Review the installation logs at `/LAMPinstallLOGS.text`
3. Open an issue on GitHub
4. Check existing issues for similar problems

## 📈 Compatibility Matrix

| OS | Version | Status | Notes |
|----|---------|--------|-------|
| Ubuntu | 18.04+ | ✅ | Fully supported |
| Debian | 9+ | ✅ | Fully supported |
| CentOS | 7+ | ✅ | Fully supported |
| RHEL | 7+ | ✅ | Fully supported |
| Fedora | 30+ | ✅ | Fully supported |
| Rocky Linux | 8+ | ✅ | Fully supported |
| AlmaLinux | 8+ | ✅ | Fully supported |

---

**Made with ❤️ for the Linux community**
