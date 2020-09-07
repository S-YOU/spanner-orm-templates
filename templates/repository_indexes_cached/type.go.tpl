{{- $short := (shortname .Name "err" "res" "sqlstr" "db" "YOLog") -}}
{{- $table := (.Table.TableName) -}}
{{- $name := (print (goparamname .Name) "Repository") -}}
{{- $typeName := .Name -}}
{{- $lname := (goparamname .Name) -}}
{{- $database := (print .Name "Repository") -}}
{{- $primaryKeys := .PrimaryKeyFields -}}
{{- $pkey0 := (index .PrimaryKeyFields 0) }}

type {{ $database }}IndexesCached interface {
	Get{{.Name}}By{{- range $i, $f := .PrimaryKeyFields }}{{ if $i }}And{{ end }}{{ .Name }}{{ end -}}
		Cached(ctx context.Context{{ goparamlist .PrimaryKeyFields true true }}) (*model.{{ .Name }}, error)
	Find{{.Name}}sBy{{- range $i, $f := .PrimaryKeyFields }}{{ if $i }}And{{ end }}{{ .Name }}s{{ end -}}
		Cached(ctx context.Context{{- range .PrimaryKeyFields }}, {{goparamname .Name}}s []{{.Type}}{{end}}) ([]*model.{{ .Name }}, error)
	{{- range .Indexes -}}
		{{- if not .Index.IsUnique }}
	Find{{$typeName}}sBy{{- range $i, $f := .Fields }}{{ if $i }}And{{ end }}{{ .Name }}{{ end }}Cached(ctx context.Context{{ goparamlist .Fields true true }}) ([]*model.{{ .Type.Name }}, error)
		{{- else }}
	Get{{ .FuncName }}Cached(ctx context.Context{{ goparamlist .Fields true true }}) (*model.{{ .Type.Name }}, error)
		{{- end }}
	Find{{$typeName}}sBy{{- range $i, $f := .Fields }}{{ if $i }}And{{ end }}{{ .Name }}{{ end }}sCached(ctx context.Context{{- range .Fields }}, {{goparamname .Name}}s []{{.Type}}{{end}}) ([]*model.{{ .Type.Name }}, error)
	{{- end}}
}

// Get{{.Name}}By
{{- range $i, $f := .PrimaryKeyFields }}{{ if $i }}And{{ end }}{{ .Name }}{{ end }}Cached retrieves a row from cache or '{{ $table }}' as a {{ .Name }}.
// Generated from primary key
func ({{$short}} {{$name}}) Get{{.Name}}By
{{- range $i, $f := .PrimaryKeyFields }}{{ if $i }}And{{ end }}{{ .Name }}{{ end -}}
Cached(ctx context.Context{{ gocustomparamlist .PrimaryKeyFields true true }}) (*model.{{ .Name }}, error) {
	{{ $lname }} := &model.{{ .Name }}{}
	if err := {{$short}}.Builder().
		Where("{{ colnamesquery .PrimaryKeyFields " AND " }}", Params{
		{{- range $i, $f := .PrimaryKeyFields -}}
			{{- if $i }}, {{ end -}}
			"param{{ $i }}": {{ goparamname $f.Name }}
		{{- end}}}).
		QueryCachedInto(ctx, &{{ $lname }}); err != nil {
		return nil, err
	}

	return {{ $lname }}, nil
}

// Find{{.Name}}sBy{{- range $i, $f := .PrimaryKeyFields }}{{ if $i }}And{{ end }}{{ .Name }}s{{ end -}}Cached retrieves multiple rows from '{{ $table }}' or cache as []*model.{{ .Name }}.
// Generated from primary key
func ({{$short}} {{$name}}) Find{{.Name}}sBy{{- range $i, $f := .PrimaryKeyFields }}{{ if $i }}And{{ end }}{{ .Name }}s{{ end -}}
	Cached(ctx context.Context{{- range .PrimaryKeyFields }}, {{goparamname .Name}}s []{{.Type}}{{end}}) ([]*model.{{ .Name }}, error) {
	var items []*model.{{ .Name }}
	if err := {{$short}}.Builder().Where("{{- range $i, $f := .PrimaryKeyFields }}{{ if $i }} AND {{ end }}{{colname $f.Col}} IN UNNEST(@arg{{$i}}){{ end -}}", Params{
	{{- range $i, $f := .PrimaryKeyFields -}}
		{{- if $i }}, {{ end -}}
		"arg{{ $i }}": {{ goparamname $f.Name }}s
	{{- end}}}).
		QueryCachedIntos(ctx, &items); err != nil {
		return nil, err
	}

	return items, nil
}
{{- /* */ -}}
