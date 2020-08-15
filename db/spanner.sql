CREATE TABLE `users` (
  user_id              STRING(36) NOT NULL,
  name                 STRING(MAX) NOT NULL,
  status               INT64 NOT NULL,
  created_at           TIMESTAMP NOT NULL,
  updated_at           TIMESTAMP NOT NULL,
) PRIMARY KEY(user_id);
CREATE INDEX idx_users_name ON users(name);
