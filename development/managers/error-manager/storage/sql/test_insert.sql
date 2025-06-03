-- Test insertion into project_errors table
INSERT INTO project_errors (
    id, timestamp, message, stack_trace, module, error_code, manager_context, severity
) VALUES (
    '123e4567-e89b-12d3-a456-426614174000',
    NOW(),
    'Test error message',
    'Test stack trace',
    'test-module',
    'E001',
    '{"key": "value"}',
    'ERROR'
);

-- Verify the insertion
SELECT * FROM project_errors;
