{{- $short := (shortname .Name "err" "res" "sqlstr" "db" "YOLog") }}
{{- $table := (.Table.TableName) }}
{{- $name := (print (goparamname .Name) "Repository") }}
{{- $lname := (goparamname .Name) }}
{{- $database := (print .Name "Repository") }}
{{- $primaryKeys := .PrimaryKeyFields }}
{{- $hasCreatedAt := false }}
{{- $hasUpdatedAt := false }}
{{- range .Fields }}
{{- if eq .Name "CreatedAt"}}{{ $hasCreatedAt = true}}
{{- else if eq .Name "UpdatedAt"}}{{ $hasUpdatedAt = true}}{{- end }}
{{- end }}
{{- $pkey0 := (index .PrimaryKeyFields 0) }}

type {{ $name }} struct {
	repository
}

type {{$lname}}Builder struct {
	b      *spannerbuilder.Builder
	client *spanner.Client
}

type {{$lname}}Iterator struct {
	*spanner.RowIterator
	cols []string
	qc   queryCache
}

func New{{ $database }}(client *spanner.Client) {{ $database }} {
	return &{{ $name }}{
		repository: repository{
			client: client,
		},
	}
}

func ({{$short}} *{{$name}}) Query(ctx context.Context, stmt spanner.Statement) *{{$lname}}Iterator {
	iter := {{$short}}.client.Single().Query(ctx, stmt)

	return &{{$lname}}Iterator{iter, model.{{ .Name }}Columns(), queryCache{stmt: stmt}}
}

func ({{$short}} *{{$name}}) Read(ctx context.Context, keySet spanner.KeySet) *{{$lname}}Iterator {
	cols := model.{{.Name}}Columns()
	iter := {{$short}}.client.Single().Read(ctx, "{{ $table }}", keySet, cols)

	return &{{$lname}}Iterator{RowIterator: iter, cols: cols}
}

func ({{$short}} *{{$name}}) ReadUsingIndex(ctx context.Context, index string, keySet spanner.KeySet) *{{$lname}}Iterator {
	cols := model.{{.Name}}ColumnsByIndexName(index)
	iter := {{$short}}.client.Single().ReadUsingIndex(ctx, "{{ $table }}", index, keySet, cols)

	return &{{$lname}}Iterator{RowIterator: iter, cols: cols}
}

func ({{$short}} *{{$name}}) Insert(ctx context.Context, {{$lname}} *model.{{.Name}}) (*time.Time, error) {
	if err := {{$lname}}.SetIdentity(); err != nil {
		return nil, err
	}
{{- if $hasCreatedAt }}
	if {{$lname}}.CreatedAt.IsZero() {
		{{$lname}}.CreatedAt = time.Now()
	}
{{- end }}
{{- if $hasUpdatedAt }}
	if {{$lname}}.UpdatedAt.IsZero() {
		{{$lname}}.UpdatedAt = time.Now()
	}
{{- end }}

	mutation := []*spanner.Mutation{ {{- $lname}}.Insert()}
	if tx, ok := ctx.Value(txKey).(Transaction); ok {
		if err := tx.BufferWrite(mutation); err != nil {
			return nil, err
		}
		return nil, nil
	}

	modified, err := {{$short}}.client.Apply(ctx, mutation)
	if err != nil {
		return nil, err
	}
	return &modified, nil
}

func ({{$short}} *{{$name}}) InsertOrUpdate(ctx context.Context, {{$lname}} *model.{{.Name}}) (*time.Time, error) {
	if err := {{$lname}}.SetIdentity(); err != nil {
		return nil, err
	}
{{- if $hasCreatedAt }}
	if {{$lname}}.CreatedAt.IsZero() {
		{{$lname}}.CreatedAt = time.Now()
	}
{{- end }}
{{- if $hasUpdatedAt }}
	if {{$lname}}.UpdatedAt.IsZero() {
		{{$lname}}.UpdatedAt = time.Now()
	}
{{- end }}

	mutation := []*spanner.Mutation{ {{- $lname}}.InsertOrUpdate()}
	if tx, ok := ctx.Value(txKey).(Transaction); ok {
		if err := tx.BufferWrite(mutation); err != nil {
			return nil, err
		}
		return nil, nil
	}

	modified, err := {{$short}}.client.Apply(ctx, mutation)
	if err != nil {
		return nil, err
	}
	return &modified, nil
}

func ({{$short}} *{{$name}}) Update(ctx context.Context, {{$lname}} *model.{{.Name}}) (*time.Time, error) {
	{{- range .PrimaryKeyFields }}
	if {{$lname}}.{{ .Name }} == {{ if eq .Type "string" }}""{{else}}0{{end}} {
		return nil, fmt.Errorf("primary_key `{{ colname .Col }}` is blank")
	}{{ end }}
{{- if $hasCreatedAt }}
	if {{$lname}}.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
{{- end }}
{{- if $hasUpdatedAt }}
	{{$lname}}.UpdatedAt = time.Now()
{{- end }}

	mutation := []*spanner.Mutation{ {{- $lname}}.Update()}
	if tx, ok := ctx.Value(txKey).(Transaction); ok {
		if err := tx.BufferWrite(mutation); err != nil {
			return nil, err
		}
		return nil, nil
	}

	modified, err := {{$short}}.client.Apply(ctx, mutation)
	if err != nil {
		return nil, err
	}
	return &modified, nil
}

func ({{$short}} *{{$name}}) UpdateColumns(ctx context.Context, {{$lname}} *model.{{.Name}}, cols ...string) (*time.Time, error) {
	{{- range .PrimaryKeyFields }}
	if {{$lname}}.{{ .Name }} == {{ if eq .Type "string" }}""{{else}}0{{end}} {
		return nil, fmt.Errorf("primary_key `{{ colname .Col }}` is blank")
	}{{ end}}
{{- if $hasCreatedAt }}
	if {{$lname}}.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
{{- end }}
{{- if $hasUpdatedAt }}
	{{$lname}}.UpdatedAt = time.Now()
{{- end }}

	_mutation, err := {{$lname}}.UpdateColumns(cols...)
	if err != nil {
		return nil, err
	}

	mutation := []*spanner.Mutation{_mutation}
	if tx, ok := ctx.Value(txKey).(Transaction); ok {
		if err := tx.BufferWrite(mutation); err != nil {
			return nil, err
		}
		return nil, nil
	}

	modified, err := {{$short}}.client.Apply(ctx, mutation)
	if err != nil {
		return nil, err
	}
	return &modified, nil
}

func ({{$short}} *{{$name}}) UpdateMap(ctx context.Context, {{$lname}} *model.{{.Name}}, {{$lname}}Map map[string]interface{}) (*time.Time, error) {
	{{- range .PrimaryKeyFields }}
	if {{$lname}}.{{ .Name }} == {{ if eq .Type "string" }}""{{else}}0{{end}} {
		return nil, fmt.Errorf("primary_key `{{ colname .Col }}` is blank")
	}{{ end}}
{{- if $hasCreatedAt }}
	if {{$lname}}.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
{{- end }}
{{- if $hasUpdatedAt }}
	{{$lname}}.UpdatedAt = time.Now()
{{- end }}

	mutation := []*spanner.Mutation{ {{- $lname }}.UpdateMap({{$lname}}Map)}
	if tx, ok := ctx.Value(txKey).(Transaction); ok {
		if err := tx.BufferWrite(mutation); err != nil {
			return nil, err
		}
		return nil, nil
	}

	modified, err := {{$short}}.client.Apply(ctx, mutation)
	if err != nil {
		return nil, err
	}
	return &modified, nil
}

func ({{$short}} *{{$name}}) Delete(ctx context.Context, {{$lname}} *model.{{.Name}}) (*time.Time, error) {
	{{- range .PrimaryKeyFields }}
	if {{$lname}}.{{ .Name }} == {{ if eq .Type "string" }}""{{else}}0{{end}} {
		return nil, fmt.Errorf("primary_key `{{ colname .Col }}` is blank")
	}{{ end}}

	mutation := []*spanner.Mutation{ {{- $lname }}.Delete()}
	if tx, ok := ctx.Value(txKey).(Transaction); ok {
		if err := tx.BufferWrite(mutation); err != nil {
			return nil, err
		}
		return nil, nil
	}

	modified, err := {{$short}}.client.Apply(ctx, mutation)
	if err != nil {
		return nil, err
	}
	return &modified, nil
}

func ({{$short}} *{{$name}}) Builder() *{{$lname}}Builder {
	return &{{$lname}}Builder{
		b:      spannerbuilder.NewSpannerBuilder("{{ $table }}", model.{{ .Name }}Columns(), model.{{ .Name }}PrimaryKeys()),
		client: {{$short}}.client,
	}
}

func (b *{{$lname}}Builder) From(s string) *{{$lname}}Builder {
	b.b.From(s)
	return b
}

func (b *{{$lname}}Builder) Select(s string, cols ...string) *{{$lname}}Builder {
	b.b.Select(s, cols...)
	return b
}

func (b *{{$lname}}Builder) Join(s string, joinType ...string) *{{$lname}}Builder {
	b.b.Join(s, joinType...)
	return b
}

func (b *{{$lname}}Builder) Where(s string, args ...interface{}) *{{$lname}}Builder {
	b.b.Where(s, args...)
	return b
}

func (b *{{$lname}}Builder) GroupBy(s string) *{{$lname}}Builder {
	b.b.GroupBy(s)
	return b
}

func (b *{{$lname}}Builder) Having(s string, args ...interface{}) *{{$lname}}Builder {
	b.b.Having(s, args...)
	return b
}

func (b *{{$lname}}Builder) TableSample(s string) *{{$lname}}Builder {
	b.b.TableSample(s)
	return b
}

func (b *{{$lname}}Builder) OrderBy(s string) *{{$lname}}Builder {
	b.b.OrderBy(s)
	return b
}

func (b *{{$lname}}Builder) Limit(i int) *{{$lname}}Builder {
	b.b.Limit(i)
	return b
}

func (b *{{$lname}}Builder) Query(ctx context.Context) *{{$lname}}Iterator {
	stmt := b.b.GetSelectStatement()
	iter := b.client.Single().Query(ctx, stmt)
	return &{{$lname}}Iterator{iter, b.b.Columns(), queryCache{stmt: stmt}}
}

func (iter *{{$lname}}Iterator) Cached(d time.Duration) *{{$lname}}Iterator {
	iter.qc.duration = d
	iter.qc.enabled = true
	return iter
}

func (iter *{{$lname}}Iterator) Do(fn func(row Row) error) error {
	return iter.RowIterator.Do(fn)
}

func (iter *{{$lname}}Iterator) Into(into *model.{{.Name}}) error {
	if iter.qc.enabled {
		cacheKey, err := getCacheKey(iter.qc.stmt)
		if err != nil {
			return err
		}
		if v, ok := cached.Get(cacheKey); ok {
			if cacheValue, ok := v.(*model.{{.Name}}); ok {
				if err := copyInto(iter.cols, into, cacheValue); err != nil {
					return err
				}
				return nil
			}
		}
		if err := iter.IntoDecodable(into); err != nil {
			return err
		}
		cached.Set(cacheKey, into, iter.qc.duration)
		return nil
	}
	return iter.IntoDecodable(into)
}

func (iter *{{$lname}}Iterator) Intos(into *[]*model.{{.Name}}) error {
	if iter.qc.enabled {
		cacheKey, err := getCacheKey(iter.qc.stmt)
		if err != nil {
			return err
		}
		if v, ok := cached.Get(cacheKey); ok {
			if *into, ok = v.([]*model.{{.Name}}); ok {
				return nil
			}
		}
		if err := iter.intos(into); err != nil {
			return err
		}
		cached.Set(cacheKey, *into, iter.qc.duration)
		return nil
	}
	return iter.intos(into)
}

func (iter *{{$lname}}Iterator) intos(into *[]*model.{{.Name}}) error {
	defer iter.Stop()
	for {
		row, err := iter.Next()
		if err != nil {
			if err == iterator.Done {
				break
			}
			return fmt.Errorf("{{$lname}}Iterator.Next: %w", err)
		}

		{{$short}} := &model.{{.Name}}{}
		if err := DecodeInto(iter.cols, row, {{$short}}); err != nil {
			return fmt.Errorf("{{$lname}}Iterator.DecodeInto: %w", err)
		}

		*into = append(*into, {{$short}})
	}

	return nil
}

func (iter *{{$lname}}Iterator) IntoDecodable(into Decodable) error {
	if err := intoDecodable(iter.RowIterator, iter.cols, into); err != nil {
		if err == ErrNotFound {
			return fmt.Errorf("{{.Name}} not found: %w", err)
		}
		return err
	}
	return nil
}

func (iter *{{$lname}}Iterator) IntosDecodable(into interface{}) error {
	return intosDecodable(iter.RowIterator, iter.cols, into)
}

func (iter *{{$lname}}Iterator) IntoAny(into interface{}) error {
	if err := intoAny(iter.RowIterator, iter.cols, into); err != nil {
		if err == ErrNotFound {
			return fmt.Errorf("{{.Name}} not found: %w", err)
		}
		return err
	}
	return nil
}

func (iter *{{$lname}}Iterator) IntosAnySlice(into interface{}) error {
	return intosAnySlice(iter.RowIterator, iter.cols, into)
}
{{- /* */ -}}
