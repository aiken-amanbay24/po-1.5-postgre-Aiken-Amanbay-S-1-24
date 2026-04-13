DROP TABLE IF EXISTS feedback CASCADE;
DROP TABLE IF EXISTS submissions CASCADE;
DROP TABLE IF EXISTS progress CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS assessments CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS modules CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS users CASCADE;


CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('student', 'instructor')),
    created_at DATE NOT NULL CHECK (created_at > DATE '2026-01-01')
);


CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    instructor_id INT,
    created_at DATE NOT NULL CHECK (created_at > DATE '2026-01-01'),
    FOREIGN KEY (instructor_id) REFERENCES users(user_id)
);


CREATE TABLE modules (
    module_id SERIAL PRIMARY KEY,
    course_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    position INT NOT NULL CHECK (position >= 0),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);


CREATE TABLE lessons (
    lesson_id SERIAL PRIMARY KEY,
    module_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    position INT NOT NULL CHECK (position >= 0),
    FOREIGN KEY (module_id) REFERENCES modules(module_id)
);


CREATE TABLE assessments (
    assessment_id SERIAL PRIMARY KEY,
    lesson_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    max_score INT NOT NULL CHECK (max_score >= 0),
    due_date DATE CHECK (due_date > DATE '2026-01-01'),
    FOREIGN KEY (lesson_id) REFERENCES lessons(lesson_id)
);


CREATE TABLE enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    enrolled_at DATE NOT NULL CHECK (enrolled_at > DATE '2026-01-01'),
    status VARCHAR(20) NOT NULL CHECK (status IN ('active', 'completed')),
    FOREIGN KEY (student_id) REFERENCES users(user_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);


CREATE TABLE progress (
    progress_id SERIAL PRIMARY KEY,
    student_id INT NOT NULL,
    lesson_id INT NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (student_id) REFERENCES users(user_id),
    FOREIGN KEY (lesson_id) REFERENCES lessons(lesson_id)
);

CREATE TABLE submissions (
    submission_id SERIAL PRIMARY KEY,
    assessment_id INT NOT NULL,
    student_id INT NOT NULL,
    score INT CHECK (score >= 0),
    submitted_at DATE NOT NULL CHECK (submitted_at > DATE '2026-01-01'),
    FOREIGN KEY (assessment_id) REFERENCES assessments(assessment_id),
    FOREIGN KEY (student_id) REFERENCES users(user_id)
);

CREATE TABLE feedback (
    feedback_id SERIAL PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at DATE NOT NULL CHECK (created_at > DATE '2026-01-01'),
    FOREIGN KEY (student_id) REFERENCES users(user_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);


INSERT INTO users (first_name, last_name, email, password, role, created_at)
VALUES
('Aiken', 'Student', 'aiken1@mail.com', '12345', 'student', '2026-02-01'),
('Dias', 'Teacher', 'dias@mail.com', '12345', 'instructor', '2026-02-01');


INSERT INTO courses (title, description, instructor_id, created_at)
VALUES
('Programming Basics', 'Intro course', 2, '2026-02-05');


INSERT INTO modules (course_id, title, position)
VALUES
(1, 'Introduction', 1);

INSERT INTO lessons (module_id, title, content, position)
VALUES
(1, 'What is programming?', 'Basic concepts', 1);

INSERT INTO assessments (lesson_id, title, max_score, due_date)
VALUES
(1, 'Quiz 1', 100, '2026-03-01');

INSERT INTO enrollments (student_id, course_id, enrolled_at, status)
VALUES
(1, 1, '2026-02-10', 'active');


INSERT INTO progress (student_id, lesson_id, completed)
VALUES
(1, 1, TRUE);

INSERT INTO submissions (assessment_id, student_id, score, submitted_at)
VALUES
(1, 1, 90, '2026-03-01');

INSERT INTO feedback (student_id, course_id, rating, comment, created_at)
VALUES
(1, 1, 5, 'Great course!', '2026-03-02');


SELECT * FROM users;