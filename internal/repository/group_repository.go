package repository

type GroupRepository interface {
	GroupRepositoryIndexes
	GroupRepositoryIndexesCached
	GroupRepositoryCRUD
}
