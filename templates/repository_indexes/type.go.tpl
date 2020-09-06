{{- $short := (shortname .Name "err" "res" "sqlstr" "db" "YOLog") -}}
{{- $table := (.Table.TableName) -}}
{{- $name := (print (goparamname .Name) "Repository") -}}
{{- $lname := (goparamname .Name) -}}
{{- $database := (print .Name "Repository") -}}
{{- $primaryKeys := .PrimaryKeyFields -}}
{{- $pkey0 := (index .PrimaryKeyFields 0) }}

type {{ $database }}Indexes interface {
	Get{{.Name}}By{{- range $i, $f := .PrimaryKeyFields }}{{ if (gt $i 0) }}And{{ end }}{{ .Name }}{{ end -}}
		(ctx context.Context{{ goparamlist .PrimaryKeyFields true true }}) (*model.{{ .Name }}, error)
	Find{{.Name}}sBy{{- range $i, $f := .PrimaryKeyFields }}{{ if (gt $i 0) }}And{{ end }}{{ .Name }}s{{ end -}}
		(ctx context.Context{{- range .PrimaryKeyFields }}, {{goparamname .Name}}s []{{.Type}}{{end}}) ([]*model.{{ .Name }}, error)
	{{- range .Indexes -}}
		{{- if not .Index.IsUnique }}
	Find{{ .FuncName }}(ctx context.Context{{ goparamlist .Fields true true }}) ([]*model.{{ .Type.Name }}, error)
		{{- else }}
	Get{{ .FuncName }}(ctx context.Context{{ goparamlist .Fields true true }}) (*model.{{ .Type.Name }}, error)
		{{- end }}
		{{- if eq (len .Fields) 1 -}}
		{{- $f0 := (index .Fields 0) }}
	Find{{.FuncName}}s(ctx context.Context, ids []{{$f0.Type}}) ([]*model.{{ .Type.Name }}, error)
		{{- end }}
	{{- end}}
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

// Find{{.Name}}sBy{{- range $i, $f := .PrimaryKeyFields }}{{ if (gt $i 0) }}And{{ end }}{{ .Name }}s{{ end }} retrieves multiple rows from '{{ $table }}' as []*model.{{ .Name }}.
// Generated from primary key
func ({{$short}} {{$name}}) Find{{.Name}}sBy{{- range $i, $f := .PrimaryKeyFields }}{{ if (gt $i 0) }}And{{ end }}{{ .Name }}s{{ end -}}
	(ctx context.Context{{- range .PrimaryKeyFields }}, {{goparamname .Name}}s []{{.Type}}{{end}}) ([]*model.{{ .Name }}, error) {
	var items []*model.{{ .Name }}
	if err := {{$short}}.Builder().Where("{{- range $i, $f := .PrimaryKeyFields }}{{ if (gt $i 0) }} AND {{ end }}{{colname $f.Col}} IN UNNEST(@arg{{$i}}){{ end -}}", Params{
	{{- range $i, $f := .PrimaryKeyFields -}}
		{{- if (gt $i 0) }}, {{ end -}}
		"arg{{ $i }}": {{ goparamname $f.Name }}s
	{{- end}}}).
		Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}
{{- /* */ -}}
