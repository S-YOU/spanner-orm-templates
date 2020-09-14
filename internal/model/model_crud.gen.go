// Code generated by yo. DO NOT EDIT.
// Package model contains the types.
package model

import (
	"context"
	"fmt"
	"time"

	"cloud.google.com/go/spanner"
)

// Insert returns a Mutation to insert a row into a table. If the row already
// exists, the write or transaction fails.
func (g *Group) Insert(ctx context.Context) *spanner.Mutation {
	g.CreatedAt = time.Now()
	g.UpdatedAt = time.Now()
	return spanner.Insert("groups", GroupColumns(), []interface{}{
		g.GroupID, g.Name, g.CreatedAt, g.UpdatedAt,
	})
}

// Update returns a Mutation to update a row in a table. If the row does not
// already exist, the write or transaction fails.
func (g *Group) Update(ctx context.Context) *spanner.Mutation {
	g.UpdatedAt = time.Now()
	return spanner.Update("groups", GroupColumns(), []interface{}{
		g.GroupID, g.Name, g.CreatedAt, g.UpdatedAt,
	})
}

// UpdateMap returns a Mutation to update a row in a table. If the row does not
// already exist, the write or transaction fails.
func (g *Group) UpdateMap(ctx context.Context, groupMap map[string]interface{}) *spanner.Mutation {
	groupMap["updated_at"] = time.Now()
	// add primary keys to columns to update by primary keys
	groupMap["group_id"] = g.GroupID
	return spanner.UpdateMap("groups", groupMap)
}

// InsertOrUpdate returns a Mutation to insert a row into a table. If the row
// already exists, it updates it instead. Any column values not explicitly
// written are preserved.
func (g *Group) InsertOrUpdate(ctx context.Context) *spanner.Mutation {
	if g.CreatedAt.IsZero() {
		g.CreatedAt = time.Now()
	}
	g.UpdatedAt = time.Now()
	return spanner.InsertOrUpdate("groups", GroupColumns(), []interface{}{
		g.GroupID, g.Name, g.CreatedAt, g.UpdatedAt,
	})
}

// UpdateColumns returns a Mutation to update specified columns of a row in a table.
func (g *Group) UpdateColumns(ctx context.Context, cols ...string) (*spanner.Mutation, error) {
	g.UpdatedAt = time.Now()
	cols = append(cols, "updated_at")
	// add primary keys to columns to update by primary keys
	colsWithPKeys := append(cols, GroupPrimaryKeys()...)

	values, err := g.columnsToValues(colsWithPKeys)
	if err != nil {
		return nil, fmt.Errorf("invalid argument: Group.UpdateColumns groups: %w", err)
	}

	return spanner.Update("groups", colsWithPKeys, values), nil
}

// Delete deletes the Group from the database.
func (g *Group) Delete(ctx context.Context) *spanner.Mutation {
	values, _ := g.columnsToValues(GroupPrimaryKeys())
	return spanner.Delete("groups", spanner.Key(values))
}

// Insert returns a Mutation to insert a row into a table. If the row already
// exists, the write or transaction fails.
func (u *User) Insert(ctx context.Context) *spanner.Mutation {
	u.CreatedAt = time.Now()
	u.UpdatedAt = time.Now()
	return spanner.Insert("users", UserColumns(), []interface{}{
		u.UserID, u.Name, u.Status, u.CreatedAt, u.UpdatedAt,
	})
}

// Update returns a Mutation to update a row in a table. If the row does not
// already exist, the write or transaction fails.
func (u *User) Update(ctx context.Context) *spanner.Mutation {
	u.UpdatedAt = time.Now()
	return spanner.Update("users", UserColumns(), []interface{}{
		u.UserID, u.Name, u.Status, u.CreatedAt, u.UpdatedAt,
	})
}

// UpdateMap returns a Mutation to update a row in a table. If the row does not
// already exist, the write or transaction fails.
func (u *User) UpdateMap(ctx context.Context, userMap map[string]interface{}) *spanner.Mutation {
	userMap["updated_at"] = time.Now()
	// add primary keys to columns to update by primary keys
	userMap["user_id"] = u.UserID
	return spanner.UpdateMap("users", userMap)
}

// InsertOrUpdate returns a Mutation to insert a row into a table. If the row
// already exists, it updates it instead. Any column values not explicitly
// written are preserved.
func (u *User) InsertOrUpdate(ctx context.Context) *spanner.Mutation {
	if u.CreatedAt.IsZero() {
		u.CreatedAt = time.Now()
	}
	u.UpdatedAt = time.Now()
	return spanner.InsertOrUpdate("users", UserColumns(), []interface{}{
		u.UserID, u.Name, u.Status, u.CreatedAt, u.UpdatedAt,
	})
}

// UpdateColumns returns a Mutation to update specified columns of a row in a table.
func (u *User) UpdateColumns(ctx context.Context, cols ...string) (*spanner.Mutation, error) {
	u.UpdatedAt = time.Now()
	cols = append(cols, "updated_at")
	// add primary keys to columns to update by primary keys
	colsWithPKeys := append(cols, UserPrimaryKeys()...)

	values, err := u.columnsToValues(colsWithPKeys)
	if err != nil {
		return nil, fmt.Errorf("invalid argument: User.UpdateColumns users: %w", err)
	}

	return spanner.Update("users", colsWithPKeys, values), nil
}

// Delete deletes the User from the database.
func (u *User) Delete(ctx context.Context) *spanner.Mutation {
	values, _ := u.columnsToValues(UserPrimaryKeys())
	return spanner.Delete("users", spanner.Key(values))
}

// Insert returns a Mutation to insert a row into a table. If the row already
// exists, the write or transaction fails.
func (ug *UserGroup) Insert(ctx context.Context) *spanner.Mutation {
	ug.CreatedAt = time.Now()
	ug.UpdatedAt = time.Now()
	return spanner.Insert("user_groups", UserGroupColumns(), []interface{}{
		ug.GroupID, ug.UserID, ug.CreatedAt, ug.UpdatedAt,
	})
}

// Update returns a Mutation to update a row in a table. If the row does not
// already exist, the write or transaction fails.
func (ug *UserGroup) Update(ctx context.Context) *spanner.Mutation {
	ug.UpdatedAt = time.Now()
	return spanner.Update("user_groups", UserGroupColumns(), []interface{}{
		ug.GroupID, ug.UserID, ug.CreatedAt, ug.UpdatedAt,
	})
}

// UpdateMap returns a Mutation to update a row in a table. If the row does not
// already exist, the write or transaction fails.
func (ug *UserGroup) UpdateMap(ctx context.Context, usergroupMap map[string]interface{}) *spanner.Mutation {
	usergroupMap["updated_at"] = time.Now()
	// add primary keys to columns to update by primary keys
	usergroupMap["group_id"] = ug.GroupID
	usergroupMap["user_id"] = ug.UserID
	return spanner.UpdateMap("user_groups", usergroupMap)
}

// InsertOrUpdate returns a Mutation to insert a row into a table. If the row
// already exists, it updates it instead. Any column values not explicitly
// written are preserved.
func (ug *UserGroup) InsertOrUpdate(ctx context.Context) *spanner.Mutation {
	if ug.CreatedAt.IsZero() {
		ug.CreatedAt = time.Now()
	}
	ug.UpdatedAt = time.Now()
	return spanner.InsertOrUpdate("user_groups", UserGroupColumns(), []interface{}{
		ug.GroupID, ug.UserID, ug.CreatedAt, ug.UpdatedAt,
	})
}

// UpdateColumns returns a Mutation to update specified columns of a row in a table.
func (ug *UserGroup) UpdateColumns(ctx context.Context, cols ...string) (*spanner.Mutation, error) {
	ug.UpdatedAt = time.Now()
	cols = append(cols, "updated_at")
	// add primary keys to columns to update by primary keys
	colsWithPKeys := append(cols, UserGroupPrimaryKeys()...)

	values, err := ug.columnsToValues(colsWithPKeys)
	if err != nil {
		return nil, fmt.Errorf("invalid argument: UserGroup.UpdateColumns user_groups: %w", err)
	}

	return spanner.Update("user_groups", colsWithPKeys, values), nil
}

// Delete deletes the UserGroup from the database.
func (ug *UserGroup) Delete(ctx context.Context) *spanner.Mutation {
	values, _ := ug.columnsToValues(UserGroupPrimaryKeys())
	return spanner.Delete("user_groups", spanner.Key(values))
}
