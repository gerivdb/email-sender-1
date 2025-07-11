-- Schéma SQL pour Event Bus
CREATE TABLE events (
  id VARCHAR(64) PRIMARY KEY,
  type VARCHAR(64),
  payload TEXT
);
CREATE TABLE managers (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(128),
  type VARCHAR(64)
);
CREATE TABLE hooks (
  id VARCHAR(64) PRIMARY KEY,
  manager_id VARCHAR(64),
  event_type VARCHAR(64),
  script TEXT,
  FOREIGN KEY (manager_id) REFERENCES managers(id)
);
CREATE TABLE logs (
  id VARCHAR(64) PRIMARY KEY,
  event_id VARCHAR(64),
  timestamp TIMESTAMP,
  message TEXT,
  FOREIGN KEY (event_id) REFERENCES events(id)
);
CREATE TABLE audits (
  id VARCHAR(64) PRIMARY KEY,
  event_id VARCHAR(64),
  status VARCHAR(32),
  details TEXT,
  FOREIGN KEY (event_id) REFERENCES events(id)
);
