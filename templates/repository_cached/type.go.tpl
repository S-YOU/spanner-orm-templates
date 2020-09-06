{{- $short := (shortname .Name "err" "res" "sqlstr" "db" "YOLog") -}}
{{- $table := (.Table.TableName) -}}
{{- $name := (print (goparamname .Name) "Repository") -}}
{{- $lname := (goparamname .Name) -}}
{{- $database := (print .Name "Repository") -}}
{{- $primaryKeys := .PrimaryKeyFields -}}
{{- $pkey0 := (index .PrimaryKeyFields 0) }}

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
{{- /* */ -}}
