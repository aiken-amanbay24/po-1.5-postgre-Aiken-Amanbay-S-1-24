-- Delete tables first so the script can be rerun without errors
DROP TABLE IF EXISTS feedback CASCADE;
DROP TABLE IF EXISTS submissions CASCADE;
DROP TABLE IF EXISTS progress CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS assessments CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS modules CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Table: users
-- Stores all platform users: students and instructors
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY, 
    -- SERIAL is used for automatic ID generation

    first_name VARCHAR(50) NOT NULL, 
    -- VARCHAR(50) is enough for first names, NOT NULL because every user must have a name

    last_name VARCHAR(50) NOT NULL, 
    -- VARCHAR(50) is enough for last names, NOT NULL because every user must have a surname

    email VARCHAR(100) UNIQUE NOT NULL, 
    -- Email must be unique to avoid duplicate accounts, NOT NULL because login/contact requires email

    password VARCHAR(255) NOT NULL, 
    -- VARCHAR(255) is commonly used for passwords, especially if passwords are stored in hashed form

    role VARCHAR(20) NOT NULL CHECK (role IN ('student', 'instructor')), 
    -- Role is limited to specific values to maintain valid user types

    created_at DATE NOT NULL CHECK (created_at > DATE '2026-01-01')
    -- DATE is enough because time is not required here
    -- CHECK ensures only dates after January 1, 2026 are allowed
);


-- Table: courses
-- Stores all courses available on the platform
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY, 
    -- Auto-incremented primary key

    title VARCHAR(200) NOT NULL, 
    -- Course title is required, VARCHAR(200) allows enough length

    description TEXT, 
    -- TEXT is used because course description can be long

    instructor_id INT, 
    -- References the instructor who teaches the course

    created_at DATE NOT NULL CHECK (created_at > DATE '2026-01-01'),
    -- Stores the course creation date, restricted by assignment requirement

    FOREIGN KEY (instructor_id) REFERENCES users(user_id)
    -- Creates relationship between courses and users
);


-- Table: modules
-- A course is divided into modules
CREATE TABLE modules (
    module_id SERIAL PRIMARY KEY, 
    -- Unique ID for each module

    course_id INT NOT NULL, 
    -- Each module must belong to a course

    title VARCHAR(200) NOT NULL, 
    -- Module title is required

    position INT NOT NULL CHECK (position >= 0), 
    -- Position shows order inside the course, cannot be negative

    FOREIGN KEY (course_id) REFERENCES courses(course_id)
    -- Relationship with courses table
);


-- Table: lessons
-- Each module contains lessons
CREATE TABLE lessons (
    lesson_id SERIAL PRIMARY KEY, 
    -- Unique ID for each lesson

    module_id INT NOT NULL, 
    -- Each lesson must belong to a module

    title VARCHAR(200) NOT NULL, 
    -- Lesson title is required

    content TEXT, 
    -- TEXT is used because lesson content may be long

    position INT NOT NULL CHECK (position >= 0), 
    -- Defines lesson order inside the module, cannot be negative

    FOREIGN KEY (module_id) REFERENCES modules(module_id)
    -- Relationship with modules table
);


-- Table: assessments
-- Stores quizzes, tests, or exams related to lessons
CREATE TABLE assessments (
    assessment_id SERIAL PRIMARY KEY, 
    -- Unique ID for each assessment

    lesson_id INT NOT NULL, 
    -- Each assessment belongs to one lesson

    title VARCHAR(200) NOT NULL, 
    -- Assessment title is required

    max_score INT NOT NULL CHECK (max_score >= 0), 
    -- Score cannot be negative

    due_date DATE CHECK (due_date > DATE '2026-01-01'),
    -- DATE is enough because exact time is not required
    -- CHECK enforces valid future date according to task

    FOREIGN KEY (lesson_id) REFERENCES lessons(lesson_id)
    -- Relationship with lessons table
);


-- Table: enrollments
-- Connects students and courses (many-to-many relationship)
CREATE TABLE enrollments (
    enrollment_id SERIAL PRIMARY KEY, 
    -- Unique ID for each enrollment record

    student_id INT NOT NULL, 
    -- Student must exist in users table

    course_id INT NOT NULL, 
    -- Course must exist in courses table

    enrolled_at DATE NOT NULL CHECK (enrolled_at > DATE '2026-01-01'),
    -- Enrollment date must follow the assignment date rule

    status VARCHAR(20) NOT NULL CHECK (status IN ('active', 'completed')), 
    -- Enrollment status is restricted to valid values only

    FOREIGN KEY (student_id) REFERENCES users(user_id),
    -- Links enrollment to a student

    FOREIGN KEY (course_id) REFERENCES courses(course_id)
    -- Links enrollment to a course
);


-- Table: progress
-- Tracks whether a student completed a lesson
CREATE TABLE progress (
    progress_id SERIAL PRIMARY KEY, 
    -- Unique ID for each progress record

    student_id INT NOT NULL, 
    -- Student reference

    lesson_id INT NOT NULL, 
    -- Lesson reference

    completed BOOLEAN DEFAULT FALSE, 
    -- BOOLEAN is suitable because lesson can only be completed or not completed
    -- DEFAULT FALSE means unfinished unless marked otherwise

    FOREIGN KEY (student_id) REFERENCES users(user_id),
    FOREIGN KEY (lesson_id) REFERENCES lessons(lesson_id)
);


-- Table: submissions
-- Stores students' submitted assessment results
CREATE TABLE submissions (
    submission_id SERIAL PRIMARY KEY, 
    -- Unique ID for each submission

    assessment_id INT NOT NULL, 
    -- Each submission belongs to an assessment

    student_id INT NOT NULL, 
    -- Each submission belongs to a student

    score INT CHECK (score >= 0), 
    -- Score cannot be negative

    submitted_at DATE NOT NULL CHECK (submitted_at > DATE '2026-01-01'),
    -- Submission date must satisfy required date condition

    FOREIGN KEY (assessment_id) REFERENCES assessments(assessment_id),
    FOREIGN KEY (student_id) REFERENCES users(user_id)
);


-- Table: feedback
-- Stores students' reviews for courses
CREATE TABLE feedback (
    feedback_id SERIAL PRIMARY KEY, 
    -- Unique ID for each feedback entry

    student_id INT NOT NULL, 
    -- Student who leaves feedback

    course_id INT NOT NULL, 
    -- Course being reviewed

    rating INT CHECK (rating BETWEEN 1 AND 5), 
    -- Rating is limited to values from 1 to 5

    comment TEXT, 
    -- TEXT allows long written feedback

    created_at DATE NOT NULL CHECK (created_at > DATE '2026-01-01'),
    -- Feedback date must be after January 1, 2026

    FOREIGN KEY (student_id) REFERENCES users(user_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);


-- Insert sample users
INSERT INTO users (first_name, last_name, email, password, role, created_at)
VALUES
('Aiken', 'Student', 'aiken1@mail.com', '12345', 'student', '2026-02-01'),
('Dias', 'Teacher', 'dias@mail.com', '12345', 'instructor', '2026-02-01');


-- Insert sample course
INSERT INTO courses (title, description, instructor_id, created_at)
VALUES
('Programming Basics', 'Intro course', 2, '2026-02-05');


-- Insert sample module
INSERT INTO modules (course_id, title, position)
VALUES
(1, 'Introduction', 1);


-- Insert sample lesson
INSERT INTO lessons (module_id, title, content, position)
VALUES
(1, 'What is programming?', 'Basic concepts', 1);


-- Insert sample assessment
INSERT INTO assessments (lesson_id, title, max_score, due_date)
VALUES
(1, 'Quiz 1', 100, '2026-03-01');


-- Insert sample enrollment
INSERT INTO enrollments (student_id, course_id, enrolled_at, status)
VALUES
(1, 1, '2026-02-10', 'active');


-- Insert sample progress
INSERT INTO progress (student_id, lesson_id, completed)
VALUES
(1, 1, TRUE);


-- Insert sample submission
INSERT INTO submissions (assessment_id, student_id, score, submitted_at)
VALUES
(1, 1, 90, '2026-03-01');


-- Insert sample feedback
INSERT INTO feedback (student_id, course_id, rating, comment, created_at)
VALUES
(1, 1, 5, 'Great course!', '2026-03-02');


-- Show all users
SELECT * FROM users;
