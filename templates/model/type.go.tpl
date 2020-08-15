{{- $short := (shortname .Name "err" "res" "sqlstr" "db") -}}
{{- $lname := (.Name | tolower) -}}
{{- $table := (.Table.TableName) -}}

{{ if .PrimaryKey }}
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

func ({{ $short }} *{{ .Name }}) columnsToPtrs(cols []string, customPtrs map[string]interface{}) ([]interface{}, error) {
	ret := make([]interface{}, 0, len(cols))
	for _, col := range cols {
		if val, ok := customPtrs[col]; ok {
			ret = append(ret, val)
			continue
		}

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

// {{ .Name }}_DecodeInto decodes row into *{{.Name}}
// The decoder is not goroutine-safe. Don't use it concurrently.
func {{ .Name }}_DecodeInto(cols []string, row *spanner.Row, into *{{.Name}}) error {
	customPtrs := map[string]interface{}{}

	ptrs, err := into.columnsToPtrs(cols, customPtrs)
	if err != nil {
		return err
	}

	if err := row.Columns(ptrs...); err != nil {
		return err
	}

	return nil
}

// Insert returns a Mutation to insert a row into a table. If the row already
// exists, the write or transaction fails.
func ({{ $short }} *{{ .Name }}) Insert(ctx context.Context) *spanner.Mutation {
	{{ $short }}.CreatedAt = time.Now()
	{{ $short }}.UpdatedAt = time.Now()
	return spanner.Insert("{{ $table }}", {{ .Name }}Columns(), []interface{}{
		{{ fieldnames .Fields $short }},
	})
}

{{- if ne (fieldnames .Fields $short .PrimaryKeyFields) "" }}

// Update returns a Mutation to update a row in a table. If the row does not
// already exist, the write or transaction fails.
func ({{ $short }} *{{ .Name }}) Update(ctx context.Context) *spanner.Mutation {
	{{ $short }}.UpdatedAt = time.Now()
	return spanner.Update("{{ $table }}", {{ .Name }}Columns(), []interface{}{
		{{ fieldnames .Fields $short }},
	})
}

// UpdateMap returns a Mutation to update a row in a table. If the row does not
// already exist, the write or transaction fails.
func ({{ $short }} *{{ .Name }}) UpdateMap(ctx context.Context, {{ $lname }}Map map[string]interface{}) *spanner.Mutation {
	{{ $lname }}Map["updated_at"] = time.Now()
	// add primary keys to columns to update by primary keys
	{{- range .PrimaryKeyFields }}
	{{ $lname }}Map["{{colname .Col}}"] = {{ $short }}.{{.Name}}
	{{- end }}
	return spanner.UpdateMap("{{ $table }}", {{ $lname }}Map)
}

// InsertOrUpdate returns a Mutation to insert a row into a table. If the row
// already exists, it updates it instead. Any column values not explicitly
// written are preserved.
func ({{ $short }} *{{ .Name }}) InsertOrUpdate(ctx context.Context) *spanner.Mutation {
	if {{ $short }}.CreatedAt.IsZero() {
		{{ $short }}.CreatedAt = time.Now()
	}
	{{ $short }}.UpdatedAt = time.Now()
	return spanner.InsertOrUpdate("{{ $table }}", {{ .Name }}Columns(), []interface{}{
		{{ fieldnames .Fields $short }},
	})
}

// UpdateColumns returns a Mutation to update specified columns of a row in a table.
func ({{ $short }} *{{ .Name }}) UpdateColumns(ctx context.Context, cols ...string) (*spanner.Mutation, error) {
	{{ $short }}.UpdatedAt = time.Now()
	cols = append(cols, "updated_at")
	// add primary keys to columns to update by primary keys
	colsWithPKeys := append(cols, {{ .Name }}PrimaryKeys()...)

	values, err := {{ $short }}.columnsToValues(colsWithPKeys)
	if err != nil {
		return nil, fmt.Errorf("invalid argument: {{ .Name }}.UpdateColumns {{ $table }}: %w", err)
	}

	return spanner.Update("{{ $table }}", colsWithPKeys, values), nil
}
{{- end }}

// Delete deletes the {{ .Name }} from the database.
func ({{ $short }} *{{ .Name }}) Delete(ctx context.Context) *spanner.Mutation {
	values, _ := {{ $short }}.columnsToValues({{ .Name }}PrimaryKeys())
	return spanner.Delete("{{ $table }}", spanner.Key(values))
}
