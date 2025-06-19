package tenant

import (
	"context"
	"errors"
)

// Role définit un rôle RBAC
type Role string

const (
	RoleAdmin    Role = "admin"
	RoleOperator Role = "operator"
	RoleUser     Role = "user"
)

// Permission définit une permission
type Permission string

const (
	PermRead   Permission = "read"
	PermWrite  Permission = "write"
	PermDelete Permission = "delete"
	PermAdmin  Permission = "admin"
)

// RBACPolicy mappe les rôles aux permissions
type RBACPolicy struct {
	RolePermissions map[Role][]Permission
}

// UserRBAC représente un utilisateur et ses rôles/permissions
type UserRBAC struct {
	UserID   string
	TenantID string
	Roles    []Role
}

// RBACManager gère les policies et vérifications
type RBACManager struct {
	policies map[string]*RBACPolicy // tenantID → policy
}

// NewRBACManager crée un gestionnaire RBAC
func NewRBACManager() *RBACManager {
	return &RBACManager{
		policies: make(map[string]*RBACPolicy),
	}
}

// SetPolicy définit la policy d’un tenant
func (rm *RBACManager) SetPolicy(tenantID string, policy *RBACPolicy) {
	rm.policies[tenantID] = policy
}

// CheckPermission vérifie si un user a la permission demandée
func (rm *RBACManager) CheckPermission(ctx context.Context, user *UserRBAC, perm Permission) error {
	policy, ok := rm.policies[user.TenantID]
	if !ok {
		return errors.New("no RBAC policy for tenant")
	}
	for _, role := range user.Roles {
		perms := policy.RolePermissions[role]
		for _, p := range perms {
			if p == perm || (perm == PermRead && p == PermAdmin) {
				return nil
			}
		}
	}
	return errors.New("permission denied")
}

// Example usage:
/*
func main() {
rbac := tenant.NewRBACManager()
rbac.SetPolicy("tenant1", &tenant.RBACPolicy{
RolePermissions: map[tenant.Role][]tenant.Permission{
tenant.RoleAdmin:    {tenant.PermAdmin, tenant.PermRead, tenant.PermWrite, tenant.PermDelete},
tenant.RoleOperator: {tenant.PermRead, tenant.PermWrite},
tenant.RoleUser:     {tenant.PermRead},
},
})
user := &tenant.UserRBAC{UserID: "u1", TenantID: "tenant1", Roles: []tenant.Role{tenant.RoleUser}}
err := rbac.CheckPermission(context.Background(), user, tenant.PermWrite)
if err != nil {
fmt.Println("Denied:", err)
}
}
*/
