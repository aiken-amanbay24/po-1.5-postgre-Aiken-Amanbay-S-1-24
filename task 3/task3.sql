CREATE DATABASE hospital_db;
USE hospital_db;

CREATE TABLE Department (
    Dept_ID INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Doctor (
    Dr_ID INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(100) UNIQUE,
    department_ID INT NOT NULL,
    FOREIGN KEY (department_ID) REFERENCES Department(Dept_ID)
);

CREATE TABLE Appointment (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Dr_ID INT,
    patient_full_name VARCHAR(100) NOT NULL,
    appointment_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'Scheduled',
    notes TEXT,
    FOREIGN KEY (Dr_ID) REFERENCES Doctor(Dr_ID),
    CHECK (status IN ('Scheduled','Completed','Cancelled'))
);

ALTER TABLE Doctor
ADD experience_years INT DEFAULT 0;

ALTER TABLE Appointment
MODIFY status VARCHAR(30) DEFAULT 'Scheduled';

ALTER TABLE Appointment
RENAME COLUMN patient_full_name TO patient_name;

INSERT INTO Department (name) VALUES
('Cardiology'),
('Neurology'),
('Pediatrics'),
('Surgery'),
('Dermatology');

INSERT INTO Doctor(first_name, last_name, specialization, phone, email, department_ID, experience_years) VALUES
('Inabat', 'Kairakbay', 'Cardiologist', '111111111', 'inabat@email.com', 1, 2),
('Assel', 'Balgabay', 'Neurologist', '2222222', 'assel@email.com', 2, 3),
('Aiken', 'Amanbay', 'Pediatrician', '3333333', 'aiken@email.com', 3, 4),
('Assylai', 'Zhumagaliyeva', 'Surgeon', '4444444444', 'assylai@email.com', 4, 5),
('Aruzhan', 'Tulegenova', 'Dermatologist', '555555555', 'aruzhan@email.com', 5, 6);

INSERT INTO Appointment (Dr_ID, patient_name, appointment_date, status, notes) VALUES
(1,'Aruzhan Tulegenova','2026-03-20','Scheduled','Regular check'),
(2,'Aigerim Nurlanova','2026-03-21','Completed','Headache'),
(3,'Dias Sarsenbay','2026-03-22','Scheduled','Child fever'),
(4,'Madina Zhumabayeva','2026-03-23','Cancelled','Surgery consultation'),
(5,'Nursultan Kairat','2026-03-24','Scheduled','Skin allergy');

SELECT * FROM Department;

SELECT * FROM Doctor;

SELECT * FROM Appointment;

SELECT 
Doctor.first_name,
Doctor.last_name,
Department.name
FROM Doctor
JOIN Department
ON Doctor.department_ID = Department.Dept_ID;

SELECT 
Appointment.patient_name,
Doctor.first_name,
Doctor.last_name,
Appointment.appointment_date
FROM Appointment
JOIN Doctor
ON Appointment.Dr_ID = Doctor.Dr_ID;