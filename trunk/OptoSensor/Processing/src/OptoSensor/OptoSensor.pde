/** 
 * OptoSensor Tracker 0.2
 *
 * Reads data from optosensor board and outputs 12 bit greayscale
 * visual rendering of sensor data. The resultant image is then processed 
 * using OpenCV and inputs are then tracked using the blobDetection 
 * library for processing.
 *
 * Nov 9th, 2009
 * By Taha Bintahir
 */
 
//Imports
import processing.serial.*;
import processing.video.*;
import blobDetection.*;
import fullscreen.*;

//Initialise Variables

/*Setup serial*/
Serial dataPort; //create object from serial class

/*Setup Java fullscreen*/
FullScreen fs; // Initialise FullScreen

/*2D Array of objects*/
Cell[][] grid; //create object from cell class 

/*Number of columns and rows in the grid*/
int cols = 16; // number of columns 
int rows = 8; // number of rows

/*Parssed data array*/
int [][] parssedData = new int [rows][cols];
// Parssed Data test array
//int[][] parssedData = {  {255, 189, 189,   0, 236, 189, 189,   0, 236, 189, 189,   0, 236, 189, 189,   0},
//                         {236,  80, 189, 189, 236,  80, 189, 189, 236,  80, 189, 189, 236,  80, 189, 189},
//                         {236,   0, 189,  80, 236,   0, 189,  80, 236,   0, 189,  80, 236,   0, 189,  80},
//                         {236, 189, 189,  80, 236, 189, 189,  80, 236, 189, 189,  80, 236, 189, 189,  80},
//                         {236, 189, 189,   0, 236, 189, 189,   0, 236, 189, 189,   0, 236, 189, 189,   0},
//                         {236,  80, 189, 189, 236,  80, 189, 189, 236,  80, 189, 189, 236,  80, 189, 189},
//                         {236,   0, 189,  80, 236,   0, 189,  80, 236,   0, 189,  80, 236,   0, 189,  80},
//                         {236, 189, 189,  80, 236, 189, 189,  80, 236, 189, 189,  80, 236, 189, 189,  80}  };


int lF = 10; // Linefeed in ASCII
String Buff = null; // Data in Buffer
int[][] values = new int[8][16]; // Values array to sensor data

int numberOfSensors = 128; // Total number of sensors
int threshold = 20; // Threshold Level
int numPixels; // Total number of pixels on screen
int[] bgPixels; // Array to hold toatal pixels 

int oldX = 0;
int oldY = 0;
int avg = 0;

boolean flag;
boolean bgsub;

BlobDetection theBlobDetection;

void setup() 
{
  //Setup application
  size(723,423, P2D);
  //size(1675,928); // initialise stage size
  frameRate (200); // set application framerate 
  dataPort = new Serial (this, Serial.list()[1],115200); // Open and initialise serial port
  println(Serial.list()); // print out serial list
  dataPort.write('1'); // select raw out put from sensor menu
  grid = new Cell[cols][rows]; // initialise raw feed grid
  
  fs = new FullScreen(this); // initialise fullscreen
  fs.setResolution(screen.width, screen.height); // get fs res and set applicaion res to fs res
  fs.setShortcutsEnabled(true); // enable fs entry shortcut ctrl+f
  
  
  numPixels = width*height;  // calculate total pixles on screen 
  bgPixels = new int [numPixels]; //
  
  loadPixels();
  
  //Ininitialise OpenCV and Blob Detection
  theBlobDetection = new BlobDetection(width, height);
  theBlobDetection.setPosDiscrimination(true);
  theBlobDetection.setThreshold(0.10);
    
  noStroke();
  smooth();
   
  flag = false;
}

void draw() 
{
  background(0);
  
  parssedData = getData();
  
 
  for (int i = 0; i < cols; i ++ ) {
    for (int j = 0; j < rows; j ++ ) {
      // Initialize each object
      grid[i][j] = new Cell(i*45,j*52.5,45,53,parssedData[j][i]);
    }
  }
  
  
  for (int i = 0; i < cols; i ++ ) {     
    for (int j = 0; j < rows; j ++ ) {
      // Display each object
      grid[i][j].display();
    }
  }
  
  flag = true;
  bgSubstraction();
  bgsub = false;
  
  if(flag == true && bgsub == false)
  {
  blobTracking(false,true);
  //updatePixels();  
  flag = false;
  }
  smooth();
}

int[][] getData()
{
    byteAvailable(); // hold if nothing is in the buffer
    
    while (dataPort.available() > 0) // hold until there is data in the buffer double check
    {
      Buff = dataPort.readStringUntil(lF); // buffer data untill Line Feed is detected
      if ( Buff != null)
      {
        Buff = Buff.trim(); // trim buffered data to remove white space characters from the begining and end of the string
        int [] nums = int(split(Buff, ' ')); // split buffer string at white space and convert to int
        // Print 1D Data Array - nums
//        println(nums.length);
//        for(int i =0; i < nums.length;i++)
//        {
//          print(nums[i] + " ");  
//        }
//        println();
//        println();
       
        // convert 1D array to 2D array 
        int counter = 0;
        for(int q=0; q < 8;q++)
        {
          for(int w=0; w < 16; w++)
          { 
//            println(counter + " ");            
            values[q][w] = nums[counter];  
            counter++;
//            println(counter + " ");         
          }
        }

        // print 2D array - values
//        for(int i =0; i < 8;i++)
//        {
//          for(int j=0; j < 16; j++)
//          {
//            print(values[i][j] + " ");    
//          }
//          println(); 
//        }
//        println(); 
//        println(); 
      }
    }
return values; // return 2d array values to the variable calling the function
   
}

//Get Background

void bgSubstraction()
{
   bgsub = true;
   loadPixels();
   
   int presenceSum = 0;
   
   for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
      // Fetch the current color in that location, and also the color
      // of the background in that spot
      color currColor = pixels[i];
      color bkgdColor = bgPixels[i];
      // Extract the red, green, and blue components of the current pixel’s color
      int currR = (currColor >> 16) & 0xFF;
      int currG = (currColor >> 8) & 0xFF;
      int currB = currColor & 0xFF;
      // Extract the red, green, and blue components of the background pixel’s color
      int bkgdR = (bkgdColor >> 16) & 0xFF;
      int bkgdG = (bkgdColor >> 8) & 0xFF;
      int bkgdB = bkgdColor & 0xFF;
      // Compute the difference of the red, green, and blue values
      int diffR = abs(currR - bkgdR);
      int diffG = abs(currG - bkgdG);
      int diffB = abs(currB - bkgdB);
      // Add these differences to the running tally
      presenceSum += diffR + diffG + diffB;
      // Render the difference image to the screen
      //pixels[i] = color(diffR, diffG, diffB);
      // The following line does the same thing much faster, but is more technical
      pixels[i] = 0xFF000000 | (diffR << 16) | (diffG << 8) | diffB;
    }
    updatePixels();
    //loadPixels();
    theBlobDetection.computeBlobs(pixels);
    bgsub = false;
}

void keyPressed()
{
  bgsub = true;
  loadPixels();
  arraycopy(pixels, bgPixels);
  bgsub = false;
}



void byteAvailable()
{
  while (dataPort.available() < 1); //do nothing untill buffer has atleast one byte
}


////Single Input Blob Tracking based on vector analysis
//void blobTracking()
//{
//  while (flag == true)
//  {
//  int brightestX = 0;
//  int brightestY = 0;
//  float brightestValue = 0;
//  float pixelBrightness = 0;
//  int [] blobs = new int [2];
//  
//  loadPixels();
//  
//  int index = 0;
//  for (int y = 0; y < height; y++) 
//  {
//      for (int x = 0; x < width; x++) 
//      {
//        // Get the color stored in the pixel
//        int pixelValue = pixels[index];
//        // Determine the brightness of the pixel
//        pixelBrightness = brightness(pixelValue);
//        // If that value is brighter than any previous, then store the
//        // brightness of that pixel, as well as its (x,y) location
//        if (pixelBrightness > brightestValue && pixelBrightness > threshold) {
//          brightestValue = pixelBrightness;
//          brightestY = y;
//          brightestX = x;
//          blobs[0] = x;
//          blobs[1] = y;
//        }
//        index++;
//      }
//    }
//    println(brightestX + ", " + brightestY);
//    
//    // Draw a large, yellow circle at the brightest pixel
//    fill(250, 250, 250, 128);
//    ellipse(brightestX + 22.5, brightestY + 26.5, 200, 200);
//    flag = false;
//  }
//}

void blobTracking(boolean drawBlobs, boolean drawEdges)
{
  loadPixels();
  
  //noFill();
  Blob b;
  EdgeVertex eA,eB;
  for (int n=0 ; n < theBlobDetection.getBlobNb() ; n++)
  {
    b=theBlobDetection.getBlob(n);
    if (b!=null)
    {
      // Detect and Display Edges
      if (drawEdges)
      {
        strokeWeight(3);
        stroke(0,255,0);
        for (int m=0; m < b.getEdgeNb();m++)
        {
          eA = b.getEdgeVertexA(m);
          eB = b.getEdgeVertexB(m);

          if (eA !=null && eB !=null)
          {
            line(eA.x*width, eA.y*height, eB.x*width, eB.y*height);
          }
        }
        // Detect and Display Blobs
        if (drawBlobs)
        {
          strokeWeight(1);
          stroke(255,0,0);
          fill(22,255,2,100);
          rect(b.xMin*width,b.yMin*height,b.w*width,b.h*height);
        }
      }
    }
    updatePixels();
  }
}

