// Code generated by yo. DO NOT EDIT.
package repository

import (
	"context"

	"github.com/s-you/yo-templates/internal/model"
)

type GroupRepositoryIndexes interface {
	GetGroupByGroupID(ctx context.Context, groupID string) (*model.Group, error)
	FindGroupsByGroupIDs(ctx context.Context, groupIDs []string) ([]*model.Group, error)
}

// GetGroupByGroupID retrieves a row from 'groups' as a Group.
// Generated from primary key. This is a fast method that can retrieve all columns
func (g groupRepository) GetGroupByGroupID(ctx context.Context, groupID string) (*model.Group, error) {
	group := &model.Group{}
	if err := g.Read(ctx, Key{groupID}).Into(group); err != nil {
		return nil, err
	}

	return group, nil
}

// FindGroupsByGroupIDs retrieves multiple rows from 'groups' as []*model.Group.
// Generated from primary key
func (g groupRepository) FindGroupsByGroupIDs(ctx context.Context, groupIDs []string) ([]*model.Group, error) {
	var items []*model.Group
	if err := g.Builder().Where("group_id IN UNNEST(@arg0)", Params{"arg0": groupIDs}).Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

type UserRepositoryIndexes interface {
	GetUserByUserID(ctx context.Context, userID string) (*model.User, error)
	FindUsersByUserIDs(ctx context.Context, userIDs []string) ([]*model.User, error)
	FindUsersByName(ctx context.Context, name string) ([]*model.User, error)
	FindUsersByNameFast(ctx context.Context, name string) ([]*model.User, error)
	FindUsersByNames(ctx context.Context, names []string) ([]*model.User, error)
	FindUsersByNameAndStatus(ctx context.Context, name string, status int64) ([]*model.User, error)
	FindUsersByNameAndStatusFast(ctx context.Context, name string, status int64) ([]*model.User, error)
	FindUsersByNamesAndStatuses(ctx context.Context, names []string, statuses []int64) ([]*model.User, error)
}

// GetUserByUserID retrieves a row from 'users' as a User.
// Generated from primary key. This is a fast method that can retrieve all columns
func (u userRepository) GetUserByUserID(ctx context.Context, userID string) (*model.User, error) {
	user := &model.User{}
	if err := u.Read(ctx, Key{userID}).Into(user); err != nil {
		return nil, err
	}

	return user, nil
}

// FindUsersByUserIDs retrieves multiple rows from 'users' as []*model.User.
// Generated from primary key
func (u userRepository) FindUsersByUserIDs(ctx context.Context, userIDs []string) ([]*model.User, error) {
	var items []*model.User
	if err := u.Builder().Where("user_id IN UNNEST(@arg0)", Params{"arg0": userIDs}).Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

type UserGroupRepositoryIndexes interface {
	GetUserGroupByGroupIDAndUserID(ctx context.Context, groupID string, userID string) (*model.UserGroup, error)
	FindUserGroupsByGroupIDsAndUserIDs(ctx context.Context, groupIDs []string, userIDs []string) ([]*model.UserGroup, error)
	FindUserGroupsByGroupIDs(ctx context.Context, groupIDs []string) ([]*model.UserGroup, error)
	FindUserGroupsByUserIDs(ctx context.Context, userIDs []string) ([]*model.UserGroup, error)
	GetUserGroupByGroupID(ctx context.Context, groupID string) (*model.UserGroup, error)
	GetUserGroupByGroupIDFast(ctx context.Context, groupID string) (*model.UserGroup, error)
	FindUserGroupsByGroupIDs(ctx context.Context, groupIDs []string) ([]*model.UserGroup, error)
	FindUserGroupsByUserID(ctx context.Context, userID string) ([]*model.UserGroup, error)
	FindUserGroupsByUserIDFast(ctx context.Context, userID string) ([]*model.UserGroup, error)
	FindUserGroupsByUserIDs(ctx context.Context, userIDs []string) ([]*model.UserGroup, error)
}

// GetUserGroupByGroupIDAndUserID retrieves a row from 'user_groups' as a UserGroup.
// Generated from primary key. This is a fast method that can retrieve all columns
func (ug userGroupRepository) GetUserGroupByGroupIDAndUserID(ctx context.Context, groupID string, userID string) (*model.UserGroup, error) {
	userGroup := &model.UserGroup{}
	if err := ug.Read(ctx, Key{groupID, userID}).Into(userGroup); err != nil {
		return nil, err
	}

	return userGroup, nil
}

// FindUserGroupsByGroupIDsAndUserIDs retrieves multiple rows from 'user_groups' as []*model.UserGroup.
// Generated from primary key
func (ug userGroupRepository) FindUserGroupsByGroupIDsAndUserIDs(ctx context.Context, groupIDs []string, userIDs []string) ([]*model.UserGroup, error) {
	var items []*model.UserGroup
	if err := ug.Builder().Where("group_id IN UNNEST(@arg0) AND user_id IN UNNEST(@arg1)", Params{"arg0": groupIDs, "arg1": userIDs}).Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

// FindUserGroupsByGroupIDs retrieves multiple rows from 'user_groups' as []*model.UserGroup.
// Generated from part of primary key
func (ug userGroupRepository) FindUserGroupsByGroupIDs(ctx context.Context, groupIDs []string) ([]*model.UserGroup, error) {
	var items []*model.UserGroup
	if err := ug.Builder().Where("group_id IN UNNEST(@arg0)", Params{"arg0": groupIDs}).Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

// FindUserGroupsByUserIDs retrieves multiple rows from 'user_groups' as []*model.UserGroup.
// Generated from part of primary key
func (ug userGroupRepository) FindUserGroupsByUserIDs(ctx context.Context, userIDs []string) ([]*model.UserGroup, error) {
	var items []*model.UserGroup
	if err := ug.Builder().Where("user_id IN UNNEST(@arg0)", Params{"arg0": userIDs}).Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

// FindUsersByNameFast retrieves multiple rows from 'users' as a slice of User.
// Generated from index 'idx_users_name'. This retrieves only primary key, index key and storing columns
func (u userRepository) FindUsersByNameFast(ctx context.Context, name string) ([]*model.User, error) {
	user := []*model.User{}
	if err := u.ReadUsingIndex(ctx, "idx_users_name", Key{name}).Intos(&user); err != nil {
		return nil, err
	}

	return user, nil
}

// FindUsersByName retrieves multiple rows from 'users' as a slice of User.
// Generated from index 'idx_users_name'.
func (u userRepository) FindUsersByName(ctx context.Context, name string) ([]*model.User, error) {
	user := []*model.User{}
	if err := u.Builder().Where("name = @param0", Params{"param0": name}).Query(ctx).Intos(&user); err != nil {
		return nil, err
	}

	return user, nil
}

// FindUsersByNames retrieves multiple rows from 'users' as []*model.User.
// Generated from index 'idx_users_name'.
func (u userRepository) FindUsersByNames(ctx context.Context, names []string) ([]*model.User, error) {
	var items []*model.User
	if err := u.Builder().Where("name IN UNNEST(@arg0)", Params{"arg0": names}).Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

// FindUsersByNameAndStatusFast retrieves multiple rows from 'users' as a slice of User.
// Generated from index 'idx_users_name_status'. This retrieves only primary key, index key and storing columns
func (u userRepository) FindUsersByNameAndStatusFast(ctx context.Context, name string, status int64) ([]*model.User, error) {
	user := []*model.User{}
	if err := u.ReadUsingIndex(ctx, "idx_users_name_status", Key{name, status}).Intos(&user); err != nil {
		return nil, err
	}

	return user, nil
}

// FindUsersByNameAndStatus retrieves multiple rows from 'users' as a slice of User.
// Generated from index 'idx_users_name_status'.
func (u userRepository) FindUsersByNameAndStatus(ctx context.Context, name string, status int64) ([]*model.User, error) {
	user := []*model.User{}
	if err := u.Builder().Where("name = @param0 AND status = @param1", Params{"param0": name, "param1": status}).Query(ctx).Intos(&user); err != nil {
		return nil, err
	}

	return user, nil
}

// FindUsersByNamesAndStatuses retrieves multiple rows from 'users' as []*model.User.
// Generated from index 'idx_users_name_status'.
func (u userRepository) FindUsersByNamesAndStatuses(ctx context.Context, names []string, statuses []int64) ([]*model.User, error) {
	var items []*model.User
	if err := u.Builder().Where("name IN UNNEST(@arg0) AND status IN UNNEST(@arg1)", Params{"arg0": names, "arg1": statuses}).Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

// GetUserGroupByGroupID retrieves a row from 'user_groups' as a UserGroup.
// Generated from unique index 'idx_group_users_group_id'.
func (ug userGroupRepository) GetUserGroupByGroupID(ctx context.Context, groupID string) (*model.UserGroup, error) {
	userGroup := &model.UserGroup{}
	if err := ug.Builder().Where("group_id = @param0", Params{"param0": groupID}).Query(ctx).Into(userGroup); err != nil {
		return nil, err
	}

	return userGroup, nil
}

// GetUserGroupByGroupIDFast retrieves a row from 'user_groups' as a UserGroup.
// Generated from unique index 'idx_group_users_group_id'. This retrieves only primary key, index key and storing columns
func (ug userGroupRepository) GetUserGroupByGroupIDFast(ctx context.Context, groupID string) (*model.UserGroup, error) {
	userGroup := &model.UserGroup{}
	if err := ug.ReadUsingIndex(ctx, "idx_group_users_group_id", Key{groupID}).Into(userGroup); err != nil {
		return nil, err
	}

	return userGroup, nil
}

// FindUserGroupsByGroupIDs retrieves multiple rows from 'user_groups' as []*model.UserGroup.
// Generated from index 'idx_group_users_group_id'.
func (ug userGroupRepository) FindUserGroupsByGroupIDs(ctx context.Context, groupIDs []string) ([]*model.UserGroup, error) {
	var items []*model.UserGroup
	if err := ug.Builder().Where("group_id IN UNNEST(@arg0)", Params{"arg0": groupIDs}).Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

// FindUserGroupsByUserIDFast retrieves multiple rows from 'user_groups' as a slice of UserGroup.
// Generated from index 'idx_group_users_user_id'. This retrieves only primary key, index key and storing columns
func (ug userGroupRepository) FindUserGroupsByUserIDFast(ctx context.Context, userID string) ([]*model.UserGroup, error) {
	userGroup := []*model.UserGroup{}
	if err := ug.ReadUsingIndex(ctx, "idx_group_users_user_id", Key{userID}).Intos(&userGroup); err != nil {
		return nil, err
	}

	return userGroup, nil
}

// FindUserGroupsByUserID retrieves multiple rows from 'user_groups' as a slice of UserGroup.
// Generated from index 'idx_group_users_user_id'.
func (ug userGroupRepository) FindUserGroupsByUserID(ctx context.Context, userID string) ([]*model.UserGroup, error) {
	userGroup := []*model.UserGroup{}
	if err := ug.Builder().Where("user_id = @param0", Params{"param0": userID}).Query(ctx).Intos(&userGroup); err != nil {
		return nil, err
	}

	return userGroup, nil
}

// FindUserGroupsByUserIDs retrieves multiple rows from 'user_groups' as []*model.UserGroup.
// Generated from index 'idx_group_users_user_id'.
func (ug userGroupRepository) FindUserGroupsByUserIDs(ctx context.Context, userIDs []string) ([]*model.UserGroup, error) {
	var items []*model.UserGroup
	if err := ug.Builder().Where("user_id IN UNNEST(@arg0)", Params{"arg0": userIDs}).Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}
