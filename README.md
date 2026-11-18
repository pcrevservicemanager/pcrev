# PC Revolution System
Flask + MySQL/MariaDB + HTML/CSS.

## Setup
    python -m venv venv
    venv\Scripts\Activate.ps1
    python -m pip install -r requirements.txt
    mysql -u root -p < schema.sql          (or import schema.sql in phpMyAdmin)
    copy .env.example .env                 (fill in DB_USER, DB_PASSWORD and a random SECRET_KEY)
    python -m flask --app app run --debug

## Modules
- Job Orders: live (form, list, search, status, print, QR status page)
- Ticketing, Inventory, Point of Sale: tables ready in schema.sql, nav entries ready in MODULES in app.py

Set PUBLIC_URL to the shop's public address so the QR code on printed job orders opens on customers' phones.

## Sign in and roles
First visit opens /setup to create the first Admin. After that, Admin and HR register staff under Staff.

| Role | Access |
|---|---|
| Admin | All job orders, staff accounts (including other Admins) |
| Service Manager | All job orders (create, edit, assign technician) |
| Technical In-Charge | Only their own pending jobs (Received, Diagnosing, Waiting for Parts, Repairing); can update work and status |
| HR | Staff accounts only (cannot edit Admin accounts) |

Edit ROLE_PERMS in app.py to change what a role can do.

Existing database? Run migration_add_users.sql once.
