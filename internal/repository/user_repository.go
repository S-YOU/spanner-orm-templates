package repository

type UserRepository interface {
	//ExampleQuery(ctx context.Context) error

	UserRepositoryIndexes
	UserRepositoryIndexesCached
	UserRepositoryCRUD
}

//func (u *userRepository) ExampleQuery(ctx context.Context) error {
//}
