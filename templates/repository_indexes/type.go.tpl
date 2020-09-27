{{- $short := (shortname .Name "err" "res" "sqlstr" "db" "YOLog") -}}
{{- $table := (.Table.TableName) -}}
{{- $name := (print (goparamname .Name) "Repository") -}}
{{- $typeName := .Name -}}
{{- $lname := (goparamname .Name) -}}
{{- $database := (print .Name "Repository") -}}
{{- $primaryKeys := .PrimaryKeyFields -}}
{{- $pkey0 := (index .PrimaryKeyFields 0) }}

type {{ $database }}Indexes interface {
	Get{{.Name}}By{{- range $i, $f := .PrimaryKeyFields }}{{ if $i }}And{{ end }}{{ .Name }}{{ end -}}
		(ctx context.Context{{ goparamlist .PrimaryKeyFields true true }}) (*model.{{ .Name }}, error)
	Find{{pluralize .Name}}By{{- range $i, $f := .PrimaryKeyFields }}{{ if $i }}And{{ end }}{{ pluralize .Name }}{{ end -}}
		(ctx context.Context{{- range .PrimaryKeyFields }}, {{goparamname (pluralize .Name)}} []{{.Type}}{{end}}) ([]*model.{{ .Name }}, error)
	{{- range .Indexes -}}
		{{- if not .Index.IsUnique }}
	Find{{pluralize $typeName}}By{{- range $i, $f := .Fields }}{{ if $i }}And{{ end }}{{ .Name }}{{ end }}(ctx context.Context{{ goparamlist .Fields true true }}) ([]*model.{{ .Type.Name }}, error)
	Find{{pluralize $typeName}}By{{- range $i, $f := .Fields }}{{ if $i }}And{{ end }}{{ .Name }}{{ end }}Fast(ctx context.Context{{ goparamlist .Fields true true }}) ([]*model.{{ .Type.Name }}, error)
		{{- else }}
	Get{{ .FuncName }}(ctx context.Context{{ goparamlist .Fields true true }}) (*model.{{ .Type.Name }}, error)
	Get{{ .FuncName }}Fast(ctx context.Context{{ goparamlist .Fields true true }}) (*model.{{ .Type.Name }}, error)
		{{- end }}
	Find{{pluralize $typeName}}By{{- range $i, $f := .Fields }}{{ if $i }}And{{ end }}{{pluralize .Name }}{{ end }}(ctx context.Context{{- range .Fields }}, {{goparamname (pluralize .Name)}} []{{.Type}}{{end}}) ([]*model.{{ .Type.Name }}, error)
	{{- end}}
}

// Get{{.Name}}By
{{- range $i, $f := .PrimaryKeyFields }}{{ if $i }}And{{ end }}{{ .Name }}{{ end }} retrieves a row from '{{ $table }}' as a {{ .Name }}.
// Generated from primary key. This is a fast method that can retrieve all columns
func ({{$short}} {{$name}}) Get{{.Name}}By
{{- range $i, $f := .PrimaryKeyFields }}{{ if $i }}And{{ end }}{{ .Name }}{{ end -}}
(ctx context.Context{{ gocustomparamlist .PrimaryKeyFields true true }}) (*model.{{ .Name }}, error) {
	{{ $lname }} := &model.{{ .Name }}{}
	if err := {{$short}}.Read(ctx, Key{ {{- gocustomparamlist .PrimaryKeyFields false false -}} }).Into({{$lname}}); err != nil {
		return nil, err
	}

	return {{ $lname }}, nil
}

// Find{{pluralize .Name}}By{{- range $i, $f := .PrimaryKeyFields }}{{ if $i }}And{{ end }}{{ pluralize .Name }}{{ end }} retrieves multiple rows from '{{ $table }}' as []*model.{{ .Name }}.
// Generated from primary key
func ({{$short}} {{$name}}) Find{{pluralize .Name}}By{{- range $i, $f := .PrimaryKeyFields }}{{ if $i }}And{{ end }}{{ pluralize .Name }}{{ end -}}
	(ctx context.Context{{- range .PrimaryKeyFields }}, {{goparamname (pluralize .Name)}} []{{.Type}}{{end}}) ([]*model.{{ .Name }}, error) {
	var items []*model.{{ .Name }}
	if err := {{$short}}.Builder().Where("{{- range $i, $f := .PrimaryKeyFields }}{{ if $i }} AND {{ end }}{{colname $f.Col}} IN UNNEST(@arg{{$i}}){{ end -}}", Params{
	{{- range $i, $f := .PrimaryKeyFields -}}
		{{- if $i }}, {{ end -}}
		"arg{{ $i }}": {{goparamname (pluralize .Name)}}
	{{- end}}}).Query(ctx).Intos(&items); err != nil {
		return nil, err
	}

	return items, nil
}
{{- /* */ -}}
