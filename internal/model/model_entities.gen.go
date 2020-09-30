// Code generated by yo. DO NOT EDIT.
// Package model contains the types.
package model

import (
	"time"

	"github.com/s-you/yo-templates/internal/util"
)

// Group represents a row from 'groups'.
type Group struct {
	GroupID   string    `spanner:"group_id" json:"groupID"`
	Name      string    `spanner:"name" json:"name"`
	CreatedAt time.Time `spanner:"created_at" json:"createdAt"`
	UpdatedAt time.Time `spanner:"updated_at" json:"updatedAt"`
}

func (g *Group) SetIdentity() (err error) {
	if g.GroupID == "" {
		g.GroupID, err = util.NewUUID()
	}
	return
}

// User represents a row from 'users'.
type User struct {
	UserID    string    `spanner:"user_id" json:"userID"`
	Name      string    `spanner:"name" json:"name"`
	Status    int64     `spanner:"status" json:"status"`
	CreatedAt time.Time `spanner:"created_at" json:"createdAt"`
	UpdatedAt time.Time `spanner:"updated_at" json:"updatedAt"`
}

func (u *User) SetIdentity() (err error) {
	if u.UserID == "" {
		u.UserID, err = util.NewUUID()
	}
	return
}

// UserGroup represents a row from 'user_groups'.
type UserGroup struct {
	GroupID   string    `spanner:"group_id" json:"groupID"`
	UserID    string    `spanner:"user_id" json:"userID"`
	CreatedAt time.Time `spanner:"created_at" json:"createdAt"`
	UpdatedAt time.Time `spanner:"updated_at" json:"updatedAt"`
}

func (ug *UserGroup) SetIdentity() (err error) {
	return
}
