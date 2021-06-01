package config

import (
	"fmt"
)

type DB struct {
	Project            string `envconfig:"GOOGLE_CLOUD_PROJECT"`
	Instance           string `envconfig:"DB_SPANNER_INSTANCE"`
	Database           string `envconfig:"DB_SPANNER_DATABASE"`
	Channels           int    `default:"4" split_words:"true"`
	SessionsPerChannel int    `default:"100" split_words:"true"`
	Debug              bool   `default:"false"`
	Stats              bool   `default:"false"`
}

func (c DB) Format() string {
	return fmt.Sprintf("projects/%s/instances/%s/databases/%s", c.Project, c.Instance, c.Database)
}
