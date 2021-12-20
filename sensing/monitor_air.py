# This script is run on a raspberry pi zero hooked up to an
# Adafruit SCD-41 sensor (https://www.adafruit.com/product/5190)
# The pi is on the same local network so the air_quality.csv file
# is just pulled off via scp
import time
import board
import requests
import datetime


# ========================================================
# Tresholds for heat and ventilation
# ========================================================
CO2_HIGH = 1000
CO2_LOW = 600

TEMP_HIGH = 24 # degrees C aka 75f
TEMP_LOW = 16  # aka 60f


# ========================================================
# Setup drivers for CO2 sensor
# ========================================================
import adafruit_scd4x
i2c = board.I2C()
scd4x = adafruit_scd4x.SCD4X(i2c)
print("Starting up air-quality sensor...")

# ========================================================
# Setup E-Ink display
# ========================================================
import digitalio
import busio
from adafruit_epd.epd import Adafruit_EPD

spi = busio.SPI(board.SCK, MOSI=board.MOSI, MISO=board.MISO)
ecs = digitalio.DigitalInOut(board.CE0)
dc = digitalio.DigitalInOut(board.D22)
rst = digitalio.DigitalInOut(board.D27)
busy = digitalio.DigitalInOut(board.D17)
srcs = None

from adafruit_epd.ssd1680 import Adafruit_SSD1680
display = Adafruit_SSD1680(122, 250, spi, cs_pin=ecs, dc_pin=dc, sramcs_pin=srcs,
                          rst_pin=rst, busy_pin=busy)

display.rotation = 1

WHITE = Adafruit_EPD.WHITE
BLACK = Adafruit_EPD.BLACK
height = display.height
width = display.width

# Useful info for text rendering
CHAR_SIZE = 6 # Text are little 6x6 squares at size = 1
LINE_HEIGHT = 10
NUM_AXIS_LABEL_CHARS = 6

# Defines the box we are plotting inside of
PAD = 5 # Padding applied to all elements
AXIS_PAD = 2 # How far to separate the axis labels from box
plot_inset_top = 5 + PAD
plot_inset_bottom = 5 + PAD
plot_inset_left = NUM_AXIS_LABEL_CHARS*CHAR_SIZE + PAD + AXIS_PAD
plot_inset_right = round(width/3) + PAD
plot_width = width - plot_inset_left - plot_inset_right
plot_height = height - plot_inset_top - plot_inset_bottom


# Helper to right-align y-axis text
def makeAxisText(val):
  # Right align value in an 8 char window
  return "{0:>6}".format(val)

def display_co2_values(co2_values, co2_datetimes):
  min_co2 = min(co2_values)
  max_co2 = max(co2_values)
  range_co2 = max_co2 - min_co2

  co2_times = [time.mktime(dtime.timetuple()) for dtime in co2_datetimes]
  min_time = min(co2_times)
  range_time = max(co2_times) - min_time

  def place_co2(co2):
    # First make value relative (i.e. min=0, max=1)
    rel_co2 = (co2 - min_co2)/range_co2

    # Next calculate where that goes in our plot box
    return round(((1-rel_co2) * plot_height) + plot_inset_top)

  def place_time(time):
    rel_time = (time - min_time)/range_time
    return round((rel_time * plot_width) + plot_inset_left)

  # Clear out background
  display.fill(WHITE)

  # Draw rectangle over our plot area. Add back padding 
  display.rect(
    plot_inset_left - PAD, 
    plot_inset_top - PAD, 
    plot_width + 2*PAD, 
    plot_height + 2*PAD, 
    BLACK
  )

  # Draw line plot of observations
  for i in range(len(co2_values)-1):
    display.line(
      place_time(co2_times[i]), 
      place_co2(co2_values[i]), 
      place_time(co2_times[i + 1]), 
      place_co2(co2_values[i + 1]), 
      BLACK
    )

  # Draw each observation as a small dot to emphasize position
  DOT_SIZE = 4
  for i, co2 in enumerate(co2_values):
    display.fill_rect(
      round(place_time(co2_times[i]) - DOT_SIZE/2), 
      round(place_co2(co2) - DOT_SIZE/2), 
      DOT_SIZE, 
      DOT_SIZE, 
      BLACK
    )

  # Make a psuedo-legend by labeling the extremes
  display.text(makeAxisText(f"{max_co2}ppm"), 1, round(place_co2(max_co2) - CHAR_SIZE/2), BLACK)
  display.text(makeAxisText(f"{min_co2}ppm"), 1, round(place_co2(min_co2) - CHAR_SIZE/2), BLACK)

  # Write some text next to the rectangle
  text_start_y = round(height/2) - LINE_HEIGHT
  text_x = width - plot_inset_right + 2*PAD
  display.text(f"Last CO2 val:", text_x, text_start_y, BLACK)
  display.text(f"{co2_values[-1]}ppm", text_x, text_start_y + LINE_HEIGHT, BLACK)

  last_obs_time = co2_datetimes[-1] - datetime.timedelta(hours=5)
  display.text(
      f"@{last_obs_time.strftime('%I:%M')}", 
      text_x, 
      text_start_y + 2*LINE_HEIGHT, 
      BLACK
    )

  # Send to display
  display.display()


# ========================================================
# Setup smart plug controls
# ========================================================
import kasa
from kasa import Discover, SmartPlug
import asyncio

heater_plug_ip = "10.0.0.107"
fan_plug_ip= "10.0.0.135"

def turnPlugOn(plug):
    if (plug.is_off):
        asyncio.run(plug.turn_on())
        print("Plug turned on")
    else:
        print("Plug is already on")
    
def turnPlugOff(plug):
    if (plug.is_on):
        asyncio.run(plug.turn_off())
        print("Plug turned off")
    else:
        print("Plug is already off")
    
    
def setPlug(plug_ip, onOrOff):
    try:
      plug = SmartPlug(plug_ip)
      asyncio.run(plug.update())

      if onOrOff == "on":    
          turnPlugOn(plug)
      else:
          turnPlugOff(plug)
    except:
        print("Failed to connect to smart plug")

def setHeater(onOrOff):
    setPlug(heater_plug_ip, onOrOff)

def setFan(onOrOff):
    setPlug(fan_plug_ip, onOrOff)



# ========================================================
# Start main loop to gather data
# ========================================================

scd4x.start_periodic_measurement()
print("Waiting for first measurement...")

OBS_PER_AUTOMATION_CHECK = 10
automation_counter = 0

sample_counter = 0
SAMPLE_FREQ = 4 # How many obs to bin for timepoints
# Holds the running average of CO2 for the last sample window to reduce noise
latest_co2_avg = 0 


update_counter = 0
OBS_PER_DISPLAY_UPDATE = 15 # How many binned timepoints before updating display
DISPLAYED_OBS = 25 # How many observations are shown on the plot at each update
display_vals_co2 = [0 for _ in range(DISPLAYED_OBS)]
display_vals_time = [datetime.datetime.now() for i in range(DISPLAYED_OBS)]


while True:
    if scd4x.data_ready:
        curr_time = datetime.datetime.now()
        now = curr_time.strftime("%m/%d/%y %H:%M:%S")
        co2 = scd4x.CO2
        temp = round(scd4x.temperature, 3)
        humidity = round(scd4x.relative_humidity, 3)
        print(f"{now} - {co2}ppm  {round(temp,1)}*C  {round(humidity,1)}%")

        sample_counter = (sample_counter + 1) % SAMPLE_FREQ
        # Build up averaged co2 value
        latest_co2_avg += co2 / SAMPLE_FREQ

        if (sample_counter == 0):
            # Write this entry to display values
            
            # Remove oldest entry
            display_vals_co2.pop(0)
            display_vals_time.pop(0)
            
            # Add newest
            display_vals_time.append(curr_time)
            display_vals_co2.append(latest_co2_avg)
            latest_co2_avg = 0

            # Iterate update counter
            update_counter = (update_counter + 1) % OBS_PER_DISPLAY_UPDATE
            if (update_counter == 0):
                print("Sending latest values to display...")
                display_co2_values(display_vals_co2, display_vals_time)
                print("...done")
        
        with open("air_quality.csv", "a") as f:
            f.write(f"{now},{co2},{temp},{humidity}\n")
        try:
            r = requests.post('http://10.0.0.137:8000/record',
                              data={'time': now, 'co2': co2, 'temp': temp, 'humidity': humidity})
        except:
            print("Failed to send to database")

        # Control heat and airflow
        if (automation_counter == 0):
          print("  Checking heat and fan thresholds...")
          if temp > TEMP_HIGH:
            print("    Temp too high, turning off heater")
            setHeater("off")
          elif temp < TEMP_LOW:
            print("    Temp too low, turning on heater")
            setHeater("on")

          if co2 > CO2_HIGH:
            print("    CO2 too high, turning on fan")
            setFan("on")
          elif co2 < CO2_LOW:
            print("    CO2 below threshold, turning off fan")
            setFan("off")

        automation_counter = (automation_counter + 1) % OBS_PER_AUTOMATION_CHECK

    time.sleep(1)
