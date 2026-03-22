-- Create medusa database if it doesn't exist
SELECT 'CREATE DATABASE "medusa"'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'medusa')\gexec

-- Create cms database if it doesn't exist
SELECT 'CREATE DATABASE "cms"'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'cms')\gexec
