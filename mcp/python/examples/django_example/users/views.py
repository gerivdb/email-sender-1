"""User views."""

from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.contrib.auth.models import User
from pymcpfy.django import mcpfy
from .serializers import UserSerializer


class UserViewSet(viewsets.ModelViewSet):
    """
    API endpoint for users.
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_permissions(self):
        """Allow unauthenticated access to register."""
        if self.action == 'create':
            return [permissions.AllowAny()]
        return super().get_permissions()

    @mcpfy()
    def create(self, request):
        """
        Create a new user with profile.
        
        :param username: Username for the new user
        :param email: Email address
        :param password: Password
        :param first_name: First name (optional)
        :param last_name: Last name (optional)
        :param profile: Profile data (optional)
            - bio: User bio
            - location: User location
            - birth_date: Birth date (YYYY-MM-DD)
            - avatar: Avatar URL
        :return: Created user data
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(self.get_serializer(user).data)

    @mcpfy()
    def list(self, request):
        """
        List all users.
        
        :return: List of users
        """
        return super().list(request)

    @mcpfy()
    def retrieve(self, request, pk=None):
        """
        Get a specific user by ID.
        
        :param pk: User ID
        :return: User data
        """
        return super().retrieve(request, pk=pk)

    @mcpfy()
    def update(self, request, pk=None):
        """
        Update a user.
        
        :param pk: User ID
        :param username: New username (optional)
        :param email: New email (optional)
        :param password: New password (optional)
        :param first_name: New first name (optional)
        :param last_name: New last name (optional)
        :param profile: Profile data (optional)
            - bio: User bio
            - location: User location
            - birth_date: Birth date (YYYY-MM-DD)
            - avatar: Avatar URL
        :return: Updated user data
        """
        return super().update(request, pk=pk)

    @mcpfy()
    def destroy(self, request, pk=None):
        """
        Delete a user.
        
        :param pk: User ID to delete
        :return: Success message
        """
        return super().destroy(request, pk=pk)

    @action(detail=True, methods=['get'])
    @mcpfy()
    def profile(self, request, pk=None):
        """
        Get user's profile.
        
        :param pk: User ID
        :return: User profile data
        """
        user = self.get_object()
        serializer = self.get_serializer(user)
        return Response(serializer.data.get('profile', {}))
