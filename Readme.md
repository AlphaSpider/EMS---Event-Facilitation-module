## 1. Data Model & Database Architecture
<p>
The data module is designed for PostgreSQL, utilizing a normalized relational schema to ensure data integrity and efficient querying. The architecture separates "Operational Data" (live event management) from "Analytical Data" (reporting), ensuring high performance even as the data grows.
</p>

### Implementation Files


* Python Logic (Django ORM): events/models.py - Defines the application-level data structures.


* Database Schema (SQL): events/SQLdb_design.sql - Contains DDL and optimized raw queries.

#### Entity Relationship Diagram (ERD)

The following diagram illustrates the relationships between Users, Events, Venues, and the Feedback system.

![ERD_img](https://github.com/AlphaSpider/EMS---Event-Facilitation-module/blob/6a19fa6a814efd7d7cf59bcbcfde6fba61e842fb/docs/Datamodel_diagram.png)

### Key Design Decisions

1. RBAC Integration: The User model includes a specific role field (Admin, Teacher, Student) to enforce the detailed permissions matrix required by the system.

2. Resource Allocation (Many-to-Many): Instead of a simple link between Events and Resources, I implemented a Through Model (EventResourceRequest). This allows tracking the quantity of items needed (e.g., "Event A needs 2 Projectors," not just "Event A needs Projectors").

3. Venue Conflict Prevention: The Venue table is decoupled from Event to allow for "Time-Overlap" validation queries (see SQL file).

4. Dedicated Analytics Table: The EventSuccessReport table has a One-to-One relationship with Event. This separates heavy aggregation logic (calculating average ratings/attendance) from the live transactional database, optimizing dashboard performance.


## 2. System Workflows

The Event Facilitation Module operates on four primary logic flows to ensure seamless coordination between Admins, Teachers, and Students.

#### A. Event Creation & Approval Workflow

This workflow ensures that all events are vetted by the administration before resources are committed.

1. Proposal: A Teacher logs in and submits an "Event Proposal" (Status: DRAFT).

2. Submission: The teacher finalizes details (venue preference, budget, resources) and submits for review (Status: PENDING).

3. Validation: The system automatically checks for:

* Venue availability conflicts.

* Resource quantity availability.

4. Admin Review: An Admin receives a notification. They review the proposal.

* If Approved: Status changes to APPROVED. Notification sent to Teacher and Students.

* If Rejected: Status changes to REJECTED. Reason for rejection sent to Teacher.

![Workflow_img](https://github.com/AlphaSpider/EMS---Event-Facilitation-module/blob/6a19fa6a814efd7d7cf59bcbcfde6fba61e842fb/docs/Workflow.png)

#### B. Venue & Resource Allocation Workflow
This prevents double-booking and ensures logistics are handled automatically.

1. Check Availability: When an event is drafted, the system queries the Venue and Resource tables for the selected time slot.

2. Provisional Hold: Upon submission (Pending state), resources are "provisionally held" to prevent other drafts from claiming them.

3. Confirmation: Upon Admin approval, the hold becomes a permanent booking.

4. Release: If an event is rejected or cancelled, resources are immediately released back to the pool.

#### C. Student Registration Workflow
1. Browse: Student views the "Upcoming Events" dashboard.

2. Register: Student clicks "Register".

3. Capacity Check: System checks Event.registrations.count() < Venue.capacity.

* Success: Record created in Registration table. Confirmation email sent.

* Failure: Student added to "Waitlist" (optional enhancement).

#### D. Feedback Loop
1. Trigger: 24 hours after Event.end_datetime, a background job triggers.

2. Notification: Attendees (marked as attended=True) receive an email with a feedback link.

3. Submission: User submits rating (1-5) and comments.

4. Review: Data is aggregated for the "Management Review" dashboard.

## 3. User Roles & Permissions (RBAC)

<p>The module implements a strict Role-Based Access Control (RBAC) system to ensure data integrity and security. The system distinguishes between four primary user types, each with specific privileges.</p>


### Permissions Matrix

| Feature / Action |🛡️ Admin | 👨‍🏫 Teacher | 🎓 Student | 👨‍👩‍👧 Parent |
|------------------|---------|-------------|-------------|-----------|
| Event Management |  |  |  |
| Create Event Proposal | ✅ | ✅ | ❌ | ❌ |
| Approve/Reject Events | ✅ | ❌ | ❌ | ❌ |
| Edit Event Details | ✅ | ✅ (Own Events) | ❌ | ❌ |
|Cancel Event|✅|❌|❌|❌|
|Logistics|||||
|View Venue Availability|✅|✅|❌|❌|
|Allocate Resources|✅|❌|❌|❌|
|Participation|||||
|View Event Calendar|✅|✅|✅|✅|
|Register for Event|❌|❌|✅|❌|
|Manage Participant List|✅|✅|❌|❌|
|Feedback & Alerts|||||
|Receive Notifications|✅|✅|✅|✅|
|Submit Feedback|❌|❌|✅|✅|
|View Feedback Reports|✅|✅ (Own Events)|❌|❌|


### Role Descriptions

#### 1. Administrator (Superuser):

<p>   

* Has full control over the system.
  
* Sole authority to approve event proposals and finalize venue bookings.

* Responsible for conflict resolution if two teachers request the same resource. </p>

#### 2. Teacher (Staff):
<p>
  
  * Primary initiator of events.

  * Can view venue availability to plan schedules but cannot finalize bookings without approval.

  * Responsible for marking attendance and uploading event materials.
</p>

#### 3. Student:
<p>
  
* End-user of the events.

* Can browse the calendar, filter by event type (e.g., "Sports", "Seminar"), and register.

* Provides "Participant Feedback" after the event.
</p>

#### 4. Parent:

<p>
  
  * Passive observer for upcoming events (View Only).

  * Active participant for specific feedback (e.g., "Event Success Feedback" as requested in requirements).
</p>

#### 5. Management:

<p>
  
  * Management can review the success of the event updated automatically.

</p>


## 4. Module Architecture

### High-Level System Design

<p>
    The system follows a layered architecture, separating the Presentation Layer (Frontend), Business Logic Layer (Backend API), and Data Layer (PostgreSQL). Crucially, it employs an Asynchronous Task Queue (Celery + Redis) to decouple time-consuming operations from the main request-response cycle.
</p>

![architecture_img]()


### Component Breakdown


**1. Frontend Layer (SPA)**
  
* Role: Handles user interaction and presentation logic.

* Tech: React.js / Vue.js.

* Interaction: Communicates with the backend exclusively via RESTful APIs (JSON). It contains no business logic, ensuring the backend remains the single source of truth.

**2. API Gateway & Load Balancing**

* Role: The entry point for all traffic. It handles SSL termination, basic rate limiting, and request routing.

* Tech: Nginx (or Cloud-native Load Balancers).

**3. Backend Application (Synchronous)**

* Core Framework: Django with Django REST Framework (DRF).

* Why Django?: Its "batteries-included" nature provides a robust ORM, built-in Authentication/Authorization (RBAC), and admin interface out of the box, significantly speeding up development of the complex "User Role" requirements.

* Services Layer: Business logic is encapsulated in services.py (e.g., EventService, VenueService) rather than bloated View functions. This makes the code testable and reusable.

**4. Asynchronous Task Queue (The "Background" Worker)**
* Role: Handles heavy lifting that shouldn't make the user wait.

* Tech: Celery (Worker) + Redis (Message Broker).

* Key Use Case: When an Admin clicks "Approve Event", the system must send emails to 500+ students.

* Without Async: The Admin's browser freezes for 30 seconds while emails send.

* With Async: The API returns "Success" instantly. The SendEmailTask is pushed to Redis, and Celery workers process the emails in the background.

**5. Data Persistence Layer**
* Database: PostgreSQL.

* Why PostgreSQL?: The module requires complex relational queries (e.g., checking venue availability time overlaps using overlapping logic). PostgreSQL's robust concurrency control and JSONB support make it superior to MySQL for this use case.

### Request Lifecycle Example


**1. Synchronous (User Action):**

* A Teacher submits a POST request to /api/events/.

* The API Layer validates the data (e.g., checks if the date is in the future).

* The VenueService runs a SQL query to check for booking conflicts.

* If valid, the event is saved to PostgreSQL with status PENDING.

* The server responds 201 Created to the frontend.


**2. Asynchronous (System Action):**

* Later, an Admin approves the event.

* The EventService updates the status to APPROVED in the DB.

* It immediately pushes a notify_participants_task to Redis.

* A Celery Worker picks up the task, generates the email content, and sends it via an external provider (e.g., SendGrid).