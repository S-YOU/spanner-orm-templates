package main

import (
	"context"
	"fmt"
	"log"

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
	users, err := u.FindAll(ctx)
	if err != nil {
		log.Fatal(err)
	}
	for _, x := range users {
		fmt.Println("FindAll", x)
	}

	//if err := u.ExampleQuery(ctx); err != nil {
	//	log.Fatal(err)
	//}
}
