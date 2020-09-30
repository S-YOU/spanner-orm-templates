{{- $short := (shortname .Name "err" "res" "sqlstr" "db") }}
{{- $lname := (.Name | tolower) }}
{{- $hasCreatedAt := false }}
{{- $hasUpdatedAt := false }}
{{- range .Fields }}
{{- if eq .Name "CreatedAt"}}{{ $hasCreatedAt = true}}
{{- else if eq .Name "UpdatedAt"}}{{ $hasUpdatedAt = true}}{{- end }}
{{- end }}
{{- $table := (.Table.TableName) }}
// Insert returns a Mutation to insert a row into a table. If the row already
// exists, the write or transaction fails.
func ({{ $short }} *{{ .Name }}) Insert() *spanner.Mutation {
{{- if $hasCreatedAt }}
	{{ $short }}.CreatedAt = time.Now()
{{- end }}
{{- if $hasUpdatedAt }}
	{{ $short }}.UpdatedAt = time.Now()
{{- end }}
	return spanner.Insert("{{ $table }}", {{ .Name }}Columns(), []interface{}{
		{{ fieldnames .Fields $short }},
	})
}

{{- if ne (fieldnames .Fields $short .PrimaryKeyFields) "" }}

// Update returns a Mutation to update a row in a table. If the row does not
// already exist, the write or transaction fails.
func ({{ $short }} *{{ .Name }}) Update() *spanner.Mutation {
{{- if $hasUpdatedAt }}
	{{ $short }}.UpdatedAt = time.Now()
{{- end }}
	return spanner.Update("{{ $table }}", {{ .Name }}Columns(), []interface{}{
		{{ fieldnames .Fields $short }},
	})
}

// UpdateMap returns a Mutation to update a row in a table. If the row does not
// already exist, the write or transaction fails.
func ({{ $short }} *{{ .Name }}) UpdateMap({{ $lname }}Map map[string]interface{}) *spanner.Mutation {
{{- if $hasUpdatedAt }}
	{{ $lname }}Map["updated_at"] = time.Now()
{{- end }}
	// add primary keys to columns to update by primary keys
	{{- range .PrimaryKeyFields }}
	{{ $lname }}Map["{{colname .Col}}"] = {{ $short }}.{{.Name}}
	{{- end }}
	return spanner.UpdateMap("{{ $table }}", {{ $lname }}Map)
}

// InsertOrUpdate returns a Mutation to insert a row into a table. If the row
// already exists, it updates it instead. Any column values not explicitly
// written are preserved.
func ({{ $short }} *{{ .Name }}) InsertOrUpdate() *spanner.Mutation {
{{- if $hasCreatedAt }}
	if {{ $short }}.CreatedAt.IsZero() {
		{{ $short }}.CreatedAt = time.Now()
	}
{{- end }}
{{- if $hasUpdatedAt }}
	{{ $short }}.UpdatedAt = time.Now()
{{- end }}
	return spanner.InsertOrUpdate("{{ $table }}", {{ .Name }}Columns(), []interface{}{
		{{ fieldnames .Fields $short }},
	})
}

// UpdateColumns returns a Mutation to update specified columns of a row in a table.
func ({{ $short }} *{{ .Name }}) UpdateColumns(cols ...string) (*spanner.Mutation, error) {
	// add primary keys to columns to update by primary keys
	colsWithPKeys := append(cols, {{ .Name }}PrimaryKeys()...)
{{- if $hasUpdatedAt }}
	{{ $short }}.UpdatedAt = time.Now()
	colsWithPKeys = append(colsWithPKeys, "updated_at")
{{- end }}

	values, err := {{ $short }}.columnsToValues(colsWithPKeys)
	if err != nil {
		return nil, fmt.Errorf("invalid argument: {{ .Name }}.UpdateColumns {{ $table }}: %w", err)
	}

	return spanner.Update("{{ $table }}", colsWithPKeys, values), nil
}
{{- end }}

// Delete deletes the {{ .Name }} from the database.
func ({{ $short }} *{{ .Name }}) Delete() *spanner.Mutation {
	return spanner.Delete("{{ $table }}", spanner.Key{ {{- fieldnames .PrimaryKeyFields $short }}})
}
