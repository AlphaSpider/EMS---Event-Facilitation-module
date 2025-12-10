from django.contrib import admin
from .models import User, Venue, Resource, Event, Registration, Feedback, EventSuccessReport

# Register your models 
admin.site.register(User)
admin.site.register(Venue)
admin.site.register(Resource)
admin.site.register(Event)
admin.site.register(Registration)
admin.site.register(Feedback)
admin.site.register(EventSuccessReport)