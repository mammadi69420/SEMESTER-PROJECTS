import json
import time
import random
import uuid
from kafka import KafkaProducer

KAFKA_BROKER = 'localhost:29092'
TOPIC_NAME = 'sensor-data'

def get_producer():
    try:
        producer = KafkaProducer(
            bootstrap_servers=[KAFKA_BROKER],
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
        return producer
    except Exception as e: # Kafka might not be up immediately
        print(f"Error connecting to Kafka: {e}")
        return None

def generate_sensor_data(anomaly_probability=0.05):
    """Generates synthetic sensor data and occasionally injects anomalies."""
    base_temp = 25.0
    base_humidity = 50.0
    base_pressure = 1013.0
    
    is_anomaly = random.random() < anomaly_probability
    
    if is_anomaly:
        temp = base_temp + random.uniform(10.0, 30.0) * random.choice([-1, 1])
        humidity = base_humidity + random.uniform(20.0, 40.0) * random.choice([-1, 1])
        pressure = base_pressure + random.uniform(30.0, 50.0) * random.choice([-1, 1])
        print(">>> INJECTED ANOMALY <<<")
    else:
        temp = base_temp + random.gauss(0, 1.0)
        humidity = base_humidity + random.gauss(0, 2.0)
        pressure = base_pressure + random.gauss(0, 1.5)
        
    return {
        "sensor_id": f"sensor_{random.randint(1, 5)}",
        "timestamp": int(time.time() * 1000),
        "temperature": round(temp, 2),
        "humidity": round(humidity, 2),
        "pressure": round(pressure, 2),
        "is_true_anomaly": is_anomaly
    }

def main():
    print("Waiting for Kafka to be ready...")
    producer = None
    while producer is None:
        producer = get_producer()
        if producer is None:
            time.sleep(2)
            
    print(f"Connected to Kafka at {KAFKA_BROKER}. Starting data generation...")
    
    try:
        events_sent = 0
        while True:
            data = generate_sensor_data()
            producer.send(TOPIC_NAME, value=data)
            events_sent += 1
            if events_sent % 100 == 0:
                print(f"Sent {events_sent} records...")
            # Limit rate to ~100 events per second for normal load
            time.sleep(0.01)
    except KeyboardInterrupt:
        print("Data generation stopped.")
    finally:
        producer.close()

if __name__ == "__main__":
    main()
