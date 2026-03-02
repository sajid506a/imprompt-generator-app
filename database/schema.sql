
CREATE TABLE workspaces(
 id SERIAL PRIMARY KEY,
 name TEXT
);

CREATE TABLE users(
 id SERIAL PRIMARY KEY,
 email TEXT,
 workspace_id INT REFERENCES workspaces(id)
);

CREATE TABLE usage_logs(
 id SERIAL PRIMARY KEY,
 user_id INT,
 tokens INT
);
