// Code generated by yo. DO NOT EDIT.
package repository

import (
	"context"
	"errors"
	"fmt"
	"reflect"
	"time"

	"cloud.google.com/go/spanner"
	"google.golang.org/api/iterator"

	"github.com/s-you/apierrors"
	"github.com/s-you/spannerbuilder"
	"github.com/s-you/yo-templates/internal/model"
)

type Repository struct {
	client *spanner.Client
}

type (
	Params = map[string]interface{}
	Key    = spanner.Key
	KeySet = spanner.KeySet
)

type Decodable interface {
	ColumnsToPtrs([]string) ([]interface{}, error)
}

var (
	ErrNotFound = errors.New("NotFound")
)

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
	elemType := elem.Type().Elem()
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
		} else {
			return fmt.Errorf("intosDecodable: not Decodable")
		}
	}
	value.Elem().Set(elem)

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
	elemType := elem.Type().Elem()

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
	}
	value.Elem().Set(elem)

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

func (g *groupRepository) ReadRowInto(ctx context.Context, key Key, into Decodable) error {
	cols := model.GroupColumns()
	row, err := g.client.Single().ReadRow(ctx, "groups", key, cols)
	if err != nil {
		return err
	}
	if err := DecodeInto(cols, row, into); err != nil {
		return err
	}

	return nil
}

func (g *groupRepository) Read(ctx context.Context, keySet KeySet) *groupIterator {
	cols := model.GroupColumns()
	iter := g.client.Single().Read(ctx, "groups", keySet, cols)

	return &groupIterator{iter, cols}
}

func (g *groupRepository) ReadUsingIndex(ctx context.Context, keySet KeySet, index string) *groupIterator {
	cols := model.GroupColumns()
	iter := g.client.Single().ReadUsingIndex(ctx, "groups", index, keySet, cols)

	return &groupIterator{iter, cols}
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

func (b *groupBuilder) From(s string) *groupBuilder {
	b.b.From(s)
	return b
}

func (b *groupBuilder) Select(s string, cols ...string) *groupBuilder {
	b.b.Select(s, cols...)
	return b
}

func (b *groupBuilder) Join(s string, joinType ...string) *groupBuilder {
	b.b.Join(s, joinType...)
	return b
}

func (b *groupBuilder) Where(s string, args ...interface{}) *groupBuilder {
	b.b.Where(s, args...)
	return b
}

func (b *groupBuilder) GroupBy(s string) *groupBuilder {
	b.b.GroupBy(s)
	return b
}

func (b *groupBuilder) Having(s string, args ...interface{}) *groupBuilder {
	b.b.Having(s, args...)
	return b
}

func (b *groupBuilder) TableSample(s string) *groupBuilder {
	b.b.TableSample(s)
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

func (u *userRepository) ReadRowInto(ctx context.Context, key Key, into Decodable) error {
	cols := model.UserColumns()
	row, err := u.client.Single().ReadRow(ctx, "users", key, cols)
	if err != nil {
		return err
	}
	if err := DecodeInto(cols, row, into); err != nil {
		return err
	}

	return nil
}

func (u *userRepository) Read(ctx context.Context, keySet KeySet) *userIterator {
	cols := model.UserColumns()
	iter := u.client.Single().Read(ctx, "users", keySet, cols)

	return &userIterator{iter, cols}
}

func (u *userRepository) ReadUsingIndex(ctx context.Context, keySet KeySet, index string) *userIterator {
	cols := model.UserColumns()
	iter := u.client.Single().ReadUsingIndex(ctx, "users", index, keySet, cols)

	return &userIterator{iter, cols}
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

func (b *userBuilder) From(s string) *userBuilder {
	b.b.From(s)
	return b
}

func (b *userBuilder) Select(s string, cols ...string) *userBuilder {
	b.b.Select(s, cols...)
	return b
}

func (b *userBuilder) Join(s string, joinType ...string) *userBuilder {
	b.b.Join(s, joinType...)
	return b
}

func (b *userBuilder) Where(s string, args ...interface{}) *userBuilder {
	b.b.Where(s, args...)
	return b
}

func (b *userBuilder) GroupBy(s string) *userBuilder {
	b.b.GroupBy(s)
	return b
}

func (b *userBuilder) Having(s string, args ...interface{}) *userBuilder {
	b.b.Having(s, args...)
	return b
}

func (b *userBuilder) TableSample(s string) *userBuilder {
	b.b.TableSample(s)
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

func (ug *userGroupRepository) ReadRowInto(ctx context.Context, key Key, into Decodable) error {
	cols := model.UserGroupColumns()
	row, err := ug.client.Single().ReadRow(ctx, "user_groups", key, cols)
	if err != nil {
		return err
	}
	if err := DecodeInto(cols, row, into); err != nil {
		return err
	}

	return nil
}

func (ug *userGroupRepository) Read(ctx context.Context, keySet KeySet) *userGroupIterator {
	cols := model.UserGroupColumns()
	iter := ug.client.Single().Read(ctx, "user_groups", keySet, cols)

	return &userGroupIterator{iter, cols}
}

func (ug *userGroupRepository) ReadUsingIndex(ctx context.Context, keySet KeySet, index string) *userGroupIterator {
	cols := model.UserGroupColumns()
	iter := ug.client.Single().ReadUsingIndex(ctx, "user_groups", index, keySet, cols)

	return &userGroupIterator{iter, cols}
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

func (b *userGroupBuilder) From(s string) *userGroupBuilder {
	b.b.From(s)
	return b
}

func (b *userGroupBuilder) Select(s string, cols ...string) *userGroupBuilder {
	b.b.Select(s, cols...)
	return b
}

func (b *userGroupBuilder) Join(s string, joinType ...string) *userGroupBuilder {
	b.b.Join(s, joinType...)
	return b
}

func (b *userGroupBuilder) Where(s string, args ...interface{}) *userGroupBuilder {
	b.b.Where(s, args...)
	return b
}

func (b *userGroupBuilder) GroupBy(s string) *userGroupBuilder {
	b.b.GroupBy(s)
	return b
}

func (b *userGroupBuilder) Having(s string, args ...interface{}) *userGroupBuilder {
	b.b.Having(s, args...)
	return b
}

func (b *userGroupBuilder) TableSample(s string) *userGroupBuilder {
	b.b.TableSample(s)
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
