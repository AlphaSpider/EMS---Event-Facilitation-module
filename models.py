from django.db import models
from django.contrib.auth.models import AbstractUser

#1. USER MANAGEMENT & ROLES

class User(AbstractUser):
    ROLE_CHOICES = (
        ('ADMIN', 'Administrator'),
        ('TEACHER', 'Teacher'),
        ('STUDENT', 'Student'),
        ('PARENT', 'Parent'),
        ('MANAGEMENT', 'Management')
    )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)
    department = models.CharField(max_length=100, blank=True, null=True)

    def __str__(self):
        return f"{self.username} ({self.role})"

#2. Venue & Resource Management
class Venue(models.Model):
    name = models.CharField(max_length=100)
    capacity = models.IntegerField()
    location = models.CharField(max_length=200)

    def __str__(self):
        return self.name

class Resource(models.Model):
    name = models.CharField(max_length=100) 
    total_quantity = models.IntegerField()

    def __str__(self):
        return self.name

# 3 Main EVENT  Module
class Event(models.Model):
    TYPE_CHOICES = (
        ('WORKSHOP', 'Workshop'),
        ('SEMINAR', 'Seminar'),
        ('CULTURAL', 'Cultural Fest'),
        ('SPORTS', 'Sports Event'),
        ('CLUB', 'Club Event'),
        ('EXAM', 'Exam Related'),
    )

    # Approval statuss
    STATUS_CHOICES = (
        ('DRAFT', 'Draft'),
        ('PENDING', 'Pending Approval'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected'),
        ('COMPLETED', 'Completed'),
    )

    title = models.CharField(max_length=200)
    description = models.TextField()
    event_type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='DRAFT')
    
    # for scheduling
    start_datetime = models.DateTimeField()
    end_datetime = models.DateTimeField()
    duration_minutes = models.IntegerField(help_text="Duration in minutes")
    
    #For Ownership and Coordination
    organizing_department = models.CharField(max_length=100)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_events')
    coordinators = models.ManyToManyField(User, related_name='coordinating_events', limit_choices_to={'role': 'TEACHER'})
    
    #for Logistics
    venue = models.ForeignKey(Venue, on_delete=models.SET_NULL, null=True)
    required_resources = models.ManyToManyField(Resource, through='EventResourceRequest')
    
    # for Registration Logic
    is_registration_required = models.BooleanField(default=True)
    registration_deadline = models.DateTimeField(null=True, blank=True)
    target_audience = models.CharField(max_length=50, choices=(('STUDENT', 'Students'), ('PARENT', 'Parents'), ('ALL', 'All')))

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.title} - {self.status}"

# table for handling resources quantities
class EventResourceRequest(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE)
    resource = models.ForeignKey(Resource, on_delete=models.CASCADE)
    quantity_needed = models.IntegerField(default=1)

# 4. ForRegistration and participation
class Registration(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='registrations')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    registered_at = models.DateTimeField(auto_now_add=True)
    attended = models.BooleanField(default=False) # To track actual participation

# 5 for Feedback
class Feedback(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='feedbacks')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    rating = models.IntegerField(choices=[(i, i) for i in range(1, 6)]) # students can rate from 1 to 5
    comments = models.TextField()
    submitted_at = models.DateTimeField(auto_now_add=True)

# 6. For Management to review event success
# 
class EventSuccessReport(models.Model):
    event = models.OneToOneField(Event, on_delete=models.CASCADE, related_name='success_report')
    total_registrations = models.IntegerField(default=0)
    actual_turnout = models.IntegerField(default=0)
    attendance_percentage = models.FloatField(help_text="Actual / Registered * 100")
    
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, null=True, help_text="Aggregated from Feedback table")

    success_summary = models.TextField(help_text="Auto-generated summary or Admin notes")

    generated_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Report for: {self.event.title}"