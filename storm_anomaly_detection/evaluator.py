import json
import time
from kafka import KafkaConsumer

KAFKA_BROKER = 'localhost:29092'
ALERT_TOPIC = 'anomaly-alerts'

def main():
    print("Waiting for Kafka to be ready...")
    consumer = None
    while consumer is None:
        try:
            consumer = KafkaConsumer(
                ALERT_TOPIC,
                bootstrap_servers=[KAFKA_BROKER],
                auto_offset_reset='latest',
                enable_auto_commit=True,
                value_deserializer=lambda x: json.loads(x.decode('utf-8'))
            )
        except Exception as e:
            print(f"Error connecting to Kafka: {e}")
            time.sleep(2)

    print(f"Connected to Kafka at {KAFKA_BROKER}. Listening to {ALERT_TOPIC}...")
    
    anomalies_detected = 0
    start_time = time.time()
    latencies = []
    
    try:
        for message in consumer:
            alert = message.value
            current_time = int(time.time() * 1000)
            latency = current_time - alert.get("timestamp", current_time)
            if latency >= 0:
                latencies.append(latency)
            
            anomalies_detected += 1
            avg_latency = sum(latencies) / len(latencies) if latencies else 0
            
            # Simple P95 calculation
            p95_latency = sorted(latencies)[int(len(latencies) * 0.95)] if len(latencies) > 20 else avg_latency

            total_elapsed = time.time() - start_time
            throughput = anomalies_detected / total_elapsed if total_elapsed > 0 else 0

            print(f"Alert Received! Sensor: {alert.get('sensor_id')}, "
                  f"Metric: {alert.get('metric')}, Value: {alert.get('value')}")
            print(f"[Stats] Detected: {anomalies_detected} | "
                  f"Avg Latency: {avg_latency:.2f}ms | P95 Latency: {p95_latency:.2f}ms")
            
    except KeyboardInterrupt:
        print("Evaluation stopped.")
    finally:
        consumer.close()

if __name__ == "__main__":
    main()
