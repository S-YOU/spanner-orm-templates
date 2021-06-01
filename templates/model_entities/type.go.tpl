{{- $short := (shortname .Name "err" "res" "sqlstr" "db") -}}
{{- $lname := (.Name | tolower) -}}
{{- $table := (.Table.TableName) }}
// {{ .Name }} represents a row from '{{ $table }}'.
type {{ .Name }} struct {
{{- range .Fields }}
{{- if eq (.Col.DataType) (.Col.ColumnName) }}
	{{ .Name | printf "%-9s" }} string    `spanner:"{{ .Col.ColumnName }}" json:"{{ goparamname .Name }}"`
{{- else if .CustomType }}
	{{ .Name | printf "%-9s" }} {{ retype .CustomType | printf "%-9s" }} `spanner:"{{ .Col.ColumnName }}" json:"{{ goparamname .Name }}"`
{{- else }}
	{{ .Name | printf "%-9s" }} {{ .Type | printf "%-9s" }} `spanner:"{{ .Col.ColumnName }}" json:"{{ goparamname .Name }}"`
{{- end }}
{{- end }}
}
