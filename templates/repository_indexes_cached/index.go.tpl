{{- $short := (shortname .Type.Name "err" "sqlstr" "db" "q" "res" .Fields) -}}
{{- $name := (print (goparamname .Type.Name ) "Repository") -}}
{{- $table := (.Type.Table.TableName) -}}
{{- $typeName := .Type.Name -}}
{{- $database := (print .Type.Name "Repository") -}}
{{- $lname := (goparamname .Type.Name) -}}
{{- $idx0 := (index .Fields 0) }}

{{- if not .Index.IsUnique }}

// Get{{pluralize $typeName}}By{{- range $i, $f := .Fields }}{{ if $i }}And{{ end }}{{ .Name }}{{ end }}Cached retrieves multiple rows from cache or '{{ $table }}' as a slice of {{ .Type.Name }}.
// Generated from index '{{ .Index.IndexName }}'.
func ({{$short}} {{$name}}) Find{{pluralize $typeName}}By{{- range $i, $f := .Fields }}{{ if $i }}And{{ end }}{{ .Name }}{{ end }}Cached(ctx context.Context{{ goparamlist .Fields true true }}) ([]*model.{{ .Type.Name }}, error) {
	{{ $lname }} := []*model.{{ .Type.Name }}{}
	if err := {{$short}}.Builder().
		Where("{{ colnamesquery .Fields " AND " }}", Params{
		{{- range $i, $f := .Fields -}}
			{{- if $i }}, {{ end -}}
			"param{{ $i }}": {{ goparamname $f.Name }}
		{{- end}}}).
		QueryCachedIntos(ctx, &{{ $lname }}); err != nil {
		return nil, err
	}

	return {{ $lname }}, nil
}
{{- else }}

// Find{{ .FuncName }}Cached retrieves a row from cache or '{{ $table }}' as a {{ .Type.Name }}.
// Generated from unique index '{{ .Index.IndexName }}'.
func ({{$short}} {{$name}}) Get{{ .FuncName }}Cached(ctx context.Context{{ goparamlist .Fields true true }}) (*model.{{ .Type.Name }}, error) {
	{{ $lname }} := &model.{{ .Type.Name }}{}
	if err := {{$short}}.Builder().
		Where("{{ colnamesquery .Fields " AND " }}", Params{
		{{- range $i, $f := .Fields -}}
			{{- if $i }}, {{ end -}}
			"param{{ $i }}": {{ goparamname $f.Name }}
		{{- end}}}).
		QueryCachedInto(ctx, &{{ $lname }}); err != nil {
		return nil, err
	}

	return {{ $lname }}, nil
}
{{- end }}

// Find{{pluralize $typeName}}By{{- range $i, $f := .Fields }}{{ if $i }}And{{ end }}{{pluralize .Name }}{{ end }}Cached retrieves multiple rows from '{{ $table }}' or from cache as []*model.{{ .Type.Name }}.
// Generated from unique index '{{ .Index.IndexName }}'.
func ({{$short}} {{$name}}) Find{{pluralize $typeName}}By{{- range $i, $f := .Fields }}{{ if $i }}And{{ end }}{{pluralize .Name }}{{ end }}Cached(ctx context.Context{{- range .Fields }}, {{goparamname (pluralize .Name)}} []{{.Type}}{{end}}) ([]*model.{{ .Type.Name }}, error) {
	var items []*model.{{ .Type.Name }}
	if err := {{$short}}.Builder().Where("{{- range $i, $f := .Fields }}{{ if $i }} AND {{ end }}{{colname $f.Col}} IN UNNEST(@arg{{$i}}){{ end -}}", Params{
	{{- range $i, $f := .Fields -}}
		{{- if $i }}, {{ end -}}
		"arg{{ $i }}": {{goparamname (pluralize .Name)}}
	{{- end}}}).QueryCachedIntos(ctx, &items); err != nil {
		return nil, err
	}

	return items, nil
}
