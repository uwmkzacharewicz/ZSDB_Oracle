import os
import json

# Ścieżki
BASE_DIR = os.path.dirname(__file__)
CONFIG_FILE = os.path.join(BASE_DIR, "config.json")
SCHEMA_FILE_LOCAL = os.path.join("db", "schema", "schema.sql")

# Wczytanie config.json
with open(CONFIG_FILE, "r") as f:
    _config = json.load(f)

# Konfiguracja FTP i Oracle z config.json
ftp_conf = _config.get("ftp", {})
oracle_conf = _config.get("proxmox", {})

# Schemat – źródło
SCHEMA_SOURCE = "local"  # "local" albo "github"
SCHEMA_FILE_URL = "https://raw.githubusercontent.com/uwmkzacharewicz/ZSBD_projekt/main/schema.sql"

# Inne ustawienia
ENABLE_LOGGING = True
SCHEDULE_IMPORT_EVERY_MINUTES = 30

