{{- $short := (shortname .Name "err" "res" "sqlstr" "db" "YOLog") }}
{{- $name := (print (goparamname .Name) "Repository") }}
{{- $typeName := .Name }}
{{- $database := (print .Name "Repository") }}
{{- $pfields := .PrimaryKeyFields }}
{{- $indexes := .Indexes }}

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
			{{- $inPkey := false }}
			{{- range $_, $p := $pfields }}{{ if eq $p.Name $i.Name }}{{ $inPkey = true }}{{ end }}{{- end}}
			{{- $inPrevKey := false }}{{- $foundCurKey := false }}
			{{- range $_, $idx1 := $indexes }}{{if eq $idx1.Index.IndexName $idx.Index.IndexName}}{{$foundCurKey = true}}{{end}}{{if not $foundCurKey}}{{- range $_, $i1 := .Fields }}{{ if eq $i1.Name $i.Name }}{{ $inPrevKey = true }}{{ end }}{{ end}}{{ end }}{{end }}
			{{- if not (or $inPkey $inPrevKey) }}
	{{ pluralize .Name }}(in []*model.{{$typeName}}) []{{.Type}}
				{{- if and $idx.Index.IsUnique (eq (len $idx.Fields) 1) }}
	{{.Name}}To{{ $typeName }}Map(in []*model.{{$typeName}}) map[{{.Type}}]*model.{{$typeName}}
				{{- else }}
	{{.Name}}To{{ pluralize $typeName }}Map(in []*model.{{$typeName}}) map[{{.Type}}][]*model.{{$typeName}}
				{{- end }}
			{{- end }}
		{{- end }}
	{{- end }}
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
{{- $inPkey := false }}
{{- range $_, $p := $pfields }}{{ if eq $p.Name $i.Name }}{{ $inPkey = true }}{{ end }}{{- end}}
{{- $inPrevKey := false }}{{- $foundCurKey := false }}
{{- range $_, $idx1 := $indexes }}{{if eq $idx1.Index.IndexName $idx.Index.IndexName}}{{$foundCurKey = true}}{{end}}{{if not $foundCurKey}}{{- range $_, $i1 := .Fields }}{{ if eq $i1.Name $i.Name }}{{ $inPrevKey = true }}{{ end }}{{ end}}{{ end }}{{end }}
{{- if not (or $inPkey $inPrevKey) }}

func ({{$short}} {{$name}}) {{ pluralize .Name }}(in []*model.{{$typeName}}) []{{.Type}} {
	items := make([]{{.Type}}, len(in))
	for i, x := range in {
		items[i] = x.{{.Name}}
	}
	return items
}
{{- if and $idx.Index.IsUnique (eq (len $idx.Fields) 1) }}

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
{{- end }}
{{- end }}{{ end }}{{ end }}
{{- /* */ -}}
