package config

import (
	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	DB DB
}

func Load() (*Config, error) {
	conf := &Config{}
	if err := envconfig.Process("", conf); err != nil {
		return nil, err
	}
	return conf, nil
}
