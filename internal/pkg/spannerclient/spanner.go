package spannerclient

import (
	"context"

	"cloud.google.com/go/spanner"
	"google.golang.org/api/option"

	"github.com/s-you/yo-templates/internal/config"
)

func Connect(ctx context.Context, db config.DB) (*spanner.Client, error) {
	spc := spanner.DefaultSessionPoolConfig
	spc.MaxOpened = uint64(db.Channels * db.SessionsPerChannel)
	cc := spanner.ClientConfig{SessionPoolConfig: spc}
	grpcOpts := option.WithGRPCConnectionPool(db.Channels)
	client, err := spanner.NewClientWithConfig(ctx, db.Format(), cc, grpcOpts)
	if err != nil {
		return nil, err
	}

	return client, nil
}
