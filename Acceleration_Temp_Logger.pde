

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
#define DEBUG

#ifndef DEBUG
#include <SD.h>
#endif

#include <Bounce.h>
#include <Format.h>

// these constants describe the pins. They won't change:
const int xpin = A2;                  // x-axis of the accelerometer
const int ypin = A3;                  // y-axis
const int zpin = A4;                  // z-axis (only on 3-axis models)
const int tpin = A5;
const int ledpin = 13;
const float vthreshold = 0.15;         // smallest sensor value before cutoff
const int sample_delay = 1000;          // time to wait in ms between updates
const float aref_voltage = 3.3;
//a = 1024 units of analog range
//b = 6G's of sensor range
//c = 1G in analog units
//c = a / b
float zerog = 1.5 * (3.3 / 3.0);
const int precision = 2;
const float gravity = 0.330;               // the magnitude of gravity              
const int chipSelect = 4;
float rad2deg = 180 / M_PI;

void setup()
{
  //set analog ref voltage to 3.3V
  //this will give us the full range on the sensor pins
  analogReference(EXTERNAL);  

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
#endif  
}

void blink_led(int blink_delay)
{
  digitalWrite(ledpin,HIGH);
  delay(blink_delay);
  digitalWrite(ledpin,LOW);
  delay(blink_delay);
}

float getx()
{
  //read the x axis from the sensor
  return getvoltage(analogRead(xpin));
}

float gety()
{
  //read the y axis from the sensor
  return getvoltage(analogRead(ypin));
}

float getz()
{
  //read the z axis from the sensor
  return getvoltage(analogRead(zpin));
}

float gett()
{
  return getvoltage(analogRead(tpin));  
}

float geta2d(float gx, float gy)
{
  float a;
  
  a = gx * gx;
  a += gy * gy;
  
  return sqrt(a);
}

//gets the magnitude of the 3d vector
//the formula is a^2 = x^2 + y^2 + z^2
float geta3d(float gx, float gy, float gz)
{
  float a;
  
  //use floating point multiply-add cpu func
  //sometimes we get better precision
  a = gx * gx;
  a = fma(gy,gy,a);
  a = fma(gz,gz,a);
  
  return sqrt(a);
}

float getrho(float ax, float ay, float az)
{
  return atan2(ax, geta2d(ay, az)) * rad2deg;  
}

float getphi(float ax, float ay, float az)
{
  return atan2(ay, geta2d(ax, az)) * rad2deg;  
}

float gettheta(float ax, float ay, float az)
{
  return atan2(geta2d(ay, ax), az) * rad2deg;
}

float getvoltage(int reading)
{
  float voltage = reading * aref_voltage;
  voltage /= 1024.0;
  
  return voltage;
}

float getgravity(float voltage)
{  
  //minus the zero g bias 
  //then divide by mv/g
  //which when Vs = 3.3V, V/g = 0.330
  float gv = (voltage - zerog) / gravity;
  
  //minus the null zone
  getthreshold(&gv);
  
  return gv;
}

void gettemperature(float voltage,float* tempc,float* tempf)
{
  //converting from 10 mv per degree with 500 mV offset
  //to degrees ((volatge - 500mV) times 100)
  *tempc = (voltage - 0.5) * 100 ;  
  // now convert to Fahrenheight
  *tempf = (*tempc * 9.0 / 5.0) + 32.0;  
}

//gets whether the device is in free fall
//boolean getfreefall(float gx, float gy, float gz)
//{
//  //if all three vectors read zero then return true, otherwise; false.
//  return gx == 0.0 && gy == 0.0 && gz == 0.0;
//}
//
//float fmap(float x, float in_min, float in_max, float out_min, float out_max)
//{
//  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
//}

void getthreshold(float* gv)
{
  if (*gv < vthreshold && *gv > -vthreshold)
  {
    *gv = 0.0;
  }
}



unsigned long start_time;
unsigned long end_time;

void start_calc_delay()
{
  start_time = millis();
}

int end_calc_delay(int sample_delay)
{
  end_time = millis();
  int calc_delay = sample_delay -  (int)(end_time - start_time);
    
  return calc_delay > 0 ? calc_delay : 0;
}



void loop()
{
  start_calc_delay();
  //get the sensor values
  float vx = getx();
  float vy = gety();
  float vz = getz();
  float vt = gett();  
  
  
  float tempc;
  float tempf;  
  float gx;
  float gy;
  float gz;
  float ga;
  float rho;
  float phi;
  float theta;
  
  gettemperature(vt, &tempc, &tempf);
  gx = getgravity(vx);
  gy = getgravity(vy);
  gz = getgravity(vz);
  
  //calculate the polar coordinates
  ga =    geta3d(gx,gy,gz);
  rho =   getrho(gx,gy,gz);
  phi =   getphi(gx,gy,gz);
  theta = gettheta(gx,gy,gz);
  String dataString = "";
  int string_width;
  
  //temperature precision is +-1 degree Celsius
  dataString += formatFloat(tempc, 0, &string_width);
  dataString += ",";
  dataString += formatFloat(tempf, 0, &string_width);
  dataString += ",";
  dataString += formatFloat(gx, precision, &string_width);
  dataString += ",";
  dataString += formatFloat(gy, precision, &string_width);
  dataString += ",";
  dataString += formatFloat(gz, precision, &string_width);
  dataString += ",";
  dataString += formatFloat(ga, precision, &string_width);
  dataString += ",";
  dataString += formatFloat(rho, precision, &string_width);
  dataString += ",";
  dataString += formatFloat(phi, precision, &string_width);
  dataString += ",";
  dataString += formatFloat(theta, precision, &string_width);

#ifdef DEBUG
  Serial.println(dataString);
#else
  File dataFile = SD.open("datalog.txt", FILE_WRITE);
  
  if (dataFile)
  {
    dataFile.println(dataString);
    dataFile.close();
  }
#endif

  int ms = end_calc_delay(sample_delay);
  //delay a little bit to let everything settle
  if (ms == 0)
  {
    blink_led(25);
  }
  
  delay(ms);
}
