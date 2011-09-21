#include <SD.h>



/*
 Acceleration Sensor Test
 
 Reads an Analog Devices ADXL3xx accelerometer and a TMP36 analog temp sensor

 The circuit:
 analog 2: x-axis
 analog 3: y-axis
 analog 4: z-axis
 analog 5: temperature
 aref: connected to 3.3V
 
 Compatibility: Only tested on the Arduino Mega 2560.
                Your board may not have enough timers
                for all the pwm in the program  

*/



// these constants describe the pins. They won't change:
const int xpin = A2;                  // x-axis of the accelerometer
const int ypin = A3;                  // y-axis
const int zpin = A4;                  // z-axis (only on 3-axis models)
const int tpin = A5;
const int ledpin = 13;
const int vthreshold = 10;            // smallest sensor value before cutoff
const int sample_delay = 250;          // time to wait in ms between updates
const float aref_voltage = 3.3;
//a = 1024 units of analog range
//b = 6G's of sensor range
//c = 1G in analog units
//c = a / b
const float gravity = 102.4;               // the magnitude of gravity              
const int chipSelect = 4;


int minx = INT_MAX;
int maxx = 0;
int miny = INT_MAX;
int maxy = 0;
int minz = INT_MAX;
int maxz = 0;
 
int g0x = 0;
int g0y = 0;
int g0z = 0;
void setup()
{
  pinMode(53, OUTPUT);
  pinMode(ledpin, OUTPUT);

  if (!SD.begin(chipSelect))
  {
    blink_led(500);
    blink_led(500);
    return;
  }
  //set analog ref voltage to 3.3V
  //this will give us the full range on the sensor pins
  analogReference(EXTERNAL);  
}


void blink_led(int blink_delay)
{
  digitalWrite(ledpin,HIGH);
  delay(blink_delay);
  digitalWrite(ledpin,LOW);
  delay(blink_delay);
}
int adjustscale(int v)
{
  return getvthreshold(v - 512);
}

int getvthreshold(int v)
{
  return v < vthreshold && v > -vthreshold ? 0 : v;
}

int getx()
{
  //read the x axis from the sensor
  return adjustscale(analogRead(xpin));
}

int gety()
{
  //read the y axis from the sensor
  return adjustscale(analogRead(ypin));
}

int getz()
{
  //read the z axis from the sensor
  return adjustscale(analogRead(zpin));
}

int gett()
{
  return analogRead(tpin);  
}

//gets the magnitude of the 3d vector
//the formula is a^2 = x^2 + y^2 + z^2
long geta(long x, long y, long z)
{
  long x2 = x * x;
  long y2 = y * y;
  long z2 = z * z;
 
  //add the vectors together
  long a2 = x2 + y2 + z2;
  //square root the sum to get the 3d vector magnitude
  return sqrt(a2);
}

float getvoltage(int reading)
{
  float voltage = reading * aref_voltage;
  voltage /= 1024.0;
  
  return voltage;
}

float getformatted(int v)
{
  //ADXL sensor only reads +-3G's
  return (float)v / gravity;
}

//gets whether the device is in free fall
boolean getfreefall(int x, int y, int z)
{
  //if all three vectors read zero then return true, otherwise; false.
  return x == 0 && y == 0 && z == 0;
}

float fmap(float x, float in_min, float in_max, float out_min, float out_max)
{
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

void autoZeroCalibration(int pfx, int pfy, int pfz)
{
  if ((pfx < minx)||(pfy < miny)||(pfz < minz)||(pfx > maxx)||(pfy > maxy)||(pfz > maxz)) {
    // autozero calibration
    if (pfx < minx) minx = pfx;
    if (pfy < miny) miny = pfy;
    if (pfz < minz) minz = pfz;
     
    if (pfx > maxx) maxx = pfx;
    if (pfy > maxy) maxy = pfy;
    if (pfz > maxz) maxz = pfz;
     
    g0x = ((maxx - minx)/2)+minx;
    g0y = ((maxy - miny)/2)+miny;
    g0z = ((maxz - minz)/2)+minz;
  }
}

void loop()
{

  //get the sensor values
  int x = getx();
  int y = gety();
  int z = getz();

  //calculate the vector magnitude
  int a = geta(x,y,z);
  
  int t = gett();
  
  //converting from 10 mv per degree wit 500 mV offset
  //to degrees ((volatge - 500mV) times 100)
//  float temperatureC = (t - 0.5) * 100 ;  
//  // now convert to Fahrenheight
//  float temperatureF = (temperatureC * 9.0 / 5.0) + 32.0;
//  float accelX = getformatted(x);
//  float accelY = getformatted(y);
//  float accelZ = getformatted(z);
//  float accelA = getformatted(a);
  String dataString = "";

  dataString += String(t);
  dataString += ",";
  dataString += String(x);
  dataString += ",";
  dataString += String(y);
  dataString += ",";  
  dataString += String(z);
  dataString += ",";  
  dataString += String(a);

  File dataFile = SD.open("datalog.txt", FILE_WRITE);
  
  if (dataFile)
  {
    dataFile.println(dataString);
    dataFile.close();
  }

  //delay a little bit to let everything settle
  delay(sample_delay);
}
