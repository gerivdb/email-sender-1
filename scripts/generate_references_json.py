import json
import os

def parse_findstr_output(file_path):
    references = []
    if not os.path.exists(file_path):
        return references

    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            parts = line.strip().split(':', 2) # Split only twice to handle content with colons
            if len(parts) == 3:
                file_name = parts[0]
                line_number = int(parts[1])
                content = parts[2]
                references.append({
                    "file": file_name,
                    "line": line_number,
                    "content": content
                })
    return references

def main():
    all_references = []
    
    # Process mcp-gateway references
    mcp_gateway_file = "migration/gateway-manager-v77/references_mcp-gateway.txt"
    all_references.extend(parse_findstr_output(mcp_gateway_file))

    # Process projet/mcp/servers/gateway references
    projet_gateway_file = "migration/gateway-manager-v77/references_projet_mcp_servers_gateway.txt"
    all_references.extend(parse_findstr_output(projet_gateway_file))

    output_json_path = "migration/gateway-manager-v77/references.json"
    with open(output_json_path, 'w', encoding='utf-8') as f:
        json.dump(all_references, f, indent=2)

    print(f"Generated {output_json_path} with {len(all_references)} references.")

if __name__ == "__main__":
    main()
