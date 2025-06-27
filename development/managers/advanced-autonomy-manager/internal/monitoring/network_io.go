// Package monitoring implements the Real-Time Monitoring Dashboard component
package monitoring

// NetworkIO métriques de réseau
type NetworkIO struct {
	BytesReceived   float64
	BytesSent       float64
	PacketsReceived float64
	PacketsSent     float64
}

// ResourceUsage utilisation des ressources
type ResourceUsage struct {
	CPUPercent    float64
	MemoryPercent float64
	DiskPercent   float64
	NetworkIO     *NetworkIO
	ProcessCount  int
}
