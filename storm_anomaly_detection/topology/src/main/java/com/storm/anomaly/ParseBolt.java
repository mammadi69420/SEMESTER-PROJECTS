package com.storm.anomaly;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.storm.topology.BasicOutputCollector;
import org.apache.storm.topology.OutputFieldsDeclarer;
import org.apache.storm.topology.base.BaseBasicBolt;
import org.apache.storm.tuple.Fields;
import org.apache.storm.tuple.Tuple;
import org.apache.storm.tuple.Values;

public class ParseBolt extends BaseBasicBolt {
    private static final ObjectMapper mapper = new ObjectMapper();

    @Override
    public void execute(Tuple input, BasicOutputCollector collector) {
        String jsonString = input.getStringByField("value");
        try {
            JsonNode rootNode = mapper.readTree(jsonString);
            String sensorId = rootNode.get("sensor_id").asText();
            long timestamp = rootNode.get("timestamp").asLong();
            double temperature = rootNode.get("temperature").asDouble();
            double humidity = rootNode.get("humidity").asDouble();
            double pressure = rootNode.get("pressure").asDouble();

            collector.emit(new Values(sensorId, "temperature", temperature, timestamp));
            collector.emit(new Values(sensorId, "humidity", humidity, timestamp));
            collector.emit(new Values(sensorId, "pressure", pressure, timestamp));
        } catch (Exception e) {
            System.err.println("Failed to parse JSON: " + jsonString);
        }
    }

    @Override
    public void declareOutputFields(OutputFieldsDeclarer declarer) {
        declarer.declare(new Fields("sensor_id", "metric_name", "value", "timestamp"));
    }
}
