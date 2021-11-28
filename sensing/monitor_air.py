# This script is run on a raspberry pi zero hooked up to an
# Adafruit SCD-41 sensor (https://www.adafruit.com/product/5190)
# The pi is on the same local network so the air_quality.csv file
# is just pulled off via scp
import time
import board
import adafruit_scd4x
import requests
from datetime import datetime

i2c = board.I2C()
scd4x = adafruit_scd4x.SCD4X(i2c)
print("Serial number:", [hex(i) for i in scd4x.serial_number])

scd4x.start_periodic_measurement()
print("Waiting for first measurement....")

while True:
    if scd4x.data_ready:
        now = datetime.now().strftime("%m/%d/%y %H:%M:%S")
        co2 = scd4x.CO2
        temp = round(scd4x.temperature, 3)
        humidity = round(scd4x.relative_humidity, 3)
        with open("air_quality.csv", "a") as f:
            f.write(f"{now},{co2},{temp},{humidity}\n")
        try:
            r = requests.post('http://10.0.0.137:8000/record',
                              data={'time': now, 'co2': co2, 'temp': temp, 'humidity': humidity})
        except:
            print("Failed to send to database")
        print(now)
        print("CO2: %d ppm" % scd4x.CO2)
        print("Temperature: %0.1f *C" % scd4x.temperature)
        print("Humidity: %0.1f %%" % scd4x.relative_humidity)
        print()
    time.sleep(1)
