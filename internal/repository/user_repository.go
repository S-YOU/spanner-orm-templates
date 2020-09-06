package repository

type UserRepository interface {
	//ExampleQuery(ctx context.Context) error

	UserRepositoryIndexes
	UserRepositoryCrud
}

//func (u *userRepository) ExampleQuery(ctx context.Context) error {
//}
