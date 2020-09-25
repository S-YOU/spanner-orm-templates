package main

import (
	"context"
	"fmt"

	"github.com/s-you/yo-templates/internal/config"
	"github.com/s-you/yo-templates/internal/pkg/spannerclient"
	"github.com/s-you/yo-templates/internal/repository"
)

func main() {
	conf, err := config.Load()
	if err != nil {
		panic(err)
	}

	ctx := context.Background()

	sdb, err := spannerclient.Connect(ctx, conf.DB)
	if err != nil {
		panic(err)
	}
	defer sdb.Close()

	u := repository.NewUserRepository(sdb)
	if items, err := u.FindAll(ctx); err == nil {
		for _, x := range items {
			fmt.Println("User.FindAll", x)
		}
	}

	g := repository.NewGroupRepository(sdb)
	if items, err := g.FindAll(ctx); err == nil {
		for _, x := range items {
			fmt.Println("Group.FindAll", x)
		}
	}

	ug := repository.NewUserGroupRepository(sdb)
	if items, err := ug.FindAll(ctx); err == nil {
		for _, x := range items {
			fmt.Println("UserGroup.FindAll", x)
		}
	}

	//if err := u.ExampleQuery(ctx); err != nil {
	//	log.Fatal(err)
	//}
}
