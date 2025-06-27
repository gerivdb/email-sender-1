// Minimal stub for qdrant package to allow compilation without the real dependency.
// Place this file in the same package as vector_registry.go and qdrant_manager.go.

package vector

import (
	"context"
)

type Client struct{}

type (
	PointsClient      struct{}
	CollectionsClient struct{}
)

type PointStruct struct {
	Id      *PointId
	Vectors *Vectors
	Payload map[string]*Value
}

type PointId struct {
	PointIdOptions interface{}
}

type Vectors struct {
	VectorsOptions interface{}
}

type Vector struct {
	Data []float32
}

type Value struct {
	Kind isValue_Kind
}

type isValue_Kind interface {
	isValue_Kind()
}

type Value_StringValue struct {
	StringValue string
}

func (*Value_StringValue) isValue_Kind() {}

type Value_IntegerValue struct {
	IntegerValue int64
}

func (*Value_IntegerValue) isValue_Kind() {}

type Value_DoubleValue struct {
	DoubleValue float64
}

func (*Value_DoubleValue) isValue_Kind() {}

func (v *Value) GetStringValue() string {
	if sv, ok := v.Kind.(*Value_StringValue); ok {
		return sv.StringValue
	}
	return ""
}

func (v *Value) GetIntegerValue() int64 {
	if iv, ok := v.Kind.(*Value_IntegerValue); ok {
		return iv.IntegerValue
	}
	return 0
}

func (v *Value) GetDoubleValue() float64 {
	if dv, ok := v.Kind.(*Value_DoubleValue); ok {
		return dv.DoubleValue
	}
	return 0
}

type UpsertPoints struct {
	CollectionName string
	Points         []*PointStruct
}

type SearchPoints struct {
	CollectionName string
	Vector         []float32
	Limit          uint64
	WithPayload    *WithPayloadSelector
	Filter         *Filter
}

type WithPayloadSelector struct {
	SelectorOptions interface{}
}
type WithPayloadSelector_Enable struct {
	Enable bool
}

type Filter struct {
	Must []*Condition
}
type Condition struct {
	ConditionOneOf interface{}
}
type Condition_Field struct {
	Field *FieldCondition
}
type FieldCondition struct {
	Key   string
	Match *Match
	Range *Range
}
type Match struct {
	MatchValue interface{}
}
type Match_Keywords struct {
	Keywords *RepeatedStrings
}
type RepeatedStrings struct {
	Strings []string
}
type Range struct {
	Gte *int64
	Lte *int64
}

type ScoredPoint struct {
	Id      *PointId
	Vectors *Vectors
	Payload map[string]*Value
	Score   float32
}

type RetrievedPoint struct {
	Id      *PointId
	Vectors *Vectors
	Payload map[string]*Value
}

type GetPoints struct {
	CollectionName string
	Ids            []*PointId
	WithPayload    *WithPayloadSelector
	WithVectors    *WithVectorsSelector
}
type WithVectorsSelector struct {
	SelectorOptions interface{}
}
type WithVectorsSelector_Enable struct {
	Enable bool
}

type DeletePoints struct {
	CollectionName string
	Points         *PointsSelector
}
type PointsSelector struct {
	PointsSelectorOneOf interface{}
}
type PointsSelector_Points struct {
	Points *PointsIdsList
}
type PointsIdsList struct {
	Ids []*PointId
}

type CreateCollection struct {
	CollectionName string
	VectorsConfig  *VectorsConfig
}
type VectorsConfig struct {
	Config *VectorsConfig_Params
	Params *VectorParams
}
type VectorsConfig_Params struct {
	Params *VectorParams
}
type VectorParams struct {
	Size     uint64
	Distance Distance
}
type Distance int32

const (
	Distance_Cosine Distance = 0
	Distance_Euclid Distance = 1
	Distance_Dot    Distance = 2
)

type GetCollectionInfoRequest struct {
	CollectionName string
}

type (
	CreateCollectionResponse  struct{}
	GetCollectionInfoResponse struct {
		Result *CollectionInfo
	}
)
type CollectionInfo struct {
	PointsCount         int64
	IndexedVectorsCount int64
	Status              *CollectionStatus
}
type CollectionStatus struct{}

func (cs *CollectionStatus) String() string { return "ok" }

func NewPointsClient(conn interface{}) *PointsClient           { return &PointsClient{} }
func NewCollectionsClient(conn interface{}) *CollectionsClient { return &CollectionsClient{} }

func (c *Client) ListCollections(ctx context.Context) (*ListCollectionsResponse, error) {
	return &ListCollectionsResponse{Collections: []*CollectionSummary{}}, nil
}

func (c *Client) CreateCollection(ctx context.Context, req *CreateCollection) (*CreateCollectionResponse, error) {
	return &CreateCollectionResponse{}, nil
}

func (c *Client) GetCollection(ctx context.Context, name string) (*CollectionInfo, error) {
	return &CollectionInfo{}, nil
}

func (c *Client) Upsert(ctx context.Context, req *UpsertPoints) (interface{}, error) {
	return nil, nil
}

func (c *Client) Search(ctx context.Context, req *SearchPoints) (*SearchPointsResponse, error) {
	return &SearchPointsResponse{Result: []*ScoredPoint{}}, nil
}

func (c *Client) Delete(ctx context.Context, req *DeletePoints) (interface{}, error) {
	return nil, nil
}
func (c *Client) Close() error { return nil }

// ---- ADDED STUBS FOR VECTOR_REGISTRY ----

func (c *CollectionsClient) Create(ctx context.Context, req *CreateCollection) (*CreateCollectionResponse, error) {
	return &CreateCollectionResponse{}, nil
}

func (c *PointsClient) Upsert(ctx context.Context, req *UpsertPoints) (interface{}, error) {
	return nil, nil
}

type ListCollectionsResponse struct {
	Collections []*CollectionSummary
}
type CollectionSummary struct {
	Name string
}
type SearchPointsResponse struct {
	Result []*ScoredPoint
}
