package repository

type UserRepository interface {
	//ExampleQuery(ctx context.Context) error

	UserRepositoryIndexes
	UserRepositoryCRUD
}

//func (u *userRepository) ExampleQuery(ctx context.Context) error {
//}
