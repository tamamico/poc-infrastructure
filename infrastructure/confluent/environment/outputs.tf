output "kafka-bootstrap-server" {
  value = confluent_kafka_cluster.basic.bootstrap_endpoint
}

output "poc-username" {
  value = confluent_api_key.cluster-poc-user.id
}

output "poc-password" {
  value     = confluent_api_key.cluster-poc-user.secret
  sensitive = true
}

output "test-username" {
  value = confluent_api_key.cluster-poc-test.id
}

output "test-password" {
  value     = confluent_api_key.cluster-poc-test.secret
  sensitive = true
}
