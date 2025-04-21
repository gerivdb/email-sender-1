"""
Flask Example: Todo List API with MCP Integration
"""

from datetime import datetime
from typing import List, Optional
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import (
    JWTManager, jwt_required, create_access_token,
    get_jwt_identity
)
from dataclasses import dataclass
from pymcpfy.flask import mcpfy

# Initialize Flask app
app = Flask(__name__)

# Configuration
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///todos.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = 'your-secret-key'  # Change in production

# Initialize extensions
db = SQLAlchemy(app)
jwt = JWTManager(app)

# Models
@dataclass
class User(db.Model):
    id: int
    username: str
    email: str

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(120), nullable=False)
    todos = db.relationship('Todo', backref='user', lazy=True)

@dataclass
class Todo(db.Model):
    id: int
    title: str
    description: str
    done: bool
    due_date: datetime
    created_at: datetime

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    done = db.Column(db.Boolean, default=False)
    due_date = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)

# Routes
@app.route('/login', methods=['POST'])
@mcpfy()
def login():
    """Login to get access token.
    
    :param username: User's username
    :param password: User's password
    :return: Access token
    """
    username = request.json.get('username')
    password = request.json.get('password')
    
    user = User.query.filter_by(username=username).first()
    if not user or user.password != password:  # Use proper password hashing in production
        return jsonify({"error": "Invalid credentials"}), 401
    
    access_token = create_access_token(identity=username)
    return jsonify({"access_token": access_token})

@app.route('/todos', methods=['GET'])
@jwt_required()
@mcpfy()
def get_todos():
    """Get all todos for the current user.
    
    :return: List of todos
    """
    current_user = User.query.filter_by(username=get_jwt_identity()).first()
    return jsonify(current_user.todos)

@app.route('/todos', methods=['POST'])
@jwt_required()
@mcpfy()
def create_todo():
    """Create a new todo.
    
    :param title: Todo title
    :param description: Todo description
    :param due_date: Due date (optional)
    :return: Created todo
    """
    current_user = User.query.filter_by(username=get_jwt_identity()).first()
    
    data = request.json
    todo = Todo(
        title=data['title'],
        description=data.get('description'),
        due_date=datetime.fromisoformat(data['due_date']) if data.get('due_date') else None,
        user_id=current_user.id
    )
    
    db.session.add(todo)
    db.session.commit()
    
    return jsonify(todo)

@app.route('/todos/<int:todo_id>', methods=['PUT'])
@jwt_required()
@mcpfy()
def update_todo(todo_id: int):
    """Update a todo.
    
    :param todo_id: ID of the todo to update
    :param title: New title (optional)
    :param description: New description (optional)
    :param done: New done status (optional)
    :param due_date: New due date (optional)
    :return: Updated todo
    """
    current_user = User.query.filter_by(username=get_jwt_identity()).first()
    todo = Todo.query.filter_by(id=todo_id, user_id=current_user.id).first()
    
    if not todo:
        return jsonify({"error": "Todo not found"}), 404
    
    data = request.json
    if 'title' in data:
        todo.title = data['title']
    if 'description' in data:
        todo.description = data['description']
    if 'done' in data:
        todo.done = data['done']
    if 'due_date' in data:
        todo.due_date = datetime.fromisoformat(data['due_date'])
    
    db.session.commit()
    return jsonify(todo)

@app.route('/todos/<int:todo_id>', methods=['DELETE'])
@jwt_required()
@mcpfy()
def delete_todo(todo_id: int):
    """Delete a todo.
    
    :param todo_id: ID of the todo to delete
    :return: Success message
    """
    current_user = User.query.filter_by(username=get_jwt_identity()).first()
    todo = Todo.query.filter_by(id=todo_id, user_id=current_user.id).first()
    
    if not todo:
        return jsonify({"error": "Todo not found"}), 404
    
    db.session.delete(todo)
    db.session.commit()
    
    return jsonify({"message": "Todo deleted"})

# Create database tables
with app.app_context():
    db.create_all()
    
    # Create demo user if not exists
    if not User.query.filter_by(username="demo").first():
        demo_user = User(
            username="demo",
            email="demo@example.com",
            password="demo123"  # Use proper password hashing in production
        )
        db.session.add(demo_user)
        db.session.commit()

if __name__ == '__main__':
    app.run(debug=True)
