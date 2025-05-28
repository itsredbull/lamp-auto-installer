#!/bin/bash

# Improved LAMP Stack Installation Script
# This script detects the OS and installs the latest LAMP stack
# with verification at each step
# Logs are saved to /LAMPinstallLOGS.text

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo or log in as root."
    exit 1
fi

# Initialize log file
LOG_FILE="/LAMPinstallLOGS.text"
echo "LAMP Stack Installation Log - $(date)" > $LOG_FILE
echo "----------------------------------------" >> $LOG_FILE

# Function to log messages
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a $LOG_FILE
}

# Function to check if command was successful
check_status() {
    if [ $? -eq 0 ]; then
        log "SUCCESS: $1"
        return 0
    else
        log "ERROR: $1 failed"
        return 1
    fi
}

# Function to retry a command
retry_command() {
    local cmd="$1"
    local description="$2"
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "Attempt $attempt of $max_attempts: $description"
        eval $cmd
        if check_status "$description"; then
            return 0
        fi
        
        log "Retrying in 5 seconds..."
        sleep 5
        ((attempt++))
    done
    
    log "Failed after $max_attempts attempts: $description"
    log "Installation aborted. Please check the error messages above."
    exit 1
}

# Detect OS
log "Detecting operating system..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
    log "Detected OS: $OS $VERSION"
else
    # Fallback detection methods
    if [ -f /etc/redhat-release ]; then
        OS=$(cat /etc/redhat-release | awk '{print tolower($1)}')
        log "Detected OS via redhat-release: $OS"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
        log "Detected OS via debian_version: $OS"
    else
        log "Could not detect OS. Attempting to use common package managers..."
        if command -v apt &> /dev/null; then
            OS="debian-like"
        elif command -v dnf &> /dev/null; then
            OS="redhat-like"
        elif command -v yum &> /dev/null; then
            OS="redhat-like"
        else
            log "Could not determine package manager. Exiting."
            exit 1
        fi
        log "Detected OS type based on package manager: $OS"
    fi
fi

# Ensure package manager works
log "Verifying package manager..."
case $OS in
    ubuntu|debian|debian-like)
        retry_command "apt update" "Repository update"
        ;;
    centos|rhel|fedora|rocky|almalinux|redhat-like)
        if command -v dnf &> /dev/null; then
            retry_command "dnf check-update || true" "Repository check"
        else
            retry_command "yum check-update || true" "Repository check"
        fi
        ;;
    *)
        log "Unsupported OS: $OS. Attempting to continue with best guess..."
        if command -v apt &> /dev/null; then
            OS="debian-like"
            retry_command "apt update" "Repository update"
        elif command -v dnf &> /dev/null; then
            OS="redhat-like"
            retry_command "dnf check-update || true" "Repository check"
        elif command -v yum &> /dev/null; then
            OS="redhat-like"
            retry_command "yum check-update || true" "Repository check"
        else
            log "No supported package manager found. Exiting."
            exit 1
        fi
        ;;
esac

# Update system
log "Updating system packages..."
case $OS in
    ubuntu|debian|debian-like)
        retry_command "DEBIAN_FRONTEND=noninteractive apt upgrade -y" "System upgrade"
        ;;
    centos|rhel|fedora|rocky|almalinux|redhat-like)
        if command -v dnf &> /dev/null; then
            retry_command "dnf upgrade -y" "System upgrade"
        else
            retry_command "yum upgrade -y" "System upgrade"
        fi
        ;;
esac

# Install Apache
log "Installing Apache web server..."
case $OS in
    ubuntu|debian|debian-like)
        retry_command "DEBIAN_FRONTEND=noninteractive apt install -y apache2" "Apache installation"
        systemctl enable apache2
        systemctl start apache2
        apache_service="apache2"
        ;;
    centos|rhel|fedora|rocky|almalinux|redhat-like)
        if command -v dnf &> /dev/null; then
            retry_command "dnf install -y httpd" "Apache installation"
        else
            retry_command "yum install -y httpd" "Apache installation"
        fi
        systemctl enable httpd
        systemctl start httpd
        apache_service="httpd"
        ;;
esac

# Verify Apache installation
if systemctl is-active --quiet $apache_service; then
    log "Apache is running successfully"
    if [ "$apache_service" = "apache2" ]; then
        apache_version=$(apache2 -v | head -n 1)
    else
        apache_version=$(httpd -v | head -n 1)
    fi
    log "Apache version: $apache_version"
else
    log "WARNING: Apache service is not running. Attempting to start..."
    systemctl start $apache_service
    sleep 2
    if systemctl is-active --quiet $apache_service; then
        log "Apache started successfully after retry"
    else
        log "ERROR: Apache service failed to start. Please check the logs."
    fi
fi

# Install MySQL/MariaDB
log "Installing MySQL/MariaDB database server..."
case $OS in
    ubuntu|debian|debian-like)
        # Check if MySQL/MariaDB is already installed
        if dpkg -l | grep -q mysql-server || dpkg -l | grep -q mariadb-server; then
            log "MySQL/MariaDB is already installed, skipping installation"
        else
            # Non-interactive installation
            export DEBIAN_FRONTEND=noninteractive
            # Set a default password for MySQL
            echo "mysql-server mysql-server/root_password password temp_password" | debconf-set-selections
            echo "mysql-server mysql-server/root_password_again password temp_password" | debconf-set-selections
            
            # Try to install MySQL first
            apt install -y mysql-server
            if ! check_status "MySQL installation"; then
                log "MySQL installation failed, trying MariaDB instead..."
                apt install -y mariadb-server
                if ! check_status "MariaDB installation"; then
                    log "Both MySQL and MariaDB installation failed. Exiting."
                    exit 1
                else
                    db_service="mariadb"
                fi
            else
                db_service="mysql"
            fi
        fi
        
        # Determine which service is installed
        if systemctl list-unit-files | grep -q mysql.service; then
            db_service="mysql"
        elif systemctl list-unit-files | grep -q mariadb.service; then
            db_service="mariadb"
        fi
        
        systemctl enable $db_service
        systemctl start $db_service
        ;;
        
    centos|rhel|fedora|rocky|almalinux|redhat-like)
        # Check if MySQL/MariaDB is already installed
        if rpm -qa | grep -q mysql-server || rpm -qa | grep -q mariadb-server; then
            log "MySQL/MariaDB is already installed, skipping installation"
        else
            if command -v dnf &> /dev/null; then
                # Try to install MariaDB first (more common on recent RHEL-based systems)
                dnf install -y mariadb-server
                if ! check_status "MariaDB installation"; then
                    log "MariaDB installation failed, trying MySQL instead..."
                    dnf install -y mysql-server
                    if ! check_status "MySQL installation"; then
                        log "Both MariaDB and MySQL installation failed. Exiting."
                        exit 1
                    else
                        db_service="mysqld"
                    fi
                else
                    db_service="mariadb"
                fi
            else
                # For older systems using yum
                yum install -y mariadb-server
                if ! check_status "MariaDB installation"; then
                    log "MariaDB installation failed, trying MySQL instead..."
                    yum install -y mysql-server
                    if ! check_status "MySQL installation"; then
                        log "Both MariaDB and MySQL installation failed. Exiting."
                        exit 1
                    else
                        db_service="mysqld"
                    fi
                else
                    db_service="mariadb"
                fi
            fi
        fi
        
        # Determine which service is installed if not set above
        if [ -z "$db_service" ]; then
            if systemctl list-unit-files | grep -q mysqld.service; then
                db_service="mysqld"
            elif systemctl list-unit-files | grep -q mariadb.service; then
                db_service="mariadb"
            fi
        fi
        
        systemctl enable $db_service
        systemctl start $db_service
        ;;
esac

# Verify MySQL/MariaDB installation
if systemctl is-active --quiet $db_service; then
    log "$db_service is running successfully"
    
    # Get MySQL/MariaDB version
    if command -v mysql &> /dev/null; then
        db_version=$(mysql --version)
    elif command -v mariadb &> /dev/null; then
        db_version=$(mariadb --version)
    else
        db_version="Version information not available"
    fi
    log "Database version: $db_version"
    
    # Try to secure the installation
    log "Securing database installation..."
    if [ "$db_service" = "mysql" ] || [ "$db_service" = "mysqld" ]; then
        # For MySQL
        mysql -u root <<EOF || mysql -u root -ptemp_password <<EOF2
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'temp_password';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'temp_password';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF2
    else
        # For MariaDB
        mysql -u root <<EOF || mysql -u root -ptemp_password <<EOF2
UPDATE mysql.user SET Password=PASSWORD('temp_password') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('temp_password');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF2
    fi
    
    if [ $? -eq 0 ]; then
        log "Database secured successfully"
    else
        log "WARNING: Failed to secure database. You should manually secure it after installation."
    fi
else
    log "WARNING: Database service is not running. Attempting to start..."
    systemctl start $db_service
    sleep 2
    if systemctl is-active --quiet $db_service; then
        log "Database service started successfully after retry"
    else
        log "ERROR: Database service failed to start. Please check the logs."
    fi
fi

# Install PHP
log "Installing PHP and required modules..."
case $OS in
    ubuntu|debian|debian-like)
        # Try different PHP versions starting with latest, then fallback
        retry_command "DEBIAN_FRONTEND=noninteractive apt install -y php libapache2-mod-php php-mysql php-cli php-common php-json php-opcache php-readline php-mbstring php-xml php-gd php-curl" "PHP installation"
        
        # Verify PHP installation
        if command -v php &> /dev/null; then
            php_version=$(php -v | head -n 1)
            log "PHP version: $php_version"
        else
            log "ERROR: PHP command not found after installation. Trying alternative PHP packages..."
            retry_command "DEBIAN_FRONTEND=noninteractive apt install -y php7.4 libapache2-mod-php7.4 php7.4-mysql php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-readline php7.4-mbstring php7.4-xml php7.4-gd php7.4-curl" "PHP 7.4 installation"
            
            if command -v php &> /dev/null; then
                php_version=$(php -v | head -n 1)
                log "PHP version: $php_version"
            else
                log "ERROR: PHP installation failed after multiple attempts. Exiting."
                exit 1
            fi
        fi
        ;;
        
    centos|rhel|fedora|rocky|almalinux|redhat-like)
        if command -v dnf &> /dev/null; then
            # Enable repos if needed
            if [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
                if [ -f /etc/redhat-release ]; then
                    version=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' | cut -d '.' -f1)
                    if [ "$version" = "8" ]; then
                        log "Enabling PHP modules for RHEL/CentOS 8..."
                        dnf module reset php -y
                        dnf module enable php:7.4 -y
                    elif [ "$version" = "9" ]; then
                        log "Enabling PHP modules for RHEL/CentOS 9..."
                        dnf module reset php -y
                        dnf module enable php:8.0 -y
                    fi
                fi
            fi
            
            retry_command "dnf install -y php php-mysqlnd php-cli php-common php-json php-opcache php-mbstring php-xml php-gd php-curl" "PHP installation"
        else
            # For older systems using yum
            retry_command "yum install -y php php-mysqlnd php-cli php-common php-json php-opcache php-mbstring php-xml php-gd php-curl" "PHP installation"
        fi
        
        # Verify PHP installation
        if command -v php &> /dev/null; then
            php_version=$(php -v | head -n 1)
            log "PHP version: $php_version"
        else
            log "ERROR: PHP command not found after installation. Trying alternative PHP packages..."
            
            if command -v dnf &> /dev/null; then
                # Try specific PHP version
                retry_command "dnf install -y php7.4 php7.4-mysqlnd php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-mbstring php7.4-xml php7.4-gd php7.4-curl" "PHP 7.4 installation"
            else
                retry_command "yum install -y php php-mysql php-cli php-common php-mbstring php-xml php-gd php-curl" "Alternative PHP installation"
            fi
            
            if command -v php &> /dev/null; then
                php_version=$(php -v | head -n 1)
                log "PHP version: $php_version"
            else
                log "ERROR: PHP installation failed after multiple attempts. Exiting."
                exit 1
            fi
        fi
        ;;
esac

# Create a phpinfo file to test PHP installation
log "Creating a test PHP file..."
echo "<?php phpinfo(); ?>" > /var/www/html/info.php
check_status "PHP info file creation"

# Restart Apache to apply PHP configuration
log "Restarting Apache web server..."
systemctl restart $apache_service
if check_status "Apache restart"; then
    log "Apache successfully restarted with PHP support"
else
    log "WARNING: Apache failed to restart. Trying again in 5 seconds..."
    sleep 5
    systemctl restart $apache_service
    if check_status "Apache restart retry"; then
        log "Apache successfully restarted on second attempt"
    else
        log "ERROR: Apache failed to restart multiple times. Please check configuration."
    fi
fi

# Get server IP address
SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n1)
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP="<server-ip>"
        log "WARNING: Could not determine server IP address"
    fi
fi

# Test PHP with MySQL/MariaDB connection
log "Testing PHP with database connection..."
cat > /var/www/html/db-test.php <<EOF
<?php
// Database connection test
\$host = 'localhost';
\$user = 'root';
\$pass = 'temp_password';

echo "<h1>PHP Database Connection Test</h1>";

// Test MySQL/MariaDB connection
try {
    \$conn = new PDO("mysql:host=\$host", \$user, \$pass);
    \$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "<p style='color:green'>Database connection successful!</p>";
    echo "<p>PHP version: " . phpversion() . "</p>";
    echo "<p>PDO driver version: " . \$conn->getAttribute(PDO::ATTR_SERVER_VERSION) . "</p>";
} catch(PDOException \$e) {
    echo "<p style='color:red'>Database connection failed: " . \$e->getMessage() . "</p>";
}
?>
EOF
check_status "PHP database test file creation"

# Verify the installation by checking service status
echo -e "\n\nVerifying Installation:" >> $LOG_FILE
echo "----------------------------------------" >> $LOG_FILE

# Check Apache
echo "Apache status:" >> $LOG_FILE
systemctl status $apache_service --no-pager | head -n 10 >> $LOG_FILE

# Check MySQL/MariaDB
echo -e "\nDatabase status:" >> $LOG_FILE
systemctl status $db_service --no-pager | head -n 10 >> $LOG_FILE

# Check PHP
echo -e "\nPHP installation:" >> $LOG_FILE
php -v >> $LOG_FILE

# Check PHP modules
echo -e "\nPHP modules:" >> $LOG_FILE
php -m >> $LOG_FILE

# Collect system information
log "Collecting system information..."
echo -e "\n\nSystem Information:" >> $LOG_FILE
echo "----------------------------------------" >> $LOG_FILE
echo "Hostname: $(hostname)" >> $LOG_FILE
echo "IP Address: $SERVER_IP" >> $LOG_FILE
echo "Kernel: $(uname -r)" >> $LOG_FILE
echo "OS Details:" >> $LOG_FILE
cat /etc/*-release >> $LOG_FILE
echo -e "\nCPU:" >> $LOG_FILE
grep 'model name' /proc/cpuinfo | head -1 >> $LOG_FILE
echo "Memory:" >> $LOG_FILE
free -h >> $LOG_FILE
echo -e "\nDisk Space:" >> $LOG_FILE
df -h / >> $LOG_FILE

# Collect ports information
echo -e "\n\nActive Ports:" >> $LOG_FILE
echo "----------------------------------------" >> $LOG_FILE
if command -v ss &> /dev/null; then
    ss -tuln >> $LOG_FILE
elif command -v netstat &> /dev/null; then
    netstat -tuln >> $LOG_FILE
fi

# Collect firewall status
echo -e "\n\nFirewall Status:" >> $LOG_FILE
echo "----------------------------------------" >> $LOG_FILE
if command -v ufw &> /dev/null; then
    ufw status >> $LOG_FILE
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --list-all >> $LOG_FILE
fi

# Check if ports 80 and 443 are open in firewall
log "Checking if web ports are open in firewall..."
PORT_80_OPEN=false
PORT_443_OPEN=false

if command -v ufw &> /dev/null; then
    if ufw status | grep -q "80.*ALLOW"; then
        PORT_80_OPEN=true
    fi
    if ufw status | grep -q "443.*ALLOW"; then
        PORT_443_OPEN=true
    fi
elif command -v firewall-cmd &> /dev/null; then
    if firewall-cmd --list-all | grep -q "services:.*http"; then
        PORT_80_OPEN=true
    fi
    if firewall-cmd --list-all | grep -q "services:.*https"; then
        PORT_443_OPEN=true
    fi
fi

if [ "$PORT_80_OPEN" = false ]; then
    log "WARNING: Port 80 (HTTP) appears to be closed in the firewall"
    echo -e "\nWARNING: Port 80 (HTTP) appears to be closed in the firewall" >> $LOG_FILE
    
    # Try to open port 80
    if command -v ufw &> /dev/null; then
        log "Attempting to open port 80 in UFW firewall..."
        ufw allow 80/tcp
        check_status "Opening port 80 in firewall"
    elif command -v firewall-cmd &> /dev/null; then
        log "Attempting to open port 80 in firewalld..."
        firewall-cmd --permanent --add-service=http
        firewall-cmd --reload
        check_status "Opening port 80 in firewall"
    fi
fi

if [ "$PORT_443_OPEN" = false ]; then
    log "WARNING: Port 443 (HTTPS) appears to be closed in the firewall"
    echo -e "\nWARNING: Port 443 (HTTPS) appears to be closed in the firewall" >> $LOG_FILE
    
    # Try to open port 443
    if command -v ufw &> /dev/null; then
        log "Attempting to open port 443 in UFW firewall..."
        ufw allow 443/tcp
        check_status "Opening port 443 in firewall"
    elif command -v firewall-cmd &> /dev/null; then
        log "Attempting to open port 443 in firewalld..."
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
        check_status "Opening port 443 in firewall"
    fi
fi

# Summary
log "LAMP stack installation completed successfully!"
log "Apache, MySQL/MariaDB, and PHP have been installed and configured."
log "You can verify PHP is working by visiting http://$SERVER_IP/info.php"
log "You can test database connection by visiting http://$SERVER_IP/db-test.php"
log "MySQL/MariaDB root password has been set to 'temp_password'. Please change it immediately!"
log "Installation log saved to $LOG_FILE"

echo -e "\n\nIMPORTANT NEXT STEPS:" >> $LOG_FILE
echo "----------------------------------------" >> $LOG_FILE
echo "1. Change the MySQL/MariaDB root password immediately" >> $LOG_FILE
echo "2. Remove the info.php and db-test.php files after testing:" >> $LOG_FILE
echo "   rm /var/www/html/info.php /var/www/html/db-test.php" >> $LOG_FILE
echo "3. Configure your firewall to allow necessary traffic" >> $LOG_FILE
echo "4. Configure virtual hosts as needed" >> $LOG_FILE
echo "5. Consider installing additional tools like phpMyAdmin" >> $LOG_FILE
echo "6. Set up regular backups for your database" >> $LOG_FILE
echo "7. Implement SSL/TLS for secure connections" >> $LOG_FILE

log "Installation completed at $(date)"

# Final verification - Print versions to console
echo ""
echo "============================================="
echo "         LAMP STACK INSTALLATION COMPLETE    "
echo "============================================="
echo ""
echo "Apache: $(if command -v apache2 &>/dev/null; then apache2 -v | head -n1; elif command -v httpd &>/dev/null; then httpd -v | head -n1; else echo "Not verified"; fi)"
echo "Database: $(if command -v mysql &>/dev/null; then mysql --version; elif command -v mariadb &>/dev/null; then mariadb --version; else echo "Not verified"; fi)"
echo "PHP: $(if command -v php &>/dev/null; then php -v | head -n1; else echo "Not verified"; fi)"
echo ""
echo "Test your PHP installation: http://$SERVER_IP/info.php"
echo "Test database connection: http://$SERVER_IP/db-test.php"
echo ""
echo "Installation logs saved to: $LOG_FILE"
echo ""
