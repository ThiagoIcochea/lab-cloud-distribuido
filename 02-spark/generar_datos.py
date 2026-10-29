"""Genera lecturas simuladas de sensores IoT (CSV) en varias regiones."""
import csv, random, sys, datetime
n = int(sys.argv[1]) if len(sys.argv) > 1 else 200000
out = sys.argv[2] if len(sys.argv) > 2 else "lecturas.csv"
regiones = ["lima", "arequipa", "trujillo", "cusco", "piura"]
inicio = datetime.datetime(2026, 10, 1)
random.seed(45104)
with open(out, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["sensor_id", "region", "timestamp", "temperatura", "humedad", "vibracion"])
    for i in range(n):
        r = random.choice(regiones)
        t = inicio + datetime.timedelta(seconds=random.randint(0, 30 * 86400))
        temp = random.gauss(24, 4) + (8 if random.random() < 0.01 else 0)  # 1 % de anomalías
        w.writerow([f"{r[:3]}-{random.randint(1, 400):04d}", r, t.isoformat(), round(temp, 2),
                    round(random.uniform(30, 90), 1), round(abs(random.gauss(0.5, 0.2)), 3)])
print(f"{n} lecturas en {out}")
