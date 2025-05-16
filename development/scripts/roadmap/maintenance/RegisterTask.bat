@echo off
schtasks /create /tn "ArchiveRoadmapTasks" /xml "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\roadmap\ArchiveTask.xml" /f
