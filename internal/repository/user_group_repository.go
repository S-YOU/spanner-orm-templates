package repository

type UserGroupRepository interface {
	UserGroupRepositoryIndexes
	UserGroupRepositoryIndexesCached
	UserGroupRepositoryCRUD
}
