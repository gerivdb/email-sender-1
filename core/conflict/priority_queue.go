package conflict

// PriorityQueue implements a priority queue for conflicts.
type PriorityQueue []*ConflictWithScore

type ConflictWithScore struct {
	Conflict Conflict
	Score    float64
}

func (pq PriorityQueue) Len() int           { return len(pq) }
func (pq PriorityQueue) Less(i, j int) bool { return pq[i].Score > pq[j].Score }
func (pq PriorityQueue) Swap(i, j int)      { pq[i], pq[j] = pq[j], pq[i] }

func (pq *PriorityQueue) Push(x interface{}) {
	*pq = append(*pq, x.(*ConflictWithScore))
}

func (pq *PriorityQueue) Pop() interface{} {
	old := *pq
	n := len(old)
	item := old[n-1]
	*pq = old[0 : n-1]
	return item
}

func (pq *PriorityQueue) Peek() *ConflictWithScore {
	if pq.Len() == 0 {
		return nil
	}
	return (*pq)[0]
}
