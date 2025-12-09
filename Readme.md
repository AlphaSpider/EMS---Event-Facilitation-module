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
