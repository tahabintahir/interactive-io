import processing.serial.*;
import fullscreen.*;

/* Setup(), the first function called when the applet is started */

Serial dataPort;
FullScreen fs;

Cell[][] grid;

int cols = 16;
int rows = 8;

int[][]parssedData = new int [8][16];

int lF = 10;
String Buff = null;
int[][]values = new int[8][16];

int y = 0;
int avg = 0;

void setup() 
{
  /* The applet is set to 500 pixels by 500 pixels */
  size(900,700);
  /* RGB mode set to maximum of 6, since we'll be using 6 colors. 0 for black, 6 for white, and everything in between. */
  //colorMode(HSB, 6);
  /* The stroke color is used to determine the border color of each quadrilateral. */
  stroke(0);
  /* Frame rate is set to 30. */
  frameRate(200);
  
  dataPort = new Serial(this, Serial.list()[1], 115200);
  println(Serial.list());
  dataPort.write('1');
  
  fs = new FullScreen(this);
  fs.setResolution(screen.width, screen.height);
  fs.setShortcutsEnabled(true);
  //fs.enter();
  
  grid = new Cell[cols][rows]; //initialise raw feed grid
}
void draw()
{
  /* 
  Initialise sensors and get data from sensor array
  */
  parssedData = getData();

  /* Screen is cleared and background is set to 255 (white). */
  background(255); 
    /* 
  These are our loops. 
  We loop through 8 rows for the x axis, and within each row, we loop through 16 collumns for the z axis
  (x,z) is the ground, while y is verticle)
  */
  for (int x = 0; x < 8; x++) {
   for (int z = 0; z < 16; z++) {
    /* 
    The y variable is set to determine the height of the box. 
    */
//    if ((parssedData[x][z]/12)*8 > 200)
//    {
//      y = 200;
//    }
//    else
//    {
      y = parssedData[x][z]; //(parssedData[x][z]/12)*8;
      //println("y: "+y);
//    }
    
    /* 
    These are 2 coordinate variations for each quadrilateral.
    Since they can be found in 4 different quadrants (+ and - for x, and + and - for z),
    we'll only need 2 coordinates for each quadrilateral (but we'll need to pair them up differently
    for this to work fully).
    
    Multiplying the x and z variables by 30 will space them 30 pixels apart.
    The 15 will determine half the width of the box ()
    15 is used because it is half of 30. Since 15 is added one way, and 15 is subtracted the other way, the total
    width of each box is 15. This will eliminate any sort of spacing in between each box.
    
    If you enable noStroke(), then the whole thing will appear as one 3d shape. Try it.
    */
    //noStroke();
    float xm = x*30 -15;
    float xt = x*30 +15;
    float zm = z*30 -15;
    float zt = z*30 +15;
    
    
    /* We use an integer to define the width and height of the window. This is used to save resources on further calculating */
    float halfw = (float)width*0.62;
    float halfh = (float)height/3;
    
    /* 
    Here is where all the isometric calculating is done. 
    We take our 4 coordinates for each quadrilateral, and find their (x,y) coordinates using an isometric formula.
    You'll probably find a similar formula used in some of my other isometric animations. However, I normally use
    these in a function. To avoid using repetitive calculation (for each coordinate of each quadrilateral, which
    would be 3 quads * 4 coords * 3 dimensions = 36 calculations).
    
    Formerly, the isometric formula was ((x - z) * cos(radians(30)) + width/2, (x + z) * sin(radians(30)) - y + height/2).
    however, the cosine and sine are constant, so they could be precalculated. Cosine of 30 degrees returns roughly 0.866, which can round to 1,
    Leaving it out would have little artifacts (unless placed side-by-side to accurate versions, where everything would appear wider in this version)
    Sine of 30 returns 0.5. 
    
    We left out subtracting the y value, since this changes for each quadrilateral coordinate. (-40 for the base, and our y variable)
    These are later subtracted in the actual quad().
    */
    float isox1 = int(xm - zm + halfw);
    float isoy1 = int((xm + zm) * 0.5 + halfh);
    float isox2 = int(xm - zt + halfw);
    float isoy2 = int((xm + zt) * 0.5 + halfh);
    float isox3 = int(xt - zt + halfw);
    float isoy3 = int((xt + zt) * 0.5 + halfh);
    float isox4 = int(xt - zm + halfw);
    float isoy4 = int((xt + zm) * 0.5 + halfh);
    
    /* The side quads. 2 and 4 is used for the coloring of each of these quads */
    fill (70);
    //noFill();
    //fill(3 + y*sin(45), 70 + y*sin(25), 155 + y *sin(17));
    //println("y: "+y);
//    float r_val = (sin(yVal*degrees(90)))*225;
//    float g_val=0;
//    float b_val= (cos(yVal*degrees(90)))*225;
//    fill (sin(degrees(y/200*90))*225, tan(degrees(y/200*90))*225, cos(degrees(y/200*90))*225);
    quad(isox2, isoy2-y, isox3, isoy3-y, isox3, isoy3+40, isox2, isoy2+40);
    
    fill (150);
    //noFill();
    //fill(225*sin(y) + y*sin(90), 225 + y*sin(220), 225 + y *sin(107));
    quad(isox3, isoy3-y, isox4, isoy4-y, isox4, isoy4+40, isox3, isoy3+40);
    
    /* 
    The top quadrilateral. 
    y, which ranges between -24 and 24, multiplied by 0.05 ranges between -1.2 and 1.2
    We add 4 to get the values up to between 2.8 and 5.2. 
    This is a very fair shade of grays, since it doesn't become one extreme or the other.
    */
    //noFill();
    fill(190 + y * 0.5);
    quad(isox1, isoy1-y, isox2, isoy2-y, isox3, isoy3-y, isox4, isoy4-y);
   }
  }
  
  /*****************************************************************************/
  for (int i = 0; i < cols; i ++ ) {
    for (int j = 0; j < rows; j ++ ) {
      // Initialize each object
      grid[i][j] = new Cell(i*10,j*10,10,10,parssedData[j][i]);
    }
  }
  
  for (int i = 0; i < cols; i ++ ) {     
    for (int j = 0; j < rows; j ++ ) {
      // Display each object
      grid[i][j].display();
    }
  } 
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
          for(int w=15; w >= 0; w--)
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

void byteAvailable()
{
  while (dataPort.available() < 1); //do nothing untill buffer has atleast one byte
}

