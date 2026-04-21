# Installation Guide

This guide provides step-by-step instructions to install and run the project locally. 

## 1. Prerequisites

Before starting, ensure that the following are installed on your system:
- **Node.js**: (Version 18.x or above)
- **PostgreSQL**: (Version 14.x or above)
- **Xcode (for iOS deployment)**: (Version 14.0 or above)

## 2. Database Setup

1. **Unzip the Database File**:
   Extract `database_dump.zip` located in the `Code/Database` directory using the provided password.
   
2. **Execute the SQL Dump**:
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

*(Insert Screenshot here of successful database restoration)*

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
   Create a `.env` file in the root of the backend folder. You must map the configuration fields to your own environment:
   ```env
   PORT=3000
   DB_USER=postgres
   DB_HOST=localhost
   DB_DATABASE=roar_db
   DB_PASSWORD=your_postgres_password
   DB_PORT=5432
   JWT_SECRET=your_secret_key
   ```
   *(Update these credentials as necessary)*

4. **Run the Server**:
   ```bash
   npm run start
   ```

*(Insert Screenshot here of the backend server running successfully)*

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

*(Insert Screenshot here of the iOS application running in the Simulator)*
