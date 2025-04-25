"""User serializers."""

from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Profile


class ProfileSerializer(serializers.ModelSerializer):
    """Profile serializer."""
    
    class Meta:
        model = Profile
        fields = ('bio', 'location', 'birth_date', 'avatar', 'created_at', 'updated_at')


class UserSerializer(serializers.ModelSerializer):
    """User serializer with nested profile."""
    
    profile = ProfileSerializer()
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'password', 'profile')
        read_only_fields = ('id',)

    def create(self, validated_data):
        """Create a new user with nested profile."""
        profile_data = validated_data.pop('profile', {})
        password = validated_data.pop('password')
        
        user = User.objects.create(**validated_data)
        user.set_password(password)
        user.save()
        
        # Profile is created via signal, just update it
        for attr, value in profile_data.items():
            setattr(user.profile, attr, value)
        user.profile.save()
        
        return user

    def update(self, instance, validated_data):
        """Update user and nested profile."""
        profile_data = validated_data.pop('profile', {})
        password = validated_data.pop('password', None)
        
        # Update User fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        if password:
            instance.set_password(password)
        
        instance.save()
        
        # Update Profile fields
        for attr, value in profile_data.items():
            setattr(instance.profile, attr, value)
        instance.profile.save()
        
        return instance
