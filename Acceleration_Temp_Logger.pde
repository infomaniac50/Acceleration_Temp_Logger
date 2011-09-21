/*
 Acceleration Sensor Test
 
 Reads an Analog Devices ADXL3xx accelerometer and a TMP36 analog temp sensor

 The circuit:
 analog 2: x-axis
 analog 3: y-axis
 analog 4: z-axis
 analog 5: temperature
 aref: connected to 3.3V
 
*/

//#define MINIMAL
//#define DEBUG

#ifndef DEBUG
#include <SD.h>
char filename[] = "LOGGER00.CSV";
#endif

#include <SampleDelay.h>

#ifndef MINIMAL
#include <ADXL335.h>
#include <TMP36.h>
#include <Format.h>
#endif


// these constants describe the pins. They won't change:
const int xpin = A2;
const int ypin = A3;
const int zpin = A4;
const int tpin = A5;
const int ledpin = 13;
const int chipSelect = 4;
const int sample_delay = 1000;          // time to wait in ms between updates
#ifndef MINIMAL
const float aref = 3.3;
const float accel_threshold = 0.02;         // smallest sensor value before cutoff
const int precision = 2;

ADXL335 accel(xpin, ypin, zpin, aref, true);
TMP36 temp(tpin,aref);
#endif

SampleDelay timer;
void setup()
{
  //set analog ref voltage to 3.3V
  //this will give us the full range on the sensor pins
  analogReference(EXTERNAL);  
  
  //deselect the W5100
  pinMode(10,OUTPUT);
  digitalWrite(10,HIGH);

#ifndef MINIMAL
  accel.setThreshold(accel_threshold);  
#endif

  pinMode(53, OUTPUT);
  pinMode(ledpin, OUTPUT);
#ifdef DEBUG
//  Serial.begin(57600);
  Serial.begin(9600);
#else
  if (!SD.begin(chipSelect))
  {
    blink_led(500);
    blink_led(500);
    return;
  }
  
  // create a new file  
  for (uint8_t i = 0; i < 100; i++) {
    filename[6] = i/10 + '0';
    filename[7] = i%10 + '0';
    if (!SD.exists(filename)) { 
      break;  // leave the loop!
    }
  }
#endif  
}

void blink_led(int blink_delay)
{
  digitalWrite(ledpin,HIGH);
  delay(blink_delay);
  digitalWrite(ledpin,LOW);
  delay(blink_delay);
}

void loop()
{
  timer.start_code_block();


  //get the sensor values
#ifndef MINIMAL  
  accel.update();
  temp.update();
  
  //calculate the polar coordinates
  String dataString = "";
  int string_width;
  
  //temperature precision is +-1 degree Celsius
  dataString += formatFloat(temp.getCelsius(), 0, &string_width);
  dataString += ",";
  dataString += formatFloat(temp.getFahrenheit(), 0, &string_width);
  dataString += ",";
  dataString += formatFloat(accel.getX(), precision, &string_width);
  dataString += ",";
  dataString += formatFloat(accel.getY(), precision, &string_width);
  dataString += ",";
  dataString += formatFloat(accel.getZ(), precision, &string_width);
  dataString += ",";
  dataString += formatFloat(accel.getRho(), precision, &string_width);
  dataString += ",";
  dataString += formatFloat(accel.getPhi(), precision, &string_width);
  dataString += ",";
  dataString += formatFloat(accel.getTheta(), precision, &string_width);
#else  
  String t;
  String x;
  String y;
  String z;
  
  t = String(analogRead(tpin));
  x = String(analogRead(xpin));
  y = String(analogRead(ypin));
  z = String(analogRead(zpin));  
  
  //calculate the polar coordinates
  String dataString = t + "," + x + "," + y + "," + z;
#endif

#ifdef DEBUG
  Serial.println(dataString);
#else
  File dataFile = SD.open(filename, FILE_WRITE);
  
  if (dataFile)
  {
    dataFile.println(dataString);
    dataFile.close();
  }
  else
  {
    blink_led(250);
  }
#endif

  int ms = timer.end_code_block(sample_delay);
  //delay a little bit to let everything settle
  if (ms == 0)
  {
    blink_led(25);
  }
  
  delay(ms);
}
