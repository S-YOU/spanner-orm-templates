// Code generated by yo. DO NOT EDIT.
package {{ .Package }}

import (
	"bytes"
	"context"
	"encoding/binary"
	"encoding/gob"
	"errors"
	"fmt"
	"reflect"
	"time"

	"cloud.google.com/go/spanner"
	"google.golang.org/api/iterator"

	"github.com/cespare/xxhash"
	"github.com/s-you/apierrors"
	"github.com/s-you/spannerbuilder"
	"github.com/s-you/yo-templates/internal/middleware"
	"github.com/s-you/yo-templates/internal/model"
)

type Repository struct {
	client *spanner.Client
}

type Params = map[string]interface{}

type Decodable interface {
	ColumnsToPtrs([]string) ([]interface{}, error)
}

var (
	ErrNotFound = errors.New("NotFound")
)

func getCacheKey(stmt spanner.Statement) (string, error) {
	sum64 := xxhash.Sum64String(stmt.SQL)
	buf := new(bytes.Buffer)
	cacheKey := make([]byte, 8)
	binary.LittleEndian.PutUint64(cacheKey, sum64)
	buf.Write(cacheKey)
	e := gob.NewEncoder(buf)
	err := e.Encode(stmt.Params)
	if err != nil {
		return "", err
	}
	return buf.String(), nil
}

func intoDecodable(iter *spanner.RowIterator, cols []string, into Decodable) error {
	defer iter.Stop()

	row, err := iter.Next()
	if err != nil {
		if err == iterator.Done {
			return ErrNotFound
		}
		return fmt.Errorf("intoDecodable.iter: %w", err)
	}

	if err := DecodeInto(cols, row, into); err != nil {
		return fmt.Errorf("intoDecodable.DecodeInto: %w", err)
	}

	return nil
}

func intosDecodable(iter *spanner.RowIterator, cols []string, intos interface{}) error {
	defer iter.Stop()

	if reflect.TypeOf(intos).Kind() != reflect.Ptr {
		return fmt.Errorf("intosDecodable: argument is not pointer")
	}
	value := reflect.ValueOf(intos)
	elem := value.Elem()
	elemType := reflect.MakeSlice(elem.Type(), 1, 1).Index(0).Type()
	isPtr := false
	if elemType.Kind() == reflect.Ptr {
		elemType = elemType.Elem()
		isPtr = true
	}

	for {
		row, err := iter.Next()
		if err != nil {
			if err == iterator.Done {
				break
			}
			return fmt.Errorf("intosDecodable.iter: %w", err)
		}

		g := reflect.New(elemType)
		if into, ok := g.Interface().(Decodable); ok {
			err = DecodeInto(cols, row, into)
			if err != nil {
				return fmt.Errorf("intosDecodable.DecodeInto: %w", err)
			}

			if isPtr {
				elem = reflect.Append(elem, g)
			} else {
				elem = reflect.Append(elem, g.Elem())
			}
			value.Elem().Set(elem)
		} else {
			return fmt.Errorf("intosDecodable: not Decodable")
		}
	}

	return nil
}

func intoAny(iter *spanner.RowIterator, cols []string, into interface{}) error {
	defer iter.Stop()
	if reflect.TypeOf(into).Kind() != reflect.Ptr {
		return fmt.Errorf("intoAny: argument is not pointer")
	}
	if len(cols) != 1 {
		return fmt.Errorf("intoAny: multiple column not supported, use .Into instead")
	}
	value := reflect.ValueOf(into)

	row, err := iter.Next()
	if err != nil {
		if err == iterator.Done {
			return ErrNotFound
		}
		return fmt.Errorf("intoAny.iter: %w", err)
	}

	g := reflect.New(value.Elem().Type())
	err = row.Column(0, g.Interface())
	if err != nil {
		return fmt.Errorf("intoAny.Column: %w", err)
	}
	value.Elem().Set(g.Elem())

	return nil
}

func intosAnySlice(iter *spanner.RowIterator, cols []string, into interface{}) error {
	defer iter.Stop()
	if reflect.TypeOf(into).Kind() != reflect.Ptr {
		return fmt.Errorf("intosAnySlice: argument is not pointer")
	}
	if len(cols) != 1 {
		return fmt.Errorf("intosAnySlice: multiple column not supported, use .Intos instead")
	}
	value := reflect.ValueOf(into)
	elem := value.Elem()
	elemType := reflect.MakeSlice(elem.Type(), 1, 1).Index(0).Type()

	for {
		row, err := iter.Next()
		if err != nil {
			if err == iterator.Done {
				break
			}
			return fmt.Errorf("intosAnySlice.iter: %w", err)
		}

		g := reflect.New(elemType)
		err = row.Column(0, g.Interface())
		if err != nil {
			return fmt.Errorf("intosAnySlice.Column: %w", err)
		}

		elem = reflect.Append(elem, g.Elem())
		value.Elem().Set(elem)
	}

	return nil
}

// DecodeInto decodes row into Decodable
// The decoder is not goroutine-safe. Don't use it concurrently.
func DecodeInto(cols []string, row *spanner.Row, into Decodable) error {
	ptrs, err := into.ColumnsToPtrs(cols)
	if err != nil {
		return err
	}

	if err := row.Columns(ptrs...); err != nil {
		return err
	}

	return nil
}
{{- /* */ -}}
