{{- $short := (shortname .Name "err" "res" "sqlstr" "db" "YOLog") }}
{{- $name := (print (goparamname .Name) "Repository") }}
{{- $typeName := .Name }}
{{- $database := (print .Name "Repository") }}
{{- $pfields := .PrimaryKeyFields }}

type {{ $database }}Util interface {
	{{- range .PrimaryKeyFields }}
	{{ pluralize .Name }}(in []*model.{{$typeName}}) []{{.Type}}
	{{- if eq (len $pfields) 1 }}
	{{.Name}}To{{ $typeName }}Map(in []*model.{{$typeName}}) map[{{.Type}}]*model.{{$typeName}}
	{{- else }}
	{{.Name}}To{{ pluralize $typeName }}Map(in []*model.{{$typeName}}) map[{{.Type}}][]*model.{{$typeName}}
	{{- end }}{{ end }}
	{{- range $_, $idx := .Indexes }}
	{{- range $_, $i := .Fields }}
	{{- $done := false }}{{ range $_, $p := $pfields }}{{ if eq $p.Name $i.Name }}{{ $done = true }}{{ end }}{{end}}
	{{- if not $done }}
	{{ pluralize .Name }}(in []*model.{{$typeName}}) []{{.Type}}
	{{- if and $idx.Index.IsUnique (eq (len $idx.Fields) 1) }}
	{{.Name}}To{{ $typeName }}Map(in []*model.{{$typeName}}) map[{{.Type}}]*model.{{$typeName}}
	{{- else }}
	{{.Name}}To{{ pluralize $typeName }}Map(in []*model.{{$typeName}}) map[{{.Type}}][]*model.{{$typeName}}
	{{- end }}
	{{- end }}{{ end }}{{ end }}
}

{{- range .PrimaryKeyFields }}

func ({{$short}} {{$name}}) {{ pluralize .Name }}(in []*model.{{$typeName}}) []{{.Type}} {
	items := make([]{{.Type}}, len(in))
	for i, x := range in {
		items[i] = x.{{.Name}}
	}
	return items
}
{{- if eq (len $pfields) 1 }}

func ({{$short}} {{$name}}) {{.Name}}To{{ $typeName }}Map(in []*model.{{$typeName}}) map[{{.Type}}]*model.{{$typeName}} {
	itemMap := make(map[{{.Type}}]*model.{{$typeName}})
	for _, x := range in {
		itemMap[x.{{.Name}}] = x
	}
	return itemMap
}
{{- else }}

func ({{$short}} {{$name}}) {{.Name}}To{{ pluralize $typeName }}Map(in []*model.{{$typeName}}) map[{{.Type}}][]*model.{{$typeName}} {
	itemMap := make(map[{{.Type}}][]*model.{{$typeName}})
	for _, x := range in {
		if _, ok := itemMap[x.{{.Name}}]; !ok {
			itemMap[x.{{.Name}}] = make([]*model.{{$typeName}}, 0)
		}
		itemMap[x.{{.Name}}] = append(itemMap[x.{{.Name}}], x)
	}
	return itemMap
}
{{- end }}{{ end }}

{{- range $_, $idx := .Indexes }}
{{- range $_, $i := .Fields }}
{{- $done := false }}{{ range $_, $p := $pfields }}{{ if eq $p.Name $i.Name }}{{ $done = true }}{{ end }}{{end}}
{{- if not $done }}

func ({{$short}} {{$name}}) {{ pluralize .Name }}(in []*model.{{$typeName}}) []{{.Type}} {
	items := make([]{{.Type}}, len(in))
	for i, x := range in {
		items[i] = x.{{.Name}}
	}
	return items
}
{{- if and $idx.Index.IsUnique (eq (len $idx.Fields) 1) }}

func ({{$short}} {{$name}}) {{.Name}}To{{ $typeName }}Map(in []*model.{{$typeName}}) map[{{.Type}}]*model.{{$typeName}} { // Unique
	itemMap := make(map[{{.Type}}]*model.{{$typeName}})
	for _, x := range in {
		itemMap[x.{{.Name}}] = x
	}
	return itemMap
}
{{- else }}

func ({{$short}} {{$name}}) {{.Name}}To{{ pluralize $typeName }}Map(in []*model.{{$typeName}}) map[{{.Type}}][]*model.{{$typeName}} { // Not Unique
	itemMap := make(map[{{.Type}}][]*model.{{$typeName}})
	for _, x := range in {
		if _, ok := itemMap[x.{{.Name}}]; !ok {
			itemMap[x.{{.Name}}] = make([]*model.{{$typeName}}, 0)
		}
		itemMap[x.{{.Name}}] = append(itemMap[x.{{.Name}}], x)
	}
	return itemMap
}
{{- end }}
{{- end }}{{ end }}{{ end }}
{{- /* */ -}}
