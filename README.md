# Nekiro TFS-1.5-Downgrades Installer

This repository provides a **full automated installer** for The Forgotten Server (TFS) 1.5 downgrades, compatible with versions 7.72, 8.0, and 8.60. The installer is designed for **Ubuntu Linux** and sets up the server, MySQL database, PHPMyAdmin, and systemd service automatically.

---

## Features

- Automatic installation of all required dependencies (MySQL, PHP, Apache, libraries, etc.)
- Swap creation if needed
- Clone and update TFS-1.5-Downgrades repository
- Generate MySQL database and random credentials
- Import database schema
- Auto-generate `config.lua` with proper IP and rates
- Build TFS server using `cmake` and `make`
- Create a test account and player
- Setup systemd service for easy start/stop/restart
- Optional PHPMyAdmin access

---

## Supported TFS Versions

- **7.72**
- **8.0**
- **8.60**

You can select the version during installation.

---

## Requirements

- Ubuntu 20.04 or 22.04
- At least 1GB RAM (installer will create a 4GB swap if needed)
- Root privileges (`sudo`)


## Installation

**1.Clone the repository:**

```bash
git clone https://github.com/Maciu00/nekiro-TFS-1.5-Downgrades-installation-script.git && cd forgottenserver-install-linux && chmod +x install.sh && ./install.sh

```

 OR

```
wget -O install.sh https://raw.githubusercontent.com/Maciu00/nekiro-TFS-1.5-Downgrades-installation-script/1.0/install.sh && chmod +x install.sh && ./install.sh
```



**2.Start the server:**

``` cd TFS-1.5-Downgrades  && ./tfs```


---

## Author

Maciu00 – Original Installer Author

Adapted for Nekiro TFS-1.5-Downgrades
