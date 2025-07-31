---
description: Learn how to use Roo Code's task todo list feature to track progress on complex tasks, manage subtasks, and stay organized.
keywords: todo list,task management,progress tracking,subtasks,project organization
image: /img/social-share.jpg
---

# Task Todo List


Keep your tasks on track with integrated todo management that helps you stay organized and focused on your development goals. Task Todo Lists provide interactive, persistent checklists that track your progress through complex, multi-step workflows directly within the chat interface.



Todo List TriggersTodo lists are automatically created for complex tasks, multi-step workflows, or when using Architect mode. You can also manually trigger them by asking Roo to "use the update_todo_list tool" or "create a todo list".

See When Roo Creates Todo Lists for detailed information about automatic and manual triggers.





## Use Case​


Before: Manually tracking steps for a complex task in your head or a separate notes file, making it easy to lose track of progress and next steps.


With Task Todo Lists: Roo Code automatically creates and manages a structured checklist embedded in the conversation. You can see the status of each item, watch as the AI marks items complete, and provide feedback when Roo presents updates for approval.



## How It Works​


The Task Todo List feature is powered by the update_todo_list tool, which enables dynamic task management within the chat interface.


### When Roo Creates Todo Lists​


Roo creates todo lists through both automatic detection and manual requests:


- Task complexity detected - Multiple steps, phases, or dependencies identified in your request
- Working in Architect mode - Always creates todo lists as the primary planning tool for structuring work
- Direct tool request - Say "use the update_todo_list tool" or "please use update_todo_list"


Remember: Even when manually triggered, Roo maintains control over the todo list content and workflow. You provide feedback during approval dialogs, but Roo manages the list based on task needs.


### Display and Interaction​


Todo lists appear in multiple places:


1. 
Task Header Summary: A compact, read-only display showing progress and the next important item via the TodoListDisplay component


2. 
Interactive Tool Block: An interface within the chat via the UpdateTodoListToolBlock component that allows you to:

View all todo items with their current status
Edit item descriptions when Roo presents updates for approval
Stage changes using the "Edit" button (applied only when Roo next updates the list)
View the progression as Roo manages the todo workflow



3. 
Environment Details: Todo lists appear as a "REMINDERS" table in the environment_details section, giving the AI persistent access to current todo state



### Understanding Task Status​


Roo Code automatically manages status progression based on task progress. Each todo item has one of three states:


Pending: Shows an empty checkbox, indicating the task hasn't been started yet



In Progress: Displays a yellow dot indicator, showing the task is currently being worked on



Completed: Features a green checkmark, confirming the task is fully finished




## FAQ​


"Can I create my own todo lists?"
Yes, you can manually trigger todo list creation by asking Roo to "use the update_todo_list tool" or "create a todo list". However, Roo maintains control over the todo list content and workflow - you provide feedback during approval dialogs, but Roo manages the list based on task needs.


"Can I use todo lists for simple tasks?"
Roo Code typically only creates todo lists for complex, multi-step tasks where they provide clear value. For simple tasks, the overhead of list management isn't necessary.


"Why can't I directly control the todo list?"
This is an architectural design decision where Roo Code maintains authority over task management. You provide guidance and feedback, but Roo controls the workflow to ensure consistent task progression and accurate status tracking.



## Auto-Approving Todo List Updates​


You can enable automatic approval of todo list updates to reduce interruptions during long workflows. When enabled, Roo will automatically update task progress without requiring confirmation for each change.


To configure this feature, see the Update Todo List auto-approval settings.