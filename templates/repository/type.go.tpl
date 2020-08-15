{{- $short := (shortname .Name "err" "res" "sqlstr" "db" "YOLog") -}}
{{- $table := (.Table.TableName) -}}
{{- $name := (print (goparamname .Name) "Repository") -}}
{{- $lname := (goparamname .Name) -}}
{{- $database := (print .Name "Repository") -}}
{{- $primaryKeys := .PrimaryKeyFields -}}
{{- $pkey0 := (index .PrimaryKeyFields 0) }}

type {{ $name }} struct {
	Repository
}

type {{$lname}}Builder struct {
	b      *spannerbuilder.Builder
	client *spanner.Client
}

type {{$lname}}Iterator struct {
	*spanner.RowIterator
	cols []string
}

type {{ $database }}Generated interface {
	Get{{.Name}}By{{- range $i, $f := .PrimaryKeyFields }}{{ if (gt $i 0) }}And{{ end }}{{ .Name }}{{ end -}}
		(ctx context.Context{{ goparamlist .PrimaryKeyFields true true }}) (*model.{{ .Name }}, error)
	Get{{.Name}}By{{- range $i, $f := .PrimaryKeyFields }}{{ if (gt $i 0) }}And{{ end }}{{ .Name }}{{ end -}}
		Cached(ctx context.Context{{ goparamlist .PrimaryKeyFields true true }}) (*model.{{ .Name }}, error)
	{{- if eq (len .PrimaryKeyFields) 1 }}
	Find{{.Name}}By{{$pkey0.Name}}s(ctx context.Context, ids []{{$pkey0.Type}}) ([]*model.{{ .Name }}, error)
	Find{{.Name}}By{{$pkey0.Name}}sCached(ctx context.Context, ids []{{$pkey0.Type}}) ([]*model.{{ .Name }}, error)
	{{- end }}
	{{- range .Indexes -}}
		{{- if not .Index.IsUnique }}
	Find{{ .FuncName }}(ctx context.Context{{ goparamlist .Fields true true }}) ([]*model.{{ .Type.Name }}, error)
	Find{{ .FuncName }}Cached(ctx context.Context{{ goparamlist .Fields true true }}) ([]*model.{{ .Type.Name }}, error)
		{{- else }}
	Get{{ .FuncName }}(ctx context.Context{{ goparamlist .Fields true true }}) (*model.{{ .Type.Name }}, error)
	Get{{ .FuncName }}Cached(ctx context.Context{{ goparamlist .Fields true true }}) (*model.{{ .Type.Name }}, error)
		{{- end }}
		{{- if eq (len .Fields) 1 -}}
		{{- $f0 := (index .Fields 0) }}
	Find{{.FuncName}}s(ctx context.Context, ids []{{$f0.Type}}) ([]*model.{{ .Type.Name }}, error)
	Find{{.FuncName}}sCached(ctx context.Context, ids []{{$f0.Type}}) ([]*model.{{ .Type.Name }}, error)
		{{- end }}
	{{- end}}
}

type {{ $database }}Crud interface {
	FindAll(ctx context.Context) ([]*model.{{.Name}}, error)
	{{- if eq (len .PrimaryKeyFields) 1}}
	FindAllWithCursor(ctx context.Context, limit int, cursor string) ([]*model.{{.Name}}, error)
	{{- end}}
	{{- if eq (len .PrimaryKeyFields) 1}}
		{{- if and (le (columncount .Fields "CreatedAt" "UpdatedAt" .PrimaryKeyFields) 5) (ne (fieldnames .Fields $short "CreatedAt" "UpdatedAt" .PrimaryKeyFields) "") }}
	Create{{.Name}}(ctx context.Context{{gocustomparamlist .Fields true true "CreatedAt" "UpdatedAt" .PrimaryKeyFields}}) (*model.{{.Name}}, error)
	CreateOrUpdate{{.Name}}(ctx context.Context{{gocustomparamlist .Fields true true "CreatedAt" "UpdatedAt" .PrimaryKeyFields}}) (*model.{{.Name}}, error)
		{{- end }}
	{{- else }}
		{{- if and (le (columncount .Fields "CreatedAt" "UpdatedAt") 7) (ne (fieldnames .Fields $short "CreatedAt" "UpdatedAt") "") }}
	Create{{.Name}}(ctx context.Context{{gocustomparamlist .Fields true true "CreatedAt" "UpdatedAt"}}) (*model.{{.Name}}, error)
	CreateOrUpdate{{.Name}}(ctx context.Context{{gocustomparamlist .Fields true true "CreatedAt" "UpdatedAt"}}) (*model.{{.Name}}, error)
		{{- end }}
	{{- end }}
	Insert{{.Name}}(ctx context.Context, {{$lname}} *model.{{.Name}}) (*model.{{.Name}}, error)
	Update{{.Name}}(ctx context.Context, {{$lname}} *model.{{.Name}}) error
	Delete{{.Name}}(ctx context.Context, {{$lname}} *model.{{.Name}}) error
}

func New{{ $database }}(client *spanner.Client) {{ $database }} {
	return &{{ $name }}{
		Repository: Repository{
			client: client,
		},
	}
}

func ({{$short}} *{{$name}}) Query(ctx context.Context, stmt spanner.Statement) *{{$lname}}Iterator {
	iter := {{$short}}.client.Single().Query(ctx, stmt)

	return &{{$lname}}Iterator{iter, model.{{ .Name }}Columns()}
}

func ({{$short}} *{{$name}}) Insert(ctx context.Context, {{$lname}} *model.{{.Name}}) (*time.Time, error) {
	if err := {{$lname}}.SetIdentity(); err != nil {
		return nil, err
	}
	if {{$lname}}.CreatedAt.IsZero() {
		{{$lname}}.CreatedAt = time.Now()
	}
	if {{$lname}}.UpdatedAt.IsZero() {
		{{$lname}}.UpdatedAt = time.Now()
	}

	mutations := []*spanner.Mutation{
		{{$lname}}.Insert(ctx),
	}
	t, err := {{$short}}.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func ({{$short}} *{{$name}}) InsertOrUpdate(ctx context.Context, {{$lname}} *model.{{.Name}}) (time.Time, error) {
	if err := {{$lname}}.SetIdentity(); err != nil {
		return time.Time{}, err
	}
	if {{$lname}}.CreatedAt.IsZero() {
		{{$lname}}.CreatedAt = time.Now()
	}
	if {{$lname}}.UpdatedAt.IsZero() {
		{{$lname}}.UpdatedAt = time.Now()
	}

	mutations := []*spanner.Mutation{
		{{$lname}}.InsertOrUpdate(ctx),
	}
	t, err := {{$short}}.client.Apply(ctx, mutations)
	if err != nil {
		return time.Time{}, err
	}
	return t, nil
}

func ({{$short}} *{{$name}}) Update(ctx context.Context, {{$lname}} *model.{{.Name}}) (*time.Time, error) {
	{{- range .PrimaryKeyFields }}
	if {{$lname}}.{{ .Name }} == "" {
		return nil, fmt.Errorf("primary_key `{{ colname .Col }}` is blank")
	}{{ end}}
	if {{$lname}}.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	{{$lname}}.UpdatedAt = time.Now()

	mutations := []*spanner.Mutation{
		{{$lname}}.Update(ctx),
	}
	t, err := {{$short}}.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func ({{$short}} *{{$name}}) UpdateColumns(ctx context.Context, {{$lname}} *model.{{.Name}}, cols ...string) (*time.Time, error) {
	{{- range .PrimaryKeyFields }}
	if {{$lname}}.{{ .Name }} == "" {
		return nil, fmt.Errorf("primary_key `{{ colname .Col }}` is blank")
	}{{ end}}
	if {{$lname}}.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	{{$lname}}.UpdatedAt = time.Now()

	mutation, err := {{$lname}}.UpdateColumns(ctx, cols...)
	if err != nil {
		return nil, err
	}
	mutations := []*spanner.Mutation{mutation}
	t, err := {{$short}}.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func ({{$short}} *{{$name}}) UpdateMap(ctx context.Context, {{$lname}} *model.{{.Name}}, {{$lname}}Map map[string]interface{}) (*time.Time, error) {
	{{- range .PrimaryKeyFields }}
	if {{$lname}}.{{ .Name }} == "" {
		return nil, fmt.Errorf("primary_key `{{ colname .Col }}` is blank")
	}{{ end}}
	if {{$lname}}.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	{{$lname}}.UpdatedAt = time.Now()

	mutation := {{ $lname }}.UpdateMap(ctx, {{$lname}}Map)
	mutations := []*spanner.Mutation{mutation}
	t, err := {{$short}}.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func ({{$short}} *{{$name}}) Delete(ctx context.Context, {{$lname}} *model.{{.Name}}) (*time.Time, error) {
	{{- range .PrimaryKeyFields }}
	if {{$lname}}.{{ .Name }} == "" {
		return nil, fmt.Errorf("primary_key `{{ colname .Col }}` is blank")
	}{{ end}}
	if {{$lname}}.CreatedAt.IsZero() {
		return nil, fmt.Errorf("created_at is blank")
	}
	{{$lname}}.UpdatedAt = time.Now()

	mutation := {{ $lname }}.Delete(ctx)
	mutations := []*spanner.Mutation{mutation}
	t, err := {{$short}}.client.Apply(ctx, mutations)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func ({{$short}} *{{$name}}) Builder() *{{$lname}}Builder {
	return &{{$lname}}Builder{
		b:      spannerbuilder.NewSpannerBuilder("{{ $table }}", model.{{ .Name }}Columns(), model.{{ .Name }}PrimaryKeys()),
		client: {{$short}}.client,
	}
}

func (b *{{$lname}}Builder) Select(s string) *{{$lname}}Builder {
	b.b.Select(s)
	return b
}

func (b *{{$lname}}Builder) Join(s string) *{{$lname}}Builder {
	b.b.Join(s)
	return b
}

func (b *{{$lname}}Builder) Where(s string, args ...interface{}) *{{$lname}}Builder {
	b.b.Where(s, args...)
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
	return &{{$lname}}Iterator{iter, b.b.Columns()}
}

func (iter *{{$lname}}Iterator) Into(into *model.{{.Name}}) error {
	defer iter.Stop()

	row, err := iter.Next()
	if err != nil {
		if err == iterator.Done {
			return apierrors.ErrNotFound.Swrapf("{{.Name}} not found: %w", ErrNotFound)
		}
		return fmt.Errorf("into.iter: %w", err)
	}

	err = model.{{ .Name }}_DecodeInto(iter.cols, row, into)
	if err != nil {
		return fmt.Errorf("into.decoder: %w", err)
	}

	return nil
}

func (iter *{{$lname}}Iterator) Intos(into *[]*model.{{.Name}}) error {
	defer iter.Stop()

	for {
		row, err := iter.Next()
		if err != nil {
			if err == iterator.Done {
				break
			}
			return fmt.Errorf("Intos.iter: %w", err)
		}

		{{$short}} := &model.{{.Name}}{}
		err = model.{{ .Name }}_DecodeInto(iter.cols, row, {{$short}})
		if err != nil {
			return fmt.Errorf("Intos.iter: %w", err)
		}

		*into = append(*into, {{$short}})
	}

	return nil
}

func (b *{{$lname}}Builder) QueryCachedInto(ctx context.Context, into **model.{{.Name}}) error {
	stmt := b.b.GetSelectStatement()
	cacheKey, err := getCacheKey(stmt)
	if err != nil {
		return err
	}

	cached := middleware.CacheFromContext(ctx)
	if v, ok := cached.Get(cacheKey); ok {
		if *into, ok = v.(*model.{{.Name}}); ok {
			return nil
		}
	}
	iter := b.client.Single().Query(ctx, stmt)
	it := &{{$lname}}Iterator{iter, b.b.Columns()}
	err = it.Into(*into)
	if err != nil {
		return err
	}
	cached.Set(cacheKey, *into)

	return nil
}

func (b *{{$lname}}Builder) QueryCachedIntos(ctx context.Context, into *[]*model.{{.Name}}) error {
	stmt := b.b.GetSelectStatement()
	cacheKey, err := getCacheKey(stmt)
	if err != nil {
		return err
	}

	cache := middleware.CacheFromContext(ctx)
	if v, ok := cache.Get(cacheKey); ok {
		if *into, ok = v.([]*model.{{.Name}}); ok {
			return nil
		}
	}
	iter := b.client.Single().Query(ctx, stmt)
	it := &{{$lname}}Iterator{iter, b.b.Columns()}
	err = it.Intos(into)
	if err != nil {
		return err
	}
	cache.Set(cacheKey, *into)

	return nil
}

// Get{{.Name}}By
{{- range $i, $f := .PrimaryKeyFields }}{{ if (gt $i 0) }}And{{ end }}{{ .Name }}{{ end }} retrieves a row from '{{ $table }}' as a {{ .Name }}.
// Generated from primary key
func ({{$short}} {{$name}}) Get{{.Name}}By
{{- range $i, $f := .PrimaryKeyFields }}{{ if (gt $i 0) }}And{{ end }}{{ .Name }}{{ end -}}
(ctx context.Context{{ gocustomparamlist .PrimaryKeyFields true true }}) (*model.{{ .Name }}, error) {
	{{ $lname }} := &model.{{ .Name }}{}
	if err := {{$short}}.Builder().
		Where("{{ colnamesquery .PrimaryKeyFields " AND " }}", Params{
		{{- range $i, $f := .PrimaryKeyFields -}}
			{{- if (gt $i 0) }}, {{ end -}}
			"param{{ $i }}": {{ goparamname $f.Name }}
		{{- end}}}).
		Query(ctx).Into({{ $lname }}); err != nil {
		return nil, err
	}

	return {{ $lname }}, nil
}

// Get{{.Name}}By
{{- range $i, $f := .PrimaryKeyFields }}{{ if (gt $i 0) }}And{{ end }}{{ .Name }}{{ end }}Cached retrieves a row from cache or '{{ $table }}' as a {{ .Name }}.
// Generated from primary key
func ({{$short}} {{$name}}) Get{{.Name}}By
{{- range $i, $f := .PrimaryKeyFields }}{{ if (gt $i 0) }}And{{ end }}{{ .Name }}{{ end -}}
Cached(ctx context.Context{{ gocustomparamlist .PrimaryKeyFields true true }}) (*model.{{ .Name }}, error) {
	{{ $lname }} := &model.{{ .Name }}{}
	if err := {{$short}}.Builder().
		Where("{{ colnamesquery .PrimaryKeyFields " AND " }}", Params{
		{{- range $i, $f := .PrimaryKeyFields -}}
			{{- if (gt $i 0) }}, {{ end -}}
			"param{{ $i }}": {{ goparamname $f.Name }}
		{{- end}}}).
		QueryCachedInto(ctx, &{{ $lname }}); err != nil {
		return nil, err
	}

	return {{ $lname }}, nil
}

{{- if eq (len .PrimaryKeyFields) 1 }}

// Find{{.Name}}By{{$pkey0.Name}}s retrieves multiple rows from '{{ $table }}' as []*model.{{ .Name }}.
// Generated from primary key
func ({{$short}} {{$name}}) Find{{.Name}}By{{$pkey0.Name}}s(ctx context.Context, ids []{{$pkey0.Type}}) ([]*model.{{ .Name }}, error) {
	var items []*model.{{ .Name }}
	if err := {{$short}}.Builder().Where("{{colname $pkey0.Col}} IN UNNEST(?)", ids).Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

// Find{{.Name}}By{{$pkey0.Name}}sCached retrieves multiple rows from '{{ $table }}' or cache as []*model.{{ .Name }}.
// Generated from primary key
func ({{$short}} {{$name}}) Find{{.Name}}By{{$pkey0.Name}}sCached(ctx context.Context, ids []{{$pkey0.Type}}) ([]*model.{{ .Name }}, error) {
	var items []*model.{{ .Name }}
	if err := {{$short}}.Builder().Where("{{colname $pkey0.Col}} IN UNNEST(?)", ids).QueryCachedIntos(ctx, &items); err != nil {
		return nil, err
	}

	return items, nil
}
{{- end }}

func ({{$short}} {{$name}}) FindAll(ctx context.Context) ([]*model.{{.Name}}, error) {
	var items []*model.{{.Name}}
	if err := {{$short}}.Builder().Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}

{{- if eq (len .PrimaryKeyFields) 1}}

func ({{$short}} {{$name}}) FindAllWithCursor(ctx context.Context, limit int, cursor string) ([]*model.{{.Name}}, error) {
	items := make([]*model.{{.Name}}, 0)
	builder := {{$short}}.Builder()
	if cursor != "" {
		{{- range .PrimaryKeyFields }}
		builder.Where("{{ colname .Col }} < ?", cursor)
		{{- end}}
	}
	if err := builder.OrderBy("{{- range .PrimaryKeyFields }}{{colname .Col}} DESC{{end}}").Limit(limit).Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}
{{- end }}

func ({{$short}} {{$name}}) Insert{{.Name}}(ctx context.Context, {{$lname}} *model.{{.Name}}) (*model.{{.Name}}, error) {
	if _, err := {{$short}}.Insert(ctx, {{$lname}}); err != nil {
		return nil, err
	}

	return {{$lname}}, nil
}

{{- if eq (len .PrimaryKeyFields) 1}}
{{- if and (le (columncount .Fields "CreatedAt" "UpdatedAt" .PrimaryKeyFields) 5) (ne (fieldnames .Fields $short "CreatedAt" "UpdatedAt" .PrimaryKeyFields ) "") }}

func ({{$short}} {{$name}}) Create{{.Name}}(ctx context.Context{{gocustomparamlist .Fields true true "CreatedAt" "UpdatedAt" .PrimaryKeyFields}}) (*model.{{.Name}}, error) {
	{{$lname}}Entity := &model.{{.Name}}{
	{{- range $i, $f := .Fields -}}
		{{- $skip := false -}}
		{{- if or (eq $f.Name "CreatedAt") (eq $f.Name "UpdatedAt") }}{{ $skip = true }}{{- end -}}
		{{- range $j, $ff := $primaryKeys }}{{ if eq $f.Name $ff.Name }}{{ $skip = true }}{{- end}}{{- end -}}
		{{- if not $skip -}}
			{{if gt $i (len $primaryKeys)}}, {{end}}
			{{- .Name}}: {{ goparamname $f.Name }}
		{{- end -}}
	{{ end -}}
	}
	if _, err := {{$short}}.Insert(ctx, {{$lname}}Entity); err != nil {
		return nil, err
	}

	return {{$lname}}Entity, nil
}

func ({{$short}} {{$name}}) CreateOrUpdate{{.Name}}(ctx context.Context{{gocustomparamlist .Fields true true "CreatedAt" "UpdatedAt" .PrimaryKeyFields}}) (*model.{{.Name}}, error) {
	{{$lname}}Entity := &model.{{.Name}}{
	{{- range $i, $f := .Fields -}}
		{{- $skip := false -}}
		{{- if or (eq $f.Name "CreatedAt") (eq $f.Name "UpdatedAt") }}{{ $skip = true }}{{- end -}}
		{{- range $j, $ff := $primaryKeys }}{{ if eq $f.Name $ff.Name }}{{ $skip = true }}{{- end}}{{- end -}}
		{{- if not $skip -}}
			{{if gt $i (len $primaryKeys)}}, {{end}}
			{{- .Name}}: {{ goparamname $f.Name }}
		{{- end -}}
	{{ end -}}
	}
	if _, err := {{$short}}.InsertOrUpdate(ctx, {{$lname}}Entity); err != nil {
		return nil, err
	}

	return {{$lname}}Entity, nil
}
{{- end}}
{{- else }}
{{ if and (le (columncount .Fields "CreatedAt" "UpdatedAt") 7) (ne (fieldnames .Fields $short "CreatedAt" "UpdatedAt") "") -}}
func ({{$short}} {{$name}}) Create{{.Name}}(ctx context.Context{{gocustomparamlist .Fields true true "CreatedAt" "UpdatedAt"}}) (*model.{{.Name}}, error) {
	{{$lname}}Entity := &model.{{.Name}}{
	{{- range $i, $f := .Fields -}}
		{{- $skip := false -}}
		{{- if or (eq $f.Name "CreatedAt") (eq $f.Name "UpdatedAt") }}{{ $skip = true }}{{- end -}}
		{{- if not $skip -}}
			{{if gt $i 0}}, {{end}}
			{{- .Name}}: {{ goparamname $f.Name }}
		{{- end -}}
	{{ end -}}
	}
	if _, err := {{$short}}.Insert(ctx, {{$lname}}Entity); err != nil {
		return nil, err
	}

	return {{$lname}}Entity, nil
}

func ({{$short}} {{$name}}) CreateOrUpdate{{.Name}}(ctx context.Context{{gocustomparamlist .Fields true true "CreatedAt" "UpdatedAt"}}) (*model.{{.Name}}, error) {
	{{ $primaryKeys := .PrimaryKeyFields -}}
	{{$lname}}Entity := &model.{{.Name}}{
	{{- range $i, $f := .Fields -}}
		{{- $skip := false -}}
		{{- if or (eq $f.Name "CreatedAt") (eq $f.Name "UpdatedAt") }}{{ $skip = true }}{{- end -}}
		{{- if not $skip -}}
			{{if gt $i 0}}, {{end}}
			{{- .Name}}: {{ goparamname $f.Name }}
		{{- end -}}
	{{ end -}}
	}
	if _, err := {{$short}}.InsertOrUpdate(ctx, {{$lname}}Entity); err != nil {
		return nil, err
	}

	return {{$lname}}Entity, nil
}
{{- end}}
{{- end }}

func ({{$short}} {{$name}}) Update{{.Name}}(ctx context.Context, {{$lname}} *model.{{.Name}}) error {
	_, err := {{$short}}.Update(ctx, {{$lname}})
	if err != nil {
		return err
	}
	return nil
}

func ({{$short}} {{$name}}) Delete{{.Name}}(ctx context.Context, {{$lname}} *model.{{.Name}}) error {
	_, err := {{$short}}.Delete(ctx, {{$lname}})
	if err != nil {
		return err
	}
	return nil
}
{{- /* */ -}}
