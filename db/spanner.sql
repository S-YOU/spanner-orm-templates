CREATE TABLE `users` (
  user_id              STRING(36) NOT NULL,
  name                 STRING(MAX) NOT NULL,
  status               INT64 NOT NULL,
  created_at           TIMESTAMP NOT NULL,
  updated_at           TIMESTAMP NOT NULL,
) PRIMARY KEY(user_id);
CREATE INDEX idx_users_name ON users(name);
CREATE INDEX idx_users_name_status ON users(name,status);

CREATE TABLE `groups` (
  group_id    STRING(36) NOT NULL,
  name        STRING(MAX) NOT NULL,
  created_at  TIMESTAMP NOT NULL,
  updated_at  TIMESTAMP NOT NULL,
) PRIMARY KEY(group_id);

CREATE TABLE `user_groups` (
  group_id    STRING(36) NOT NULL,
  user_id     STRING(36) NOT NULL,
  created_at  TIMESTAMP NOT NULL,
  updated_at  TIMESTAMP NOT NULL,
) PRIMARY KEY(group_id, user_id),
  INTERLEAVE IN PARENT `groups` ON DELETE NO ACTION;
CREATE UNIQUE INDEX idx_group_users_group_id ON user_groups(group_id);
CREATE INDEX idx_group_users_user_id ON user_groups(user_id);
