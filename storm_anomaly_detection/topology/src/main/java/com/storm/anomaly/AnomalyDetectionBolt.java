package com.storm.anomaly;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.storm.topology.BasicOutputCollector;
import org.apache.storm.topology.OutputFieldsDeclarer;
import org.apache.storm.topology.base.BaseBasicBolt;
import org.apache.storm.tuple.Fields;
import org.apache.storm.tuple.Tuple;
import org.apache.storm.tuple.Values;

import java.util.HashMap;
import java.util.LinkedList;
import java.util.Map;

public class AnomalyDetectionBolt extends BaseBasicBolt {
    // sensor_id + "_" + metric_name -> last N values
    private Map<String, LinkedList<Double>> history = new HashMap<>();
    private static final int WINDOW_SIZE = 50;
    private static final double Z_SCORE_THRESHOLD = 3.0;
    private static final ObjectMapper mapper = new ObjectMapper();

    @Override
    public void execute(Tuple input, BasicOutputCollector collector) {
        String sensorId = input.getStringByField("sensor_id");
        String metricName = input.getStringByField("metric_name");
        double value = input.getDoubleByField("value");
        long timestamp = input.getLongByField("timestamp");

        String key = sensorId + "_" + metricName;
        LinkedList<Double> values = history.getOrDefault(key, new LinkedList<>());

        if (values.size() >= WINDOW_SIZE) {
            double mean = getMean(values);
            double stdDev = getStdDev(values, mean);

            if (stdDev > 0) {
                double zScore = Math.abs((value - mean) / stdDev);
                if (zScore > Z_SCORE_THRESHOLD) {
                    // It's an anomaly!
                    Map<String, Object> alert = new HashMap<>();
                    alert.put("sensor_id", sensorId);
                    alert.put("metric", metricName);
                    alert.put("value", value);
                    alert.put("z_score", zScore);
                    alert.put("timestamp", timestamp);

                    try {
                        String alertJson = mapper.writeValueAsString(alert);
                        // Emit to Kafka bolt
                        collector.emit(new Values(sensorId, alertJson));
                    } catch (JsonProcessingException e) {
                        e.printStackTrace();
                    }
                }
            }
            values.removeFirst();
        }
        
        values.addLast(value);
        history.put(key, values);
    }

    private double getMean(LinkedList<Double> list) {
        double sum = 0.0;
        for (Double v : list) sum += v;
        return sum / list.size();
    }

    private double getStdDev(LinkedList<Double> list, double mean) {
        double sumSq = 0.0;
        for (Double v : list) {
            sumSq += Math.pow(v - mean, 2);
        }
        return Math.sqrt(sumSq / list.size());
    }

    @Override
    public void declareOutputFields(OutputFieldsDeclarer declarer) {
        declarer.declare(new Fields("key", "message"));
    }
}
