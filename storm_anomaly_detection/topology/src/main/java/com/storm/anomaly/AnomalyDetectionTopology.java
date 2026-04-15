package com.storm.anomaly;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.storm.Config;
import org.apache.storm.StormSubmitter;
import org.apache.storm.kafka.bolt.KafkaBolt;
import org.apache.storm.kafka.bolt.mapper.FieldNameBasedTupleToKafkaMapper;
import org.apache.storm.kafka.bolt.selector.DefaultTopicSelector;
import org.apache.storm.kafka.spout.KafkaSpout;
import org.apache.storm.kafka.spout.KafkaSpoutConfig;
import org.apache.storm.topology.TopologyBuilder;
import org.apache.storm.tuple.Fields;
import java.util.Properties;

public class AnomalyDetectionTopology {

    public static void main(String[] args) throws Exception {
        String bootstrapServers = "kafka:9092";
        String inputTopic = "sensor-data";
        String outputTopic = "anomaly-alerts";

        TopologyBuilder builder = new TopologyBuilder();

        // 1. Kafka Spout (Ingest Data)
        KafkaSpoutConfig<String, String> spoutConfig = KafkaSpoutConfig.builder(bootstrapServers, inputTopic)
                .setProp(ConsumerConfig.GROUP_ID_CONFIG, "storm-consumer-group")
                .setProp(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringDeserializer")
                .build();
        builder.setSpout("kafka-spout", new KafkaSpout<>(spoutConfig), 2);

        // 2. Parse Bolt (Parse JSON and emit individually)
        builder.setBolt("parse-bolt", new ParseBolt(), 4)
                .shuffleGrouping("kafka-spout");

        // 3. Anomaly Detection Bolt (Z-Score)
        builder.setBolt("anomaly-bolt", new AnomalyDetectionBolt(), 4)
                .fieldsGrouping("parse-bolt", new Fields("sensor_id", "metric_name"));

        // 4. Kafka Bolt (Publish Alerts)
        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");

        KafkaBolt<String, String> kafkaBolt = new KafkaBolt<String, String>()
                .withProducerProperties(props)
                .withTopicSelector(new DefaultTopicSelector(outputTopic))
                .withTupleToKafkaMapper(new FieldNameBasedTupleToKafkaMapper<>("key", "message"));

        builder.setBolt("kafka-bolt", kafkaBolt, 2)
                .shuffleGrouping("anomaly-bolt");

        // Configuration
        Config config = new Config();
        config.setNumWorkers(2); // Enable fault tolerance with 2 workers
        config.setMessageTimeoutSecs(30);
        
        // Use StormSubmitter for production cluster deployment
        StormSubmitter.submitTopology("anomaly-detection-topology", config, builder.createTopology());
    }
}
