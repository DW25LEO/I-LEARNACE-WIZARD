# I-LEARNACE WIZARD

Real multi-school portal creation and management platform.

## Stack
- Frontend: React + Vite
- Backend: Node.js + Express
- Database: MySQL

## One-click local run
Double-click **SETUP-PROJECT.bat**.

The single runner:
1. checks required tools,
2. installs backend/frontend packages,
3. asks for local MySQL credentials,
4. creates `backend/.env`,
5. creates/imports the MySQL database,
6. verifies the database,
7. initializes the real I-LEARNACE WIZARD Super Admin account,
8. starts backend and frontend,
9. opens `http://localhost:5175`.

No demo schools, students, teachers, or exams are included.

Phase 17.3: MySQL-compatible provisioning migration fix.

## Phase 19.2
Fixes built-in template activation, permanent working portal/admin links, provisioning progress in the application table, retry handling, and encrypted credential recovery for the global Super Admin.
