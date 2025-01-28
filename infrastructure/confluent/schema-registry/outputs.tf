output "schema-registry-url" {
  value = data.confluent_schema_registry_cluster.schema-registry.rest_endpoint
}

output "poc-username" {
  value = confluent_api_key.schema-registry-poc-user.id
}

output "poc-password" {
  value     = confluent_api_key.schema-registry-poc-user.secret
  sensitive = true
}

output "test-username" {
  value = confluent_api_key.schema-registry-poc-test.id
}

output "test-password" {
  value     = confluent_api_key.schema-registry-poc-test.secret
  sensitive = true
}
