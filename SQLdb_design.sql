
-- SECTION 1: SCHEMA DEFINITION

-- 1. USERS
CREATE TABLE app_user (
    id SERIAL PRIMARY KEY, username VARCHAR(150) UNIQUE NOT NULL, email VARCHAR(254) NOT NULL,
    role VARCHAR(10) CHECK (role IN ('ADMIN', 'TEACHER', 'STUDENT', 'PARENT', 'MANAGEMENT')),
    department VARCHAR(100), is_active BOOLEAN DEFAULT TRUE, date_joined TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. VENUES & RESOURCES
CREATE TABLE app_venue (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL, capacity INTEGER NOT NULL, location VARCHAR(200) NOT NULL);

CREATE TABLE app_resource (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL, total_quantity INTEGER NOT NULL);

-- 3. EVENTS - Main Table
CREATE TABLE app_event (id SERIAL PRIMARY KEY, title VARCHAR(200) NOT NULL, description TEXT,
    event_type VARCHAR(20) CHECK (event_type IN ('WORKSHOP', 'SEMINAR', 'CULTURAL', 'SPORTS', 'CLUB', 'EXAM')),
    status VARCHAR(20) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PENDING', 'APPROVED', 'REJECTED', 'COMPLETED')),
    
    -- Scheduling
    start_datetime TIMESTAMP WITH TIME ZONE NOT NULL, end_datetime TIMESTAMP WITH TIME ZONE NOT NULL, duration_minutes INTEGER,
    
    -- Dpt
    organizing_department VARCHAR(100), created_by_id INTEGER REFERENCES app_user(id) ON DELETE CASCADE,
    venue_id INTEGER REFERENCES app_venue(id) ON DELETE SET NULL,
    
    -- Registration
    is_registration_required BOOLEAN DEFAULT TRUE, registration_deadline TIMESTAMP WITH TIME ZONE, target_audience VARCHAR(50) DEFAULT 'ALL',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP);

-- 4. Many-to-Many Relationships Tables

-- Event Resource Request
CREATE TABLE app_eventresourcerequest (
    id SERIAL PRIMARY KEY, event_id INTEGER REFERENCES app_event(id) ON DELETE CASCADE,
    resource_id INTEGER REFERENCES app_resource(id) ON DELETE CASCADE, quantity_needed INTEGER DEFAULT 1);

-- Event Coordinators Table
CREATE TABLE app_event_coordinators (
    id SERIAL PRIMARY KEY, event_id INTEGER REFERENCES app_event(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES app_user(id) ON DELETE CASCADE);

-- 5. REGISTRATION & FEEDBACK
CREATE TABLE app_registration (
    id SERIAL PRIMARY KEY, event_id INTEGER REFERENCES app_event(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES app_user(id) ON DELETE CASCADE, registered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    attended BOOLEAN DEFAULT FALSE,
    UNIQUE(event_id, user_id));

CREATE TABLE app_feedback (
    id SERIAL PRIMARY KEY, event_id INTEGER REFERENCES app_event(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES app_user(id) ON DELETE CASCADE, rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comments TEXT, submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP);


-- SECTION 2: BUSINESS LOGIC QUERIES (DML)

/* * Conflict detevction
 * This is for to check if a venue is already booked 
 */
SELECT e.id, e.title, e.start_datetime, e.end_datetime FROM app_event e
WHERE e.venue_id = 1 
  AND e.status = 'APPROVED'
  AND (
    e.start_datetime < '2025-12-15 12:00:00' 
    AND e.end_datetime > '2025-12-15 10:00:00'
  );


/* * Checking resource availability*/
SELECT 
    r.name,
    r.total_quantity,
    COALESCE(SUM(req.quantity_needed), 0) as currently_booked,
    (r.total_quantity - COALESCE(SUM(req.quantity_needed), 0)) as available_stock
FROM app_resource r
LEFT JOIN app_eventresourcerequest req ON r.id = req.resource_id
LEFT JOIN app_event e ON req.event_id = e.id
WHERE r.id = 5 
  AND e.status = 'APPROVED'
  AND (e.start_datetime < '2025-12-15 12:00:00' AND e.end_datetime > '2025-12-15 10:00:00')
GROUP BY r.id;


/* * C. Event Success Review for Management
 */
SELECT 
    e.title,
    e.organizing_department,
    COUNT(DISTINCT r.id) as total_registrations,
    COUNT(DISTINCT CASE WHEN r.attended = TRUE THEN r.id END) as actual_attendees,
    ROUND(AVG(f.rating), 2) as average_rating
FROM app_event e
LEFT JOIN app_registration r ON e.id = r.event_id
LEFT JOIN app_feedback f ON e.id = f.event_id
WHERE e.status = 'COMPLETED' 
GROUP BY e.id
ORDER BY average_rating DESC;