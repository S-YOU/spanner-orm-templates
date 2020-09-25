package repository

type UserRepository interface {
	//ExampleQuery(ctx context.Context) error

	UserRepositoryIndexes
	UserRepositoryIndexesCached
	UserRepositoryCRUD
}
