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
	"github.com/cespare/xxhash"
	"google.golang.org/api/iterator"

	"github.com/s-you/apierrors"
	"github.com/s-you/spannerbuilder"
	"github.com/s-you/yo-templates/internal/model"
	"github.com/s-you/yo-templates/internal/pkg/cache"
)

type Repository struct {
	client *spanner.Client
}

type (
	Params   = map[string]interface{}
	Key      = spanner.Key
	KeyRange = spanner.KeyRange
	Row      = *spanner.Row
)

type Decodable interface {
	ColumnsToPtrs([]string) ([]interface{}, error)
}

type queryCache struct {
	stmt     spanner.Statement
	duration time.Duration
	enabled  bool
}

var (
	ErrNotFound = errors.New("NotFound")
)

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
	elemType := elem.Type().Elem()
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
		} else {
			return fmt.Errorf("intosDecodable: not Decodable")
		}
	}
	value.Elem().Set(elem)

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
	elemType := elem.Type().Elem()

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
	}
	value.Elem().Set(elem)

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

// copyInto copy values into similar struct that implements Decodable, used where you cannot pass by pointer
func copyInto(cols []string, dst, src Decodable) error {
	dstPtrs, err := dst.ColumnsToPtrs(cols)
	if err != nil {
		return err
	}
	srcPtrs, err := src.ColumnsToPtrs(cols)
	if err != nil {
		return err
	}
	for i := range srcPtrs {
		dstPtrs[i] = srcPtrs[i]
	}

	return nil
}

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
{{- /* */ -}}
