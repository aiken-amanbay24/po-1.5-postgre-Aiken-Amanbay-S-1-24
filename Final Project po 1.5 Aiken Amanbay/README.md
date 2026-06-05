🛒 Online Shop Database Schema
Author: Aiken Amanbay

Group: PO-1-24

DBMS: PostgreSQL

Database Name: onlineshop_db

Schema Name: onlineshop_schema

📌 Project Description
This project represents a fully designed relational database from scratch, intended to manage the core operations of an online store. The database covers the entire data lifecycle: from customer registration and inventory management (via suppliers) to order processing, payments, and delivery tracking.

The script is written using modern PostgreSQL standards, featuring idempotent DDL operations, strict data integrity constraints, automatically computed columns, and a role-based security model.

🏗 Database Structure
The database consists of 11 interconnected tables, logically grouped into the following domains:

Users and Staff: customer, employee, addresses (delivery locations).

Catalog and Inventory: product, category, supplier, product_supplier (supply tracking).

Sales and Logistics: orders, order_items (shopping cart details), payment, delivery.

🚀 Key Technical Features
Idempotency (Safe Execution): The use of anonymous DO $$... END$$ blocks allows the script to be executed multiple times without throwing errors (e.g., when renaming columns or adding new constraints).

Data Integrity (Constraints):

Uses ON DELETE RESTRICT to protect critical data (e.g., preventing the deletion of categories that contain active products).

Uses ON DELETE CASCADE for automatic cleanup of dependent data (e.g., deleting payments when an order is deleted).

Business logic checks via CHECK constraints (e.g., product price >= 0, strict role and order statuses).

Automated Calculations: The total_price column in order_items is calculated at the database level using GENERATED ALWAYS AS.

Security and Access Control (DCL): Privilege separation is implemented through roles:

onlineshop_readonly — read-only access (for reporting/analytics).

onlineshop_writer — write access for the application (with UPDATE privileges revoked on the orders table to maintain an immutable history).

📂 SQL Script Structure
The script is logically divided into 6 parts:

SCHEMA SETUP: Schema creation and environment isolation.

CREATE TABLES: Table definitions and foreign key establishment.

ALTER TABLE: Modifying existing tables (using dynamic SQL).

DATA INSERTION: Purging old data (TRUNCATE) and populating tables with mock data.

UPDATE & DELETE: Examples of data modification (e.g., rewarding loyalty_points).

GRANT & REVOKE: Role management and permission allocation.

🛠 How to Run
Ensure you have PostgreSQL installed and running.

Create an empty database:

CREATE DATABASE onlineshop_db;

3. Connect to the newly created database.
4. Open the SQL script file (e.g., `init_db.sql`) and run the entire script. All schemas, tables, relationships, and test data will be generated automatically.

---
*This project was developed as a final assignment for a Database Design course.*
