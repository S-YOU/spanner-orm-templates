{{- $pkeys := .Type.PrimaryKeyFields -}}
{{- $fkeys := .Fields -}}
{{- $skeys := .StoringFields -}}

var {{ .Index.IndexName }}_cols = []string{
	{{ range $i, $x := $pkeys }}{{if $i}} {{end}}"{{ colname .Col }}",{{ end -}}
	{{ range $i, $x := $fkeys }}{{if (or $i (len $pkeys))}} {{end}}"{{ colname .Col }}",{{ end -}}
	{{ range $i, $x := $skeys }}{{if (or $i (len $pkeys) (len $fkeys))}} {{end}}"{{ colname .Col }}",{{ end }}
}
