# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] — 2026-04-29

### Added
- **Linux/SQL Server Reference Guide** (`docs/Linux_SQLServer_Reference_Guide.docx`, 50 pages)
  - Part I: Linux command basics — SSH, file system, permissions, processes, network, packages, systemd, monitoring, text processing
  - Part II: SQL Server on Linux — install/config/sqlcmd/ODBC/backup/security
  - Part III: Glossary of 50+ key terms with definitions and examples
  - Part IV: Troubleshooting 16 common errors (symptom → cause → solution)
  - Part V: One-page cheatsheet for quick reference
- README updated with "Learning Materials" section explaining workbook vs reference guide

### Rationale
The hands-on workbook (v1.1) covers "what to do" procedurally. New learners need a companion that explains "why it works that way" and provides definitions for unfamiliar Linux/SQL Server concepts. The reference guide fills that gap with command syntax, options, and theory.

## [1.1.0] — 2026-04-29

### Changed (BREAKING)
- **OS upgrade**: Ubuntu 22.04 LTS → **Ubuntu 24.04 LTS (Noble)**
- **SQL Server upgrade**: SQL Server 2022 (16.x) → **SQL Server 2025 (17.x)**
- **Repository paths** updated to Ubuntu 24.04 official repos:
  - `mssql-server`: `config/ubuntu/22.04/mssql-server-2022.list` → `config/ubuntu/24.04/mssql-server-2025.list`
  - `mssql-tools`: `config/ubuntu/22.04/prod.list` → `config/ubuntu/24.04/prod.list`
- **GPG key registration** changed to Ubuntu 24.04 recommended method:
  - Before: `tee /etc/apt/trusted.gpg.d/microsoft.asc`
  - After: `gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg`
- **VM image alias** in Azure CLI: `Ubuntu2204` → `Ubuntu2404`
- **Python**: 3.10 (Jammy default) → 3.12 (Noble default)

### Added
- OS validation checks in `install-mssql.sh` and `install-tools.sh` (refuses non-24.04)
- Memory-aware swap creation: only adds 2GB swap when RAM < 6GB
- `msodbcsql18` package explicitly installed (was implicit dependency)
- Cleanup of legacy `mssql-server-2022.list` and `mssql-server-preview.list` for safe re-runs

### Rationale
- SQL Server 2022 does not officially support Ubuntu 24.04 — installation succeeds but `sqlservr` fails to start due to missing `liblber-2.4.so.2` and other openldap dependencies (Ubuntu 24.04 ships openldap 2.5+).
- SQL Server 2025 CU1 (released 2026-01) is the first version with official Ubuntu 24.04 support.
- Reference: [SQL Server 2025 GA on Ubuntu 24.04 LTS announcement](https://ubuntu.com/blog/sql-server-2025-ubuntu-24-04-lts)
- Microsoft Learn: [Configure repositories for installing and upgrading SQL Server 2025 on Linux](https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-change-repo)

### Compatibility
- ODBC Driver 18 — unchanged, supports both SQL 2022 and 2025
- pyodbc, Flask, application code — unchanged
- Database schema (`sql/schema.sql`, `sql/seed.sql`) — unchanged, T-SQL is backward compatible

### Migration from v1.0
If you have a running v1.0 setup (Ubuntu 22.04 + SQL 2022) and want to upgrade:
1. Backup database: `BACKUP DATABASE CarMarket TO DISK = '/var/opt/mssql/data/cm.bak'`
2. Recreate VM with `Ubuntu2404` image
3. Restore database after running v1.1 install scripts

## [1.0.0] — 2026-04-29

### Added
- Initial release: SQL VM Used Car MVP
- Azure CLI scripts for VM provisioning (`infra/`)
- SQL Server 2022 installation automation
- Python Flask + pyodbc backend with 5 REST endpoints
- Bootstrap 5 single-page frontend
- 3-table data model (Users / Cars / Inquiries)
- systemd service unit
- 36-page hands-on workbook (DOCX)
- Architecture documentation
- Designed by 5 teams: Infrastructure / Web Dev / Network / Test / Documentation
