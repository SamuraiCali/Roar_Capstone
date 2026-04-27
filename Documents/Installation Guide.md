# Installation Guide

This guide provides step-by-step instructions to install and run the project locally.

## 1. Prerequisites

Before starting, ensure that the following are installed on your system:

- **Node.js**: (Version 18.x or above)
- **Docker**: (Version 25.x or above)
- **Xcode (for iOS deployment)**: (Version 14.0 or above)
- **PostgreSQL**: (Version 14.x or above)

## 2. Database Setup

1. **Unzip the Database File**:
   Extract `database_dump.zip` located in the `Code/Database` directory using the provided password in the description of the InstallMaintenanceGuide YouTube video (URL can be found in Videos/index.html).

2. **Place SQL Dump in Directory for Docker**
   Move the SQL Dump file "database_dump.sql" into Code/WebSite/backend-folder/src/config
   This is the directory that Docker will be scanning later for seeding the database

3. **Optional: Execute the SQL Dump**:
   This step is only if one wants to view the SQL Dump data locally. It does not affect installation.
   Open a terminal and log into your local PostgreSQL instance:
    ```bash
    psql -U postgres
    ```
    Create a new database for the project and execute the SQL dump file:
    ```bash
    CREATE DATABASE roar_db;
    \c roar_db
    \i path/to/extracted/database_dump.sql
    ```

## 3. Backend Setup

1. **Navigate to the Backend Directory**:

    ```bash
    cd Code/WebSite/backend-folder
    ```

2. **Install Dependencies**:

    ```bash
    npm install
    ```

3. **Configure Environment Variables**:
   In this directory is a password-protected folder called "env.zip", containing a file named
   ".env" containing all the necessary environment variables required to connect to the
   postgresql server, AWS server, and other miscellaneous items. Its password can be found in the description of the InstallMaintenanceGuide YouTube video (URL in Videos/index.html).
   After obtaining access to the folder, ensure that ".env" is moved inside the "backend-folder" directory

4. **Run the Server**:
    ```bash
    npm run dk
    ```
    Internally, this runs the command "docker-compose up", which causes Docker to setup the server
    environment and postgresql server as outlined in the Dockerfile and docker-compose.yml
    Note: Docker Desktop (or the Docker daemon) must be running before executing this command.

<img width="1138" height="245" alt="dockercompose" src="https://github.com/user-attachments/assets/cc687021-eeb0-4349-9e08-bec6bd296899" />
//
<img width="1138" height="151" alt="dbready" src="https://github.com/user-attachments/assets/2b725e9e-c49e-4633-8969-da88128bb4f7" />

## 4. Frontend Setup (iOS App)

1. **Navigate to the Frontend Directory**:

    ```bash
    cd Code/WebSite/frontend-folder
    ```

2. **Open the Project in Xcode**:
   Open `Roar.xcodeproj` or `Roar.xcworkspace` in Xcode.

3. **Configure API URL**:
   Ensure that your API client is pointing to the local backend URL: `http://localhost:3000`. This is typically configured in `NetworkManager.swift` or `Constants.swift`.

4. **Build and Run**:
   Select an iOS Simulator or connected device in Xcode and press the `Run` (Play) button.

    <img width="282" height="576" alt="fyp" src="https://github.com/user-attachments/assets/38439c2f-2211-40d8-abe0-ffcae822c547" />
