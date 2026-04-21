# Code Directory Structure

This `Code` directory contains all source code, deployable code, database schemas, and documentation required for the complete system. 

The structure of this directory is designed to ensure all project resources are fully included, well-documented, and securely packaged.

## Directory Layout

```text
Code/
├── WebSite/                # (or Frontend/Backend) All deployable code & source files for the application
├── Database/               # SQL files, schemas, and data population scripts
├── Installation Guide.md   # Step-by-step setup instructions with screenshots
├── User Manual.md          # Comprehensive user guide detailing how the system works
└── README.md               # This file
```

### 1. `/WebSite` (Application Source & Deployable Code)
This folder includes all the source files and deployable code for the project's web site or application. The source code is organized into frontend and backend directories representing the iOS application and the Express API respectively.

### 2. `/Database` (Database Setup & Population)
This directory includes the necessary files designed to instantiate the database environment.
- Contains the `.sql` dump file that executes the creation of the database, tables, relationships, and populates the database with the seed data used in this version of the project.
- **Security Note:** To ensure that private data is not revealed in plain text, the database dump file has been **zipped and password-protected**. The required extraction password has been provided via a separate email, as instructed.

### 3. `Installation Guide`
A detailed, step-by-step manual covering how to install the project from scratch. It includes:
- System prerequisites and dependency installations.
- Screenshots mapping out the installation process visually.
- Detailed instructions specifying which configuration variables must be modified depending on the testing or server environment.

### 4. `User Manual`
The User Manual document acts as the primary guide for the end-user. It outlines the core features, how to navigate the platform, and explains how to interact with the project functionally.

---

## Evaluation Instructions

To effectively evaluate or run this project:
1. Please begin by thoroughly reading the **Installation Guide.md**.
2. Unzip the SQL dump located in `Database/database_dump.zip` using the password provided securely via email.
3. Follow the installation guide's configuration steps to connect the local application in `/WebSite` to your newly instantiated database.
