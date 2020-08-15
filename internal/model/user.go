package model

import (
	"time"

	"github.com/s-you/yo-templates/internal/util"
)

type User struct {
	UserID    string
	Name      string
	Status    int64
	CreatedAt time.Time
	UpdatedAt time.Time
}

func (u *User) SetIdentity() (err error) {
	if u.UserID == "" {
		u.UserID, err = util.NewUUID()
	}
	return nil
}
