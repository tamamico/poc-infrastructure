output "input-topic-men" {
  value = confluent_kafka_topic.input-men.topic_name
}

output "input-topic-mwoen" {
  value = confluent_kafka_topic.input-women.topic_name
}

output "output-topic" {
  value = confluent_kafka_topic.output.topic_name
}
