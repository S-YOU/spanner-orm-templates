{{- $short := (shortname .Name "err" "res" "sqlstr" "db") -}}
{{- $lname := (.Name | tolower) -}}

{{- if .PrimaryKey }}
func ({{$short}} *{{.Name}}) SetIdentity() (err error) {
	{{- if eq (len .PrimaryKeyFields) 1 }}
	{{- range .PrimaryKeyFields }}
	{{- if eq .Type "string" }}
	if {{$short}}.{{.Name}} == "" {
		{{$short}}.{{.Name}}, err = NewUUID()
	}
	{{- end }}
	{{- end }}
	{{- end }}
	return
}
{{- end }}
