// Code generated by yo. DO NOT EDIT.
package repository

import (
	"bytes"
	"context"
	"encoding/binary"
	"encoding/gob"
	"errors"
	"fmt"
	"reflect"
	"time"

	"cloud.google.com/go/spanner"
	"google.golang.org/api/iterator"

	"github.com/cespare/xxhash"
	"github.com/s-you/apierrors"
	"github.com/s-you/spannerbuilder"
	"github.com/s-you/yo-templates/internal/middleware"
	"github.com/s-you/yo-templates/internal/model"
)

type Repository struct {
	client *spanner.Client
}

type Params = map[string]interface{}

type Decodable interface {
	ColumnsToPtrs([]string) ([]interface{}, error)
}

var (
	ErrNotFound = errors.New("NotFound")
)

func getCacheKey(stmt spanner.Statement) (string, error) {
	sum64 := xxhash.Sum64String(stmt.SQL)
	buf := new(bytes.Buffer)
	cacheKey := make([]byte, 8)
	binary.LittleEndian.PutUint64(cacheKey, sum64)
	buf.Write(cacheKey)
	e := gob.NewEncoder(buf)
	err := e.Encode(stmt.Params)
	if err != nil {
		return "", err
	}
	return buf.String(), nil
}

func intoDecodable(iter *spanner.RowIterator, cols []string, into Decodable) error {
	defer iter.Stop()

	row, err := iter.Next()
	if err != nil {
		if err == iterator.Done {
			return ErrNotFound
		}
		return fmt.Errorf("intoDecodable.iter: %w", err)
	}

	if err := DecodeInto(cols, row, into); err != nil {
		return fmt.Errorf("intoDecodable.DecodeInto: %w", err)
	}

	return nil
}

func intosDecodable(iter *spanner.RowIterator, cols []string, intos interface{}) error {
	defer iter.Stop()

	if reflect.TypeOf(intos).Kind() != reflect.Ptr {
		return fmt.Errorf("intosDecodable: argument is not pointer")
	}
	value := reflect.ValueOf(intos)
	elem := value.Elem()
	elemType := reflect.MakeSlice(elem.Type(), 1, 1).Index(0).Type()
	isPtr := false
	if elemType.Kind() == reflect.Ptr {
		elemType = elemType.Elem()
		isPtr = true
	}

	for {
		row, err := iter.Next()
		if err != nil {
			if err == iterator.Done {
				break
			}
			return fmt.Errorf("intosDecodable.iter: %w", err)
		}

		g := reflect.New(elemType)
		if into, ok := g.Interface().(Decodable); ok {
			err = DecodeInto(cols, row, into)
			if err != nil {
				return fmt.Errorf("intosDecodable.DecodeInto: %w", err)
			}

			if isPtr {
				elem = reflect.Append(elem, g)
			} else {
				elem = reflect.Append(elem, g.Elem())
			}
			value.Elem().Set(elem)
		} else {
			return fmt.Errorf("intosDecodable: not Decodable")
		}
	}

	return nil
}

func intoAny(iter *spanner.RowIterator, cols []string, into interface{}) error {
	defer iter.Stop()
	if reflect.TypeOf(into).Kind() != reflect.Ptr {
		return fmt.Errorf("intoAny: argument is not pointer")
	}
	if len(cols) != 1 {
		return fmt.Errorf("intoAny: multiple column not supported, use .Into instead")
	}
	value := reflect.ValueOf(into)

	row, err := iter.Next()
	if err != nil {
		if err == iterator.Done {
			return ErrNotFound
		}
		return fmt.Errorf("intoAny.iter: %w", err)
	}

	g := reflect.New(value.Elem().Type())
	err = row.Column(0, g.Interface())
	if err != nil {
		return fmt.Errorf("intoAny.Column: %w", err)
	}
	value.Elem().Set(g.Elem())

	return nil
}

func intosAnySlice(iter *spanner.RowIterator, cols []string, into interface{}) error {
	defer iter.Stop()
	if reflect.TypeOf(into).Kind() != reflect.Ptr {
		return fmt.Errorf("intosAnySlice: argument is not pointer")
	}
	if len(cols) != 1 {
		return fmt.Errorf("intosAnySlice: multiple column not supported, use .Intos instead")
	}
	value := reflect.ValueOf(into)
	elem := value.Elem()
	elemType := reflect.MakeSlice(elem.Type(), 1, 1).Index(0).Type()

	for {
		row, err := iter.Next()
		if err != nil {
			if err == iterator.Done {
				break
			}
			return fmt.Errorf("intosAnySlice.iter: %w", err)
		}

		g := reflect.New(elemType)
		err = row.Column(0, g.Interface())
		if err != nil {
			return fmt.Errorf("intosAnySlice.Column: %w", err)
		}

		elem = reflect.Append(elem, g.Elem())
		value.Elem().Set(elem)
	}

	return nil
}

// DecodeInto decodes row into Decodable
// The decoder is not goroutine-safe. Don't use it concurrently.
func DecodeInto(cols []string, row *spanner.Row, into Decodable) error {
	ptrs, err := into.ColumnsToPtrs(cols)
	if err != nil {
		return err
	}

	if err := row.Columns(ptrs...); err != nil {
		return err
	}

	return nil
}

type groupRepository struct {
	Repository
}

type groupBuilder struct {
	b      *spannerbuilder.Builder
	client *spanner.Client
}

type groupIterator struct {
	*spanner.RowIterator
	cols []string
}

type GroupRepositoryCrud interface {
	FindAll(ctx context.Context) ([]*model.Group, error)
	FindAllWithCursor(ctx context.Context, limit int, cursor string) ([]*model.Group, error)
	CreateGroup(ctx context.Context, name string) (*model.Group, error)
	CreateOrUpdateGroup(ctx context.Context, name string) (*model.Group, error)
	InsertGroup(ctx context.Context, group *model.Group) (*model.Group, error)
	UpdateGroup(ctx context.Context, group *model.Group) error
	DeleteGroup(ctx context.Context, group *model.Group) error
}

func NewGroupRepository(client *spanner.Client) GroupRepository {
	return &groupRepository{
		Repository: Repository{
			client: client,
		},
	}
}

func (g *groupRepository) Query(ctx context.Context, stmt spanner.Statement) *groupIterator {
	iter := g.client.Single().Query(ctx, stmt)

	return &groupIterator{iter, model.GroupColumns()}
}

func (g *groupRepository) Insert(ctx context.Context, group *model.Group) (*time.Time, error) {
	if err := group.SetIdentity(); err != nil {
		return nil, err
	}
	if group.CreatedAt.IsZero() {
		group.CreatedAt = time.Now()
	}
	if group.UpdatedAt.IsZero() {
		group.UpdatedAt = time.Now()
	}

	mutations := []*spanner.Mutation{
		group.Insert(ctx),
	}
	t, err := g.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (g *groupRepository) InsertOrUpdate(ctx context.Context, group *model.Group) (time.Time, error) {
	if err := group.SetIdentity(); err != nil {
		return time.Time{}, err
	}
	if group.CreatedAt.IsZero() {
		group.CreatedAt = time.Now()
	}
	if group.UpdatedAt.IsZero() {
		group.UpdatedAt = time.Now()
	}

	mutations := []*spanner.Mutation{
		group.InsertOrUpdate(ctx),
	}
	t, err := g.client.Apply(ctx, mutations)
	if err != nil {
		return time.Time{}, err
	}
	return t, nil
}

func (g *groupRepository) Update(ctx context.Context, group *model.Group) (*time.Time, error) {
	if group.GroupID == "" {
		return nil, fmt.Errorf("primary_key `group_id` is blank")
	}
	if group.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	group.UpdatedAt = time.Now()

	mutations := []*spanner.Mutation{
		group.Update(ctx),
	}
	t, err := g.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (g *groupRepository) UpdateColumns(ctx context.Context, group *model.Group, cols ...string) (*time.Time, error) {
	if group.GroupID == "" {
		return nil, fmt.Errorf("primary_key `group_id` is blank")
	}
	if group.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	group.UpdatedAt = time.Now()

	mutation, err := group.UpdateColumns(ctx, cols...)
	if err != nil {
		return nil, err
	}
	mutations := []*spanner.Mutation{mutation}
	t, err := g.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (g *groupRepository) UpdateMap(ctx context.Context, group *model.Group, groupMap map[string]interface{}) (*time.Time, error) {
	if group.GroupID == "" {
		return nil, fmt.Errorf("primary_key `group_id` is blank")
	}
	if group.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	group.UpdatedAt = time.Now()

	mutation := group.UpdateMap(ctx, groupMap)
	mutations := []*spanner.Mutation{mutation}
	t, err := g.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (g *groupRepository) Delete(ctx context.Context, group *model.Group) (*time.Time, error) {
	if group.GroupID == "" {
		return nil, fmt.Errorf("primary_key `group_id` is blank")
	}
	if group.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	group.UpdatedAt = time.Now()

	mutation := group.Delete(ctx)
	mutations := []*spanner.Mutation{mutation}
	t, err := g.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (g *groupRepository) Builder() *groupBuilder {
	return &groupBuilder{
		b:      spannerbuilder.NewSpannerBuilder("groups", model.GroupColumns(), model.GroupPrimaryKeys()),
		client: g.client,
	}
}

func (b *groupBuilder) Select(s string) *groupBuilder {
	b.b.Select(s)
	return b
}

func (b *groupBuilder) Join(s string) *groupBuilder {
	b.b.Join(s)
	return b
}

func (b *groupBuilder) Where(s string, args ...interface{}) *groupBuilder {
	b.b.Where(s, args...)
	return b
}

func (b *groupBuilder) OrderBy(s string) *groupBuilder {
	b.b.OrderBy(s)
	return b
}

func (b *groupBuilder) Limit(i int) *groupBuilder {
	b.b.Limit(i)
	return b
}

func (b *groupBuilder) Query(ctx context.Context) *groupIterator {
	stmt := b.b.GetSelectStatement()
	iter := b.client.Single().Query(ctx, stmt)
	return &groupIterator{iter, b.b.Columns()}
}

func (iter *groupIterator) Into(into *model.Group) error {
	return iter.IntoDecodable(into)
}

func (iter *groupIterator) Intos(into *[]*model.Group) error {
	defer iter.Stop()
	for {
		row, err := iter.Next()
		if err != nil {
			if err == iterator.Done {
				break
			}
			return fmt.Errorf("Intos.iter: %w", err)
		}

		g := &model.Group{}
		err = DecodeInto(iter.cols, row, g)
		if err != nil {
			return fmt.Errorf("Intos.iter: %w", err)
		}

		*into = append(*into, g)
	}

	return nil
}

func (iter *groupIterator) IntoDecodable(into Decodable) error {
	if err := intoDecodable(iter.RowIterator, iter.cols, into); err != nil {
		if err == ErrNotFound {
			return apierrors.ErrNotFound.Swrapf("Group not found: %w", err)
		}
		return err
	}
	return nil
}

func (iter *groupIterator) IntosDecodable(into interface{}) error {
	return intosDecodable(iter.RowIterator, iter.cols, into)
}

func (iter *groupIterator) IntoAny(into interface{}) error {
	if err := intoAny(iter.RowIterator, iter.cols, into); err != nil {
		if err == ErrNotFound {
			return apierrors.ErrNotFound.Swrapf("Group not found: %w", err)
		}
		return err
	}
	return nil
}

func (iter *groupIterator) IntosAnySlice(into interface{}) error {
	return intosAnySlice(iter.RowIterator, iter.cols, into)
}

func (b *groupBuilder) QueryCachedInto(ctx context.Context, into **model.Group) error {
	stmt := b.b.GetSelectStatement()
	cacheKey, err := getCacheKey(stmt)
	if err != nil {
		return err
	}

	cached := middleware.CacheFromContext(ctx)
	if v, ok := cached.Get(cacheKey); ok {
		if *into, ok = v.(*model.Group); ok {
			return nil
		}
	}
	iter := b.client.Single().Query(ctx, stmt)
	it := &groupIterator{iter, b.b.Columns()}
	err = it.Into(*into)
	if err != nil {
		return err
	}
	cached.Set(cacheKey, *into)

	return nil
}

func (b *groupBuilder) QueryCachedIntos(ctx context.Context, into *[]*model.Group) error {
	stmt := b.b.GetSelectStatement()
	cacheKey, err := getCacheKey(stmt)
	if err != nil {
		return err
	}

	cache := middleware.CacheFromContext(ctx)
	if v, ok := cache.Get(cacheKey); ok {
		if *into, ok = v.([]*model.Group); ok {
			return nil
		}
	}
	iter := b.client.Single().Query(ctx, stmt)
	it := &groupIterator{iter, b.b.Columns()}
	err = it.Intos(into)
	if err != nil {
		return err
	}
	cache.Set(cacheKey, *into)

	return nil
}

func (g groupRepository) FindAll(ctx context.Context) ([]*model.Group, error) {
	var items []*model.Group
	if err := g.Builder().Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

func (g groupRepository) FindAllWithCursor(ctx context.Context, limit int, cursor string) ([]*model.Group, error) {
	items := make([]*model.Group, 0)
	builder := g.Builder()
	if cursor != "" {
		builder.Where("group_id < ?", cursor)
	}
	if err := builder.OrderBy("group_id DESC").Limit(limit).Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

func (g groupRepository) InsertGroup(ctx context.Context, group *model.Group) (*model.Group, error) {
	if _, err := g.Insert(ctx, group); err != nil {
		return nil, err
	}

	return group, nil
}

func (g groupRepository) CreateGroup(ctx context.Context, name string) (*model.Group, error) {
	groupEntity := &model.Group{Name: name}
	if _, err := g.Insert(ctx, groupEntity); err != nil {
		return nil, err
	}

	return groupEntity, nil
}

func (g groupRepository) CreateOrUpdateGroup(ctx context.Context, name string) (*model.Group, error) {
	groupEntity := &model.Group{Name: name}
	if _, err := g.InsertOrUpdate(ctx, groupEntity); err != nil {
		return nil, err
	}

	return groupEntity, nil
}

func (g groupRepository) UpdateGroup(ctx context.Context, group *model.Group) error {
	_, err := g.Update(ctx, group)
	if err != nil {
		return err
	}
	return nil
}

func (g groupRepository) DeleteGroup(ctx context.Context, group *model.Group) error {
	_, err := g.Delete(ctx, group)
	if err != nil {
		return err
	}
	return nil
}

type userRepository struct {
	Repository
}

type userBuilder struct {
	b      *spannerbuilder.Builder
	client *spanner.Client
}

type userIterator struct {
	*spanner.RowIterator
	cols []string
}

type UserRepositoryCrud interface {
	FindAll(ctx context.Context) ([]*model.User, error)
	FindAllWithCursor(ctx context.Context, limit int, cursor string) ([]*model.User, error)
	CreateUser(ctx context.Context, name string, status int64) (*model.User, error)
	CreateOrUpdateUser(ctx context.Context, name string, status int64) (*model.User, error)
	InsertUser(ctx context.Context, user *model.User) (*model.User, error)
	UpdateUser(ctx context.Context, user *model.User) error
	DeleteUser(ctx context.Context, user *model.User) error
}

func NewUserRepository(client *spanner.Client) UserRepository {
	return &userRepository{
		Repository: Repository{
			client: client,
		},
	}
}

func (u *userRepository) Query(ctx context.Context, stmt spanner.Statement) *userIterator {
	iter := u.client.Single().Query(ctx, stmt)

	return &userIterator{iter, model.UserColumns()}
}

func (u *userRepository) Insert(ctx context.Context, user *model.User) (*time.Time, error) {
	if err := user.SetIdentity(); err != nil {
		return nil, err
	}
	if user.CreatedAt.IsZero() {
		user.CreatedAt = time.Now()
	}
	if user.UpdatedAt.IsZero() {
		user.UpdatedAt = time.Now()
	}

	mutations := []*spanner.Mutation{
		user.Insert(ctx),
	}
	t, err := u.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (u *userRepository) InsertOrUpdate(ctx context.Context, user *model.User) (time.Time, error) {
	if err := user.SetIdentity(); err != nil {
		return time.Time{}, err
	}
	if user.CreatedAt.IsZero() {
		user.CreatedAt = time.Now()
	}
	if user.UpdatedAt.IsZero() {
		user.UpdatedAt = time.Now()
	}

	mutations := []*spanner.Mutation{
		user.InsertOrUpdate(ctx),
	}
	t, err := u.client.Apply(ctx, mutations)
	if err != nil {
		return time.Time{}, err
	}
	return t, nil
}

func (u *userRepository) Update(ctx context.Context, user *model.User) (*time.Time, error) {
	if user.UserID == "" {
		return nil, fmt.Errorf("primary_key `user_id` is blank")
	}
	if user.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	user.UpdatedAt = time.Now()

	mutations := []*spanner.Mutation{
		user.Update(ctx),
	}
	t, err := u.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (u *userRepository) UpdateColumns(ctx context.Context, user *model.User, cols ...string) (*time.Time, error) {
	if user.UserID == "" {
		return nil, fmt.Errorf("primary_key `user_id` is blank")
	}
	if user.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	user.UpdatedAt = time.Now()

	mutation, err := user.UpdateColumns(ctx, cols...)
	if err != nil {
		return nil, err
	}
	mutations := []*spanner.Mutation{mutation}
	t, err := u.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (u *userRepository) UpdateMap(ctx context.Context, user *model.User, userMap map[string]interface{}) (*time.Time, error) {
	if user.UserID == "" {
		return nil, fmt.Errorf("primary_key `user_id` is blank")
	}
	if user.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	user.UpdatedAt = time.Now()

	mutation := user.UpdateMap(ctx, userMap)
	mutations := []*spanner.Mutation{mutation}
	t, err := u.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (u *userRepository) Delete(ctx context.Context, user *model.User) (*time.Time, error) {
	if user.UserID == "" {
		return nil, fmt.Errorf("primary_key `user_id` is blank")
	}
	if user.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	user.UpdatedAt = time.Now()

	mutation := user.Delete(ctx)
	mutations := []*spanner.Mutation{mutation}
	t, err := u.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (u *userRepository) Builder() *userBuilder {
	return &userBuilder{
		b:      spannerbuilder.NewSpannerBuilder("users", model.UserColumns(), model.UserPrimaryKeys()),
		client: u.client,
	}
}

func (b *userBuilder) Select(s string) *userBuilder {
	b.b.Select(s)
	return b
}

func (b *userBuilder) Join(s string) *userBuilder {
	b.b.Join(s)
	return b
}

func (b *userBuilder) Where(s string, args ...interface{}) *userBuilder {
	b.b.Where(s, args...)
	return b
}

func (b *userBuilder) OrderBy(s string) *userBuilder {
	b.b.OrderBy(s)
	return b
}

func (b *userBuilder) Limit(i int) *userBuilder {
	b.b.Limit(i)
	return b
}

func (b *userBuilder) Query(ctx context.Context) *userIterator {
	stmt := b.b.GetSelectStatement()
	iter := b.client.Single().Query(ctx, stmt)
	return &userIterator{iter, b.b.Columns()}
}

func (iter *userIterator) Into(into *model.User) error {
	return iter.IntoDecodable(into)
}

func (iter *userIterator) Intos(into *[]*model.User) error {
	defer iter.Stop()
	for {
		row, err := iter.Next()
		if err != nil {
			if err == iterator.Done {
				break
			}
			return fmt.Errorf("Intos.iter: %w", err)
		}

		u := &model.User{}
		err = DecodeInto(iter.cols, row, u)
		if err != nil {
			return fmt.Errorf("Intos.iter: %w", err)
		}

		*into = append(*into, u)
	}

	return nil
}

func (iter *userIterator) IntoDecodable(into Decodable) error {
	if err := intoDecodable(iter.RowIterator, iter.cols, into); err != nil {
		if err == ErrNotFound {
			return apierrors.ErrNotFound.Swrapf("User not found: %w", err)
		}
		return err
	}
	return nil
}

func (iter *userIterator) IntosDecodable(into interface{}) error {
	return intosDecodable(iter.RowIterator, iter.cols, into)
}

func (iter *userIterator) IntoAny(into interface{}) error {
	if err := intoAny(iter.RowIterator, iter.cols, into); err != nil {
		if err == ErrNotFound {
			return apierrors.ErrNotFound.Swrapf("User not found: %w", err)
		}
		return err
	}
	return nil
}

func (iter *userIterator) IntosAnySlice(into interface{}) error {
	return intosAnySlice(iter.RowIterator, iter.cols, into)
}

func (b *userBuilder) QueryCachedInto(ctx context.Context, into **model.User) error {
	stmt := b.b.GetSelectStatement()
	cacheKey, err := getCacheKey(stmt)
	if err != nil {
		return err
	}

	cached := middleware.CacheFromContext(ctx)
	if v, ok := cached.Get(cacheKey); ok {
		if *into, ok = v.(*model.User); ok {
			return nil
		}
	}
	iter := b.client.Single().Query(ctx, stmt)
	it := &userIterator{iter, b.b.Columns()}
	err = it.Into(*into)
	if err != nil {
		return err
	}
	cached.Set(cacheKey, *into)

	return nil
}

func (b *userBuilder) QueryCachedIntos(ctx context.Context, into *[]*model.User) error {
	stmt := b.b.GetSelectStatement()
	cacheKey, err := getCacheKey(stmt)
	if err != nil {
		return err
	}

	cache := middleware.CacheFromContext(ctx)
	if v, ok := cache.Get(cacheKey); ok {
		if *into, ok = v.([]*model.User); ok {
			return nil
		}
	}
	iter := b.client.Single().Query(ctx, stmt)
	it := &userIterator{iter, b.b.Columns()}
	err = it.Intos(into)
	if err != nil {
		return err
	}
	cache.Set(cacheKey, *into)

	return nil
}

func (u userRepository) FindAll(ctx context.Context) ([]*model.User, error) {
	var items []*model.User
	if err := u.Builder().Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

func (u userRepository) FindAllWithCursor(ctx context.Context, limit int, cursor string) ([]*model.User, error) {
	items := make([]*model.User, 0)
	builder := u.Builder()
	if cursor != "" {
		builder.Where("user_id < ?", cursor)
	}
	if err := builder.OrderBy("user_id DESC").Limit(limit).Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

func (u userRepository) InsertUser(ctx context.Context, user *model.User) (*model.User, error) {
	if _, err := u.Insert(ctx, user); err != nil {
		return nil, err
	}

	return user, nil
}

func (u userRepository) CreateUser(ctx context.Context, name string, status int64) (*model.User, error) {
	userEntity := &model.User{Name: name, Status: status}
	if _, err := u.Insert(ctx, userEntity); err != nil {
		return nil, err
	}

	return userEntity, nil
}

func (u userRepository) CreateOrUpdateUser(ctx context.Context, name string, status int64) (*model.User, error) {
	userEntity := &model.User{Name: name, Status: status}
	if _, err := u.InsertOrUpdate(ctx, userEntity); err != nil {
		return nil, err
	}

	return userEntity, nil
}

func (u userRepository) UpdateUser(ctx context.Context, user *model.User) error {
	_, err := u.Update(ctx, user)
	if err != nil {
		return err
	}
	return nil
}

func (u userRepository) DeleteUser(ctx context.Context, user *model.User) error {
	_, err := u.Delete(ctx, user)
	if err != nil {
		return err
	}
	return nil
}

type userGroupRepository struct {
	Repository
}

type userGroupBuilder struct {
	b      *spannerbuilder.Builder
	client *spanner.Client
}

type userGroupIterator struct {
	*spanner.RowIterator
	cols []string
}

type UserGroupRepositoryCrud interface {
	FindAll(ctx context.Context) ([]*model.UserGroup, error)
	CreateUserGroup(ctx context.Context, groupID string, userID string) (*model.UserGroup, error)
	CreateOrUpdateUserGroup(ctx context.Context, groupID string, userID string) (*model.UserGroup, error)
	InsertUserGroup(ctx context.Context, userGroup *model.UserGroup) (*model.UserGroup, error)
	UpdateUserGroup(ctx context.Context, userGroup *model.UserGroup) error
	DeleteUserGroup(ctx context.Context, userGroup *model.UserGroup) error
}

func NewUserGroupRepository(client *spanner.Client) UserGroupRepository {
	return &userGroupRepository{
		Repository: Repository{
			client: client,
		},
	}
}

func (ug *userGroupRepository) Query(ctx context.Context, stmt spanner.Statement) *userGroupIterator {
	iter := ug.client.Single().Query(ctx, stmt)

	return &userGroupIterator{iter, model.UserGroupColumns()}
}

func (ug *userGroupRepository) Insert(ctx context.Context, userGroup *model.UserGroup) (*time.Time, error) {
	if err := userGroup.SetIdentity(); err != nil {
		return nil, err
	}
	if userGroup.CreatedAt.IsZero() {
		userGroup.CreatedAt = time.Now()
	}
	if userGroup.UpdatedAt.IsZero() {
		userGroup.UpdatedAt = time.Now()
	}

	mutations := []*spanner.Mutation{
		userGroup.Insert(ctx),
	}
	t, err := ug.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (ug *userGroupRepository) InsertOrUpdate(ctx context.Context, userGroup *model.UserGroup) (time.Time, error) {
	if err := userGroup.SetIdentity(); err != nil {
		return time.Time{}, err
	}
	if userGroup.CreatedAt.IsZero() {
		userGroup.CreatedAt = time.Now()
	}
	if userGroup.UpdatedAt.IsZero() {
		userGroup.UpdatedAt = time.Now()
	}

	mutations := []*spanner.Mutation{
		userGroup.InsertOrUpdate(ctx),
	}
	t, err := ug.client.Apply(ctx, mutations)
	if err != nil {
		return time.Time{}, err
	}
	return t, nil
}

func (ug *userGroupRepository) Update(ctx context.Context, userGroup *model.UserGroup) (*time.Time, error) {
	if userGroup.GroupID == "" {
		return nil, fmt.Errorf("primary_key `group_id` is blank")
	}
	if userGroup.UserID == "" {
		return nil, fmt.Errorf("primary_key `user_id` is blank")
	}
	if userGroup.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	userGroup.UpdatedAt = time.Now()

	mutations := []*spanner.Mutation{
		userGroup.Update(ctx),
	}
	t, err := ug.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (ug *userGroupRepository) UpdateColumns(ctx context.Context, userGroup *model.UserGroup, cols ...string) (*time.Time, error) {
	if userGroup.GroupID == "" {
		return nil, fmt.Errorf("primary_key `group_id` is blank")
	}
	if userGroup.UserID == "" {
		return nil, fmt.Errorf("primary_key `user_id` is blank")
	}
	if userGroup.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	userGroup.UpdatedAt = time.Now()

	mutation, err := userGroup.UpdateColumns(ctx, cols...)
	if err != nil {
		return nil, err
	}
	mutations := []*spanner.Mutation{mutation}
	t, err := ug.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (ug *userGroupRepository) UpdateMap(ctx context.Context, userGroup *model.UserGroup, userGroupMap map[string]interface{}) (*time.Time, error) {
	if userGroup.GroupID == "" {
		return nil, fmt.Errorf("primary_key `group_id` is blank")
	}
	if userGroup.UserID == "" {
		return nil, fmt.Errorf("primary_key `user_id` is blank")
	}
	if userGroup.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	userGroup.UpdatedAt = time.Now()

	mutation := userGroup.UpdateMap(ctx, userGroupMap)
	mutations := []*spanner.Mutation{mutation}
	t, err := ug.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (ug *userGroupRepository) Delete(ctx context.Context, userGroup *model.UserGroup) (*time.Time, error) {
	if userGroup.GroupID == "" {
		return nil, fmt.Errorf("primary_key `group_id` is blank")
	}
	if userGroup.UserID == "" {
		return nil, fmt.Errorf("primary_key `user_id` is blank")
	}
	if userGroup.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	userGroup.UpdatedAt = time.Now()

	mutation := userGroup.Delete(ctx)
	mutations := []*spanner.Mutation{mutation}
	t, err := ug.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (ug *userGroupRepository) Builder() *userGroupBuilder {
	return &userGroupBuilder{
		b:      spannerbuilder.NewSpannerBuilder("user_groups", model.UserGroupColumns(), model.UserGroupPrimaryKeys()),
		client: ug.client,
	}
}

func (b *userGroupBuilder) Select(s string) *userGroupBuilder {
	b.b.Select(s)
	return b
}

func (b *userGroupBuilder) Join(s string) *userGroupBuilder {
	b.b.Join(s)
	return b
}

func (b *userGroupBuilder) Where(s string, args ...interface{}) *userGroupBuilder {
	b.b.Where(s, args...)
	return b
}

func (b *userGroupBuilder) OrderBy(s string) *userGroupBuilder {
	b.b.OrderBy(s)
	return b
}

func (b *userGroupBuilder) Limit(i int) *userGroupBuilder {
	b.b.Limit(i)
	return b
}

func (b *userGroupBuilder) Query(ctx context.Context) *userGroupIterator {
	stmt := b.b.GetSelectStatement()
	iter := b.client.Single().Query(ctx, stmt)
	return &userGroupIterator{iter, b.b.Columns()}
}

func (iter *userGroupIterator) Into(into *model.UserGroup) error {
	return iter.IntoDecodable(into)
}

func (iter *userGroupIterator) Intos(into *[]*model.UserGroup) error {
	defer iter.Stop()
	for {
		row, err := iter.Next()
		if err != nil {
			if err == iterator.Done {
				break
			}
			return fmt.Errorf("Intos.iter: %w", err)
		}

		ug := &model.UserGroup{}
		err = DecodeInto(iter.cols, row, ug)
		if err != nil {
			return fmt.Errorf("Intos.iter: %w", err)
		}

		*into = append(*into, ug)
	}

	return nil
}

func (iter *userGroupIterator) IntoDecodable(into Decodable) error {
	if err := intoDecodable(iter.RowIterator, iter.cols, into); err != nil {
		if err == ErrNotFound {
			return apierrors.ErrNotFound.Swrapf("UserGroup not found: %w", err)
		}
		return err
	}
	return nil
}

func (iter *userGroupIterator) IntosDecodable(into interface{}) error {
	return intosDecodable(iter.RowIterator, iter.cols, into)
}

func (iter *userGroupIterator) IntoAny(into interface{}) error {
	if err := intoAny(iter.RowIterator, iter.cols, into); err != nil {
		if err == ErrNotFound {
			return apierrors.ErrNotFound.Swrapf("UserGroup not found: %w", err)
		}
		return err
	}
	return nil
}

func (iter *userGroupIterator) IntosAnySlice(into interface{}) error {
	return intosAnySlice(iter.RowIterator, iter.cols, into)
}

func (b *userGroupBuilder) QueryCachedInto(ctx context.Context, into **model.UserGroup) error {
	stmt := b.b.GetSelectStatement()
	cacheKey, err := getCacheKey(stmt)
	if err != nil {
		return err
	}

	cached := middleware.CacheFromContext(ctx)
	if v, ok := cached.Get(cacheKey); ok {
		if *into, ok = v.(*model.UserGroup); ok {
			return nil
		}
	}
	iter := b.client.Single().Query(ctx, stmt)
	it := &userGroupIterator{iter, b.b.Columns()}
	err = it.Into(*into)
	if err != nil {
		return err
	}
	cached.Set(cacheKey, *into)

	return nil
}

func (b *userGroupBuilder) QueryCachedIntos(ctx context.Context, into *[]*model.UserGroup) error {
	stmt := b.b.GetSelectStatement()
	cacheKey, err := getCacheKey(stmt)
	if err != nil {
		return err
	}

	cache := middleware.CacheFromContext(ctx)
	if v, ok := cache.Get(cacheKey); ok {
		if *into, ok = v.([]*model.UserGroup); ok {
			return nil
		}
	}
	iter := b.client.Single().Query(ctx, stmt)
	it := &userGroupIterator{iter, b.b.Columns()}
	err = it.Intos(into)
	if err != nil {
		return err
	}
	cache.Set(cacheKey, *into)

	return nil
}

func (ug userGroupRepository) FindAll(ctx context.Context) ([]*model.UserGroup, error) {
	var items []*model.UserGroup
	if err := ug.Builder().Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

func (ug userGroupRepository) InsertUserGroup(ctx context.Context, userGroup *model.UserGroup) (*model.UserGroup, error) {
	if _, err := ug.Insert(ctx, userGroup); err != nil {
		return nil, err
	}

	return userGroup, nil
}
func (ug userGroupRepository) CreateUserGroup(ctx context.Context, groupID string, userID string) (*model.UserGroup, error) {
	userGroupEntity := &model.UserGroup{GroupID: groupID, UserID: userID}
	if _, err := ug.Insert(ctx, userGroupEntity); err != nil {
		return nil, err
	}

	return userGroupEntity, nil
}

func (ug userGroupRepository) CreateOrUpdateUserGroup(ctx context.Context, groupID string, userID string) (*model.UserGroup, error) {
	userGroupEntity := &model.UserGroup{GroupID: groupID, UserID: userID}
	if _, err := ug.InsertOrUpdate(ctx, userGroupEntity); err != nil {
		return nil, err
	}

	return userGroupEntity, nil
}

func (ug userGroupRepository) UpdateUserGroup(ctx context.Context, userGroup *model.UserGroup) error {
	_, err := ug.Update(ctx, userGroup)
	if err != nil {
		return err
	}
	return nil
}

func (ug userGroupRepository) DeleteUserGroup(ctx context.Context, userGroup *model.UserGroup) error {
	_, err := ug.Delete(ctx, userGroup)
	if err != nil {
		return err
	}
	return nil
}
