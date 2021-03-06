{{- $short := (shortname .Name "err" "res" "sqlstr" "db") -}}
{{- $lname := (.Name | tolower) -}}
{{- $table := (.Table.TableName) }}
{{- if .PrimaryKey }}
func {{ .Name }}PrimaryKeys() []string {
	return []string{
{{- range .PrimaryKeyFields }}
		"{{ colname .Col }}",
{{- end }}
	}
}
{{- end }}

func {{ .Name }}Columns() []string {
	return []string{
{{- range .Fields }}
		"{{ colname .Col }}",
{{- end }}
	}
}

func {{ .Name }}ColumnsByIndexName(index string) []string {
	{{ if .Indexes -}}
	switch index {
	{{ range .Indexes -}}
	case "{{.Index.IndexName}}":
		return {{.Index.IndexName}}_cols
	{{ end }}}
	{{ end -}}
	return nil
}

func ({{ $short }} *{{ .Name }}) ColumnsToPtrs(cols []string) ([]interface{}, error) {
	ret := make([]interface{}, 0, len(cols))
	for _, col := range cols {
		switch col {
{{- range .Fields }}
		case "{{ colname .Col }}":
			ret = append(ret, &{{ $short }}.{{ .Name }})
{{- end }}
		default:
			return nil, fmt.Errorf("unknown column: %s", col)
		}
	}
	return ret, nil
}

func ({{ $short }} *{{ .Name }}) Ptrs() []interface{} {
	return []interface{}{
	{{- range .Fields }}
		&{{ $short }}.{{ .Name }},
	{{- end }}
	}
}

func ({{ $short }} *{{ .Name }}) columnsToValues(cols []string) ([]interface{}, error) {
	ret := make([]interface{}, 0, len(cols))
	for _, col := range cols {
		switch col {
{{- range .Fields }}
		case "{{ colname .Col }}":
			ret = append(ret, {{ $short }}.{{ .Name }})
{{- end }}
		default:
			return nil, fmt.Errorf("unknown column: %s", col)
		}
	}

	return ret, nil
}
