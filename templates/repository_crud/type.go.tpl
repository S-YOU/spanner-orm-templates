{{- $short := (shortname .Name "err" "res" "sqlstr" "db" "YOLog") -}}
{{- $table := (.Table.TableName) -}}
{{- $name := (print (goparamname .Name) "Repository") -}}
{{- $lname := (goparamname .Name) -}}
{{- $database := (print .Name "Repository") -}}
{{- $primaryKeys := .PrimaryKeyFields -}}
{{- $pkey0 := (index .PrimaryKeyFields 0) }}

type {{ $database }}CRUD interface {
	FindAll(ctx context.Context) ([]*model.{{.Name}}, error)
	{{- if eq (len .PrimaryKeyFields) 1}}
	FindAllWithCursor(ctx context.Context, limit int, cursor string) ([]*model.{{.Name}}, error)
	{{- end}}
	{{- if le (columncount .Fields "CreatedAt" "UpdatedAt" .PrimaryKeyFields) 5 }}
		{{- if eq (len .PrimaryKeyFields) 1}}
	Create{{.Name}}(ctx context.Context{{gocustomparamlist .Fields true true "CreatedAt" "UpdatedAt" .PrimaryKeyFields}}) (*model.{{.Name}}, error)
		{{- else }}
	Create{{.Name}}(ctx context.Context{{gocustomparamlist .Fields true true "CreatedAt" "UpdatedAt"}}) (*model.{{.Name}}, error)
		{{- end }}
	CreateOrUpdate{{.Name}}(ctx context.Context{{gocustomparamlist .Fields true true "CreatedAt" "UpdatedAt"}}) (*model.{{.Name}}, error)
	{{- end }}
	Insert{{.Name}}(ctx context.Context, {{$lname}} *model.{{.Name}}) (*model.{{.Name}}, error)
	Update{{.Name}}(ctx context.Context, {{$lname}} *model.{{.Name}}) error
	Delete{{.Name}}(ctx context.Context, {{$lname}} *model.{{.Name}}) error
}

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

{{- if le (columncount .Fields "CreatedAt" "UpdatedAt" .PrimaryKeyFields) 5 }}
{{- if eq (len .PrimaryKeyFields) 1}}

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
{{- else }}
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
{{- end}}

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
