/** 
 * OptoSensor Firmware V3.0.12
 *
 * Reads data from optosensor board and outputs to pc via USB TTL Serial
 * OptoSensor is based on the principal of  Discrete Distributed Sensor 
 * arrays. The project is a thin form-factor interactive surface technology
 * based on optical sensors to be embedded within regular an off the shelf 
 * liquid crystal display. This project aims to implement a new method of
 * adding multi-touch capabilities to existing LCD based technologies. 
 * For this project we implemented a combination existing sensing 
 * technologies to create sensor that is more robust than those available 
 * currently in the market. By using a large IR sensor array consisting of 
 * 128 sensors behind a traditional LCD panel and an IR light source in 
 * front of the panel, we are able to augment the display with the ability 
 * to sense a variety of objects near or on the surface; including finger 
 * tips and hands, and thus permitting us to enable multi-touch interaction. 
 * By creating a low cost high fidelity image sensor we are able to take 
 * advantage of optical sensing which also allows other physical items 
 * to be detected, and thus permitting interactions using various 
 * multi-modal interaction schemas.
 *
 * Nov 9th, 2009
 * By Taha Bintahir
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define SS 5 //Selection Pin 
#define DATA_OUT 6//MOSI 
#define SPI_CLOCK  7//Clock 

#define DATA_IN1  52 //22//MISO1
#define DATA_IN2  50 //24//MISO2
#define DATA_IN3  48 //26//MISO3
#define DATA_IN4  46 //28//MISO4
#define DATA_IN5  44 //30//MISO5
#define DATA_IN6  42 //32//MISO6
#define DATA_IN7  40 //34//MISO7
#define DATA_IN8  38 //36//MISO8
#define DATA_IN9  36 //38//MISO9
#define DATA_IN10  34 //40//MISO10
#define DATA_IN11  32 //42//MISO11
#define DATA_IN12  30 //44//MISO12
#define DATA_IN13  28 //46//MISO13
#define DATA_IN14  26 //48//MISO14
#define DATA_IN15  24 //50//MISO15
#define DATA_IN16  22 //52//MISO16

#define NUM_ADCS 16 // Total number of ADCs
#define NUM_CHNL 8 // Total Number of Channels per ACDC
#define NUM_SNRS 128 // Total number of Sensors
#define BAUDRATE 115200 // Baud Rate for communication

int adcvalue[NUM_ADCS]; // Array to hold channel values for all ADCs
int threshold; // Threshold variable; default set to zero
int sensor; // sensor variable used to calculate sensor location in test_sensor()

boolean configflag; // Config flag used in testing ftos()
boolean setthreshold; // Set threshold flag used to check if threshold has been set or not
boolean sensorflag; // Sensor flag used to check sensor number existance
boolean debugflag; // Debug flag used to toggle debug mode on/off

int frame[NUM_SNRS]; // Array to hold all sensor values in testing ftos()
int count;// counter used in ftos()


/**
 * setup() function sets up all project variables and
 * initialises both SPI communication interface and 
 * Serial communication channel.
 */
void setup()
{ 
  //set pin modes 
  pinMode(SS, OUTPUT); 
  pinMode(DATA_OUT, OUTPUT); 
  pinMode(DATA_IN1, INPUT); 
  pinMode(DATA_IN2, INPUT); 
  pinMode(DATA_IN3, INPUT); 
  pinMode(DATA_IN4, INPUT);
  pinMode(DATA_IN5, INPUT); 
  pinMode(DATA_IN6, INPUT); 
  pinMode(DATA_IN7, INPUT); 
  pinMode(DATA_IN8, INPUT);
  pinMode(DATA_IN9, INPUT); 
  pinMode(DATA_IN10, INPUT); 
  pinMode(DATA_IN11, INPUT); 
  pinMode(DATA_IN12, INPUT);
  pinMode(DATA_IN13, INPUT); 
  pinMode(DATA_IN14, INPUT); 
  pinMode(DATA_IN15, INPUT); 
  pinMode(DATA_IN16, INPUT);
  pinMode(SPI_CLOCK, OUTPUT);

  //disable device to start with 
  digitalWrite(SS,HIGH); 
  digitalWrite(DATA_OUT,LOW); 
  digitalWrite(SPI_CLOCK,LOW); 

  //Setup variables
  count = 0;
  threshold = 0;
  configflag = false;
  sensorflag = false;
  debugflag = false;

  //Setup Serial Communication 
  Serial.begin(BAUDRATE);

  //Initiate Menu
  Serial.println("       ");
  Serial.println("******************************************************************************");
  Serial.println("*                 OptoSensor Firmware ver3.0 - Help Menu                     *");
  Serial.println("*                             by Taha Bintahir                               *");
  Serial.println("* [1] Hit 1 to get raw sensor output                                         *");
  Serial.println("* [2] Hit 2 to get active sensor output ONLY, prefilter (x,y,value)          *");
  Serial.println("* [3] Hit 3 to set set point/threshold value MANUAL (Range 0 - 4095)         *");  
  Serial.println("* [4] Hit 4 to set active set point/threshold value (Avg Noise Substraction) *");
  Serial.println("* [5] Hit 5 to test individual sensor output                                 *");
  Serial.println("* [6] Hit 6 to print single frame out                                        *");
  Serial.println("* [7] Hit 7 toggle debug mode                                                *");
  Serial.println("* *** Hitting ctrl+z at anytime will toggle between output and the menu***   *");
  Serial.println("******************************************************************************");
} 

/**
 * read_adc() function polls the adcs for sensor values
 * the function recives an int channel variable where 
 * the value of channel is between 1 - 8. The SPI Bus
 * is configured in such a way that all adcs are 
 * triggered and channel 'x' is selected on all slaves
 * the corresponding sensor values are then retrived and 
 * placed within adcvalue[] array. i.e. if channel 1 is
 * selected all adcs then output channel 1 values in a 
 * single call to this function.
 */
int read_adc(int channel)
{
  // setup adc value place holders
  int adcvalue1 = 0;
  int adcvalue2 = 0;
  int adcvalue3 = 0;
  int adcvalue4 = 0;
  int adcvalue5 = 0;
  int adcvalue6 = 0;
  int adcvalue7 = 0;
  int adcvalue8 = 0;
  int adcvalue9 = 0;
  int adcvalue10 = 0;
  int adcvalue11 = 0;
  int adcvalue12 = 0;
  int adcvalue13 = 0;
  int adcvalue14 = 0;
  int adcvalue15 = 0;
  int adcvalue16 = 0;

  byte commandbits = B11000000; //command bits - start, mode, chn (3), dont care (3)


  commandbits|=((channel-1)<<3); //allow channel selection

  digitalWrite(SS,LOW); //Select adc

  // setup bits to be written
  for (int i=7; i>=3; i--)
  {
    digitalWrite(DATA_OUT,commandbits&1<<i);
    //cycle clock
    digitalWrite(SPI_CLOCK,HIGH);
    digitalWrite(SPI_CLOCK,LOW);    
  }

  //ADC ignores 2 null bits
  digitalWrite(SPI_CLOCK,HIGH);    
  digitalWrite(SPI_CLOCK,LOW);
  digitalWrite(SPI_CLOCK,HIGH);  
  digitalWrite(SPI_CLOCK,LOW);

  //read bits from adc
  for (int i=11; i>=0; i--)
  {
    adcvalue1+=digitalRead(DATA_IN1)<<i;
    adcvalue2+=digitalRead(DATA_IN2)<<i;
    adcvalue3+=digitalRead(DATA_IN3)<<i;
    adcvalue4+=digitalRead(DATA_IN4)<<i;
    adcvalue5+=digitalRead(DATA_IN5)<<i;
    adcvalue6+=digitalRead(DATA_IN6)<<i;
    adcvalue7+=digitalRead(DATA_IN7)<<i;
    adcvalue8+=digitalRead(DATA_IN8)<<i;
    adcvalue9+=digitalRead(DATA_IN9)<<i;
    adcvalue10+=digitalRead(DATA_IN10)<<i;
    adcvalue11+=digitalRead(DATA_IN11)<<i;
    adcvalue12+=digitalRead(DATA_IN12)<<i;
    adcvalue13+=digitalRead(DATA_IN13)<<i;
    adcvalue14+=digitalRead(DATA_IN14)<<i;
    adcvalue15+=digitalRead(DATA_IN15)<<i;
    adcvalue16+=digitalRead(DATA_IN16)<<i;

    //cycle clock
    digitalWrite(SPI_CLOCK,HIGH);
    digitalWrite(SPI_CLOCK,LOW);
  }
  digitalWrite(SS, HIGH); //turn off device

  //store channel values in an array
  adcvalue[0]=adcvalue1;
  adcvalue[1]=adcvalue2;
  adcvalue[2]=adcvalue3;
  adcvalue[3]=adcvalue4;
  adcvalue[4]=adcvalue5;
  adcvalue[5]=adcvalue6;
  adcvalue[6]=adcvalue7;
  adcvalue[7]=adcvalue8;
  adcvalue[8]=adcvalue9;
  adcvalue[9]=adcvalue10;
  adcvalue[10]=adcvalue11;
  adcvalue[11]=adcvalue12;
  adcvalue[12]=adcvalue13;
  adcvalue[13]=adcvalue14;
  adcvalue[14]=adcvalue15;
  adcvalue[15]=adcvalue16;
}

/**
 * loop() function loops through the menu cycle and 
 * remains on the menu item selected.
 */
void loop() 
{
  int inByte = 0;
  if (Serial.available() > 0) 
  {
    inByte = Serial.read();
    if (inByte != 0)
    {
      // Menu 1 raw output mode
      if (inByte == '1')
      {
        while(1)
        {
          raw();  
          inByte = Serial.read();
          if (inByte == 0x1A)
            break;
        }
      }
      // Menu 2 active sensors only output based on threshold level
      if (inByte == '2')
      {
        while(1)
        {
          active();
          inByte = Serial.read();
          if (inByte == 0x1A)
            break;
        }
      }
      // Menu 3 set threshold level
      if (inByte == '3')
      {
        Serial.println("Enter threshold value (0000 - 4095): ");
        while(1)
        {
          set_threshold();
          inByte = 0x1A;
          if (inByte == 0x1A)
            break;
        }
      }
      // Menu 4 set active threshold
      if (inByte == '4')
      {
        while(1)
        {
          set_athreshold();
          inByte = 0x1A;
          if (inByte == 0x1A)
            break;
        }
      }
      // Menu 5 test single sensor output
      if (inByte == '5')
      {
        Serial.println("Enter sensor No. (000 - 128): ");
        while(1)
        {
          test_sensor();
          inByte = 0x1A;
          if (inByte == 0x1A)
            break;
        }
      }
      // print single frame out
      if (inByte == '6')
      {
        while(1)
        {
          s_frame();
          inByte = 0x1A;
          if (inByte == 0x1A)
            break;
        }
      }
      // toggle debug mode on/off
      if (inByte == '7')
      {
        while(1)
        {
          debug();
          inByte = 0x1A;
          if (inByte == 0x1A)
            break;
        }
      }

      // Toggle Menu.
      if (inByte == 0x1A)
      {
        while(1)
        {
          Serial.println("       ");
          Serial.println("******************************************************************************");
          Serial.println("*                 OptoSensor Firmware ver3.0 - Help Menu                     *");
          Serial.println("*                             by Taha Bintahir                               *");
          Serial.println("* [1] Hit 1 to get raw sensor output                                         *");
          Serial.println("* [2] Hit 2 to get active sensor output ONLY, prefilter (x,y,value)          *");
          Serial.println("* [3] Hit 3 to set set point/threshold value MANUAL (Range 0 - 4095)         *");  
          Serial.println("* [4] Hit 4 to set active set point/threshold value (Avg Noise Substraction) *");
          Serial.println("* [5] Hit 5 to test individual sensor output                                 *");
          Serial.println("* [6] Hit 6 to print single frame out                                        *");
          Serial.println("* [7] Hit 7 toggle debug mode                                                *");
          Serial.println("* *** Hitting ctrl+z at anytime will toggle between output and the menu***   *");
          Serial.println("******************************************************************************");
          delay(20);
          break;
        }
      }
    }
  }
}

/**
 * raw() function polls the sensors and outputs raw 
 * data from sensors without active filtering.
 */
void raw()
{
  int channel;

  for (channel = 0; channel < NUM_CHNL; channel++)
  {
    read_adc(channel+1);
    for ( int i = 0; i < NUM_ADCS; i++)
    {
      Serial.print(adcvalue[i]);
      Serial.print(" ");
    }
  }
  Serial.println(" ");
  delay(20);
}

/**
 * active() function polls the sensors and outputs 
 * active sensor data from sensors by filtering out
 * sensor data below the threshold value. By default
 * the threshold value is set to zero. Threshold 
 * value can be changed by either manual input of 
 * threshold level or by doing active threshold 
 * calculations which use avg. bg substraction.
 */
void active()
{
  int val;
  int channel;
  int adc;  


  adc = 0;

  for (channel = 0; channel < NUM_CHNL; channel++)
  {
    val = read_adc(channel+1);  
    for (adc = 0; adc < NUM_ADCS; adc++)
    {
      Serial.println();
      if (adcvalue[adc] >= threshold) // internal threshold control
      {
        if(debugflag == true)
        {
          Serial.print("Adc: ");
          Serial.print(adc);
          Serial.print(",");
          Serial.print("Channel: ");
          Serial.print(channel);
          Serial.print(",");
          Serial.print("Value: ");
          Serial.println(adcvalue[adc]);
        }
        else
        {
          Serial.print(adc);
          Serial.print(",");
          Serial.print(channel);
          Serial.print(",");
          Serial.println(adcvalue[adc]);
        }
      }
    }
  }
  //signify end of frame
  Serial.println("****");
}

/**
 * set_athreshold() processes all sensors by doing a 
 * single pass through the sensors and then calculates
 * the average sensor noise level, which it then uses 
 * to set the active threshold value. 
 */
void set_athreshold()
{
  int channel;
  int adc;
  int val;
  int sum;

  sum = 0;

  for (channel = 0; channel < NUM_CHNL; channel++)
  {
    val = read_adc(channel+1);  
    for (adc = 0; adc < NUM_ADCS; adc++)
    {    
      sum = sum + adcvalue[adc];
    }
  }

  threshold = sum/(NUM_CHNL*NUM_ADCS);

  Serial.print ("Threshold Set @: ");
  Serial.println (threshold);
  //return threshold;
}

/**
 * set_threshold() function sets threshold variable to
 * what the user defines. Since the adc's output a 
 * 12bit value in for the sensors i.e. 0 - 4095, the 
 * user can set a threshold between 0 - 4095
 */
void set_threshold()
{
  char szInput [6];
  int index;
  int temp;

  while (Serial.available() <= 4)
  {
    if (Serial.available() >= 4) 
    {
      index =0;
      for (byte i=0; i<4; i++)
      {
        szInput[index] = Serial.read();
        index++;
      }
      temp = atoi(szInput);
      if (temp < 4096)
      {
        threshold = temp;
        setthreshold = true;
      }
      else 
      {
        Serial.print("Error: 0x");
        Serial.println(temp, HEX);
        break;
      }
    } 
    if (setthreshold ==true)
    {
      Serial.print("Threshold Set @ : ");
      Serial.println(threshold);
      setthreshold = false;
      break;
    }
  }
}

/**
 * test_sensor() function polls a single user specified
 * sensor and returns its value, used for debugging 
 * hardware
 */
void test_sensor()
{
  char szInput [4];
  int index;
  int temp;
  int channel;
  int adc;
  int res;
  int rem;

  while (Serial.available() <= 3)
  {
    if (Serial.available() >= 3) 
    {
      index =0;
      for (byte i=0; i<3; i++)
      {
        szInput[index] = Serial.read();
        index++;
      }
      temp = atoi(szInput);
      if (temp < 129)
      {
        sensor = temp;
        sensorflag = true;
      }
      else 
      {
        Serial.print("Error: 0x");
        Serial.println(temp, HEX);
        break;
      }
    } 
    if (sensorflag ==true)
    {
      Serial.print("Sensor No. : ");
      Serial.println(sensor);
      if (sensor <= 8)
      {
        adc = 1;
        channel = sensor;
      }
      else if (sensor > 8)
      {
        res = sensor/8;
        rem = sensor%8;
        if (rem > 0)
        {
          channel = rem;
          adc = res +1;          
        }
        else if (rem == 0)
        {
          channel = 8;
          adc = res;
        }
      }
      read_adc(channel); //channel (1 - 8)
      if (debugflag == true)
      {
        Serial.print("Sensor X: ");
        Serial.print(adc);
        Serial.print(", ");
        Serial.print("Sensor Y: ");
        Serial.print(channel);
        Serial.print(", ");
        Serial.print("Val: ");
        //Test individual Sensors 
        Serial.println(adcvalue[adc -1]); //adc (0 - 15)
      }
      else
      {
        Serial.print(adc);
        Serial.print(", ");
        Serial.print(channel);
        Serial.print(", ");
        //Test individual Sensors 
        Serial.println(adcvalue[adc -1]); //adc (0 - 15)
      }
      sensorflag = false;
      break;
    }
  }
}

/**
 * s_frame() function preforms single pass poll on all 
 * sensors, and prints data out via terminal.
 */
void s_frame()
{
  int val;
  int channel;
  int adc;  

  adc = 0;

  for (channel = 0; channel < NUM_CHNL; channel++)
  {
    val = read_adc(channel+1);  
    for (adc = 0; adc < NUM_ADCS; adc++)
    {
      Serial.println();
      if (adcvalue[adc] >= threshold) // internal threshold control
      {
        if(debugflag == true)
        {
          Serial.print("Adc: ");
          Serial.print(adc);
          Serial.print(",");
          Serial.print("Channel: ");
          Serial.print(channel);
          Serial.print(",");
          Serial.print("Value: ");
          Serial.println(adcvalue[adc]);
        }
        else
        {
          Serial.print(adc);
          Serial.print(",");
          Serial.print(channel);
          Serial.print(",");
          Serial.println(adcvalue[adc]);
        }
      }
    }
  }
  //signify end of frame
  Serial.println("****");
}

/**
 * debug() function toggles the debug flag which displays 
 * contexual infomation in regards to sensor, and channel.
 */
void debug()
{
  if (debugflag == false)
  {
    debugflag = true;
    Serial.println("Debug Mode On");
  }
  else if (debugflag = true)
  {
    debugflag = false;
    Serial.println("Debug Mode Off");
  }

}

/**
 * ftos() function buffers an entire frame and converts it to
 * string.
 */
//void ftos()
//{
//  int val;
//  int channel;
//  int adc;
//  char buff [1400];

//  if(configflag==true)
//  {
//    threshold = 0;
//  }

//  for (channel = 0; channel < NUM_CHNL; channel++)
//  {
//    if (count <= NUM_SNRS)
//    {
//      val = read_adc(channel+1);
//      
//      frame[count] = adcvalue[0];
//      count++;
//      frame[count] = adcvalue[1];
//      count++;
//      frame[count] = adcvalue[2];
//      count++;
//      frame[count] = adcvalue[3];
//      count++;
//      frame[count] = adcvalue[4];
//      count++;
//      frame[count] = adcvalue[5];
//      count++;
//      frame[count] = adcvalue[6];
//      count++;
//      frame[count] = adcvalue[7];
//      count++;
//      frame[count] = adcvalue[8];
//      count++;
//      frame[count] = adcvalue[9];
//      count++;
//      frame[count] = adcvalue[10];
//      count++;
//      frame[count] = adcvalue[11];
//      count++;
//      frame[count] = adcvalue[12];
//      count++;
//      frame[count] = adcvalue[13];
//      count++;
//      frame[count] = adcvalue[14];
//      count++;
//      frame[count] = adcvalue[15];
//      count++;
//    }
//    if(count == 128)
//    {
//      count = 0;
//      // convert frame[] into an string
//      for(int i = 0; i < NUM_SNRS; i++)
//      {
//        char temp[15];
//        //itoa(frame[i], temp, 10);
//        sprintf(temp, "%d", frame[i]);
//        strcat(buff, temp);
//        strcat(buff, ", ");
//      }
//      for(int i = 0; i < 128; i++)
//      {
//      Serial.print(frame[i]);
//      Serial.println("");
//      }
//      //Serial.print(frame);
//      Serial.println("");
//      //then send string over via serial
//    }
//  }
//}

