// A Cell object

class Cell {

  // A cell object knows about its location in the grid as well as its size with the variables x, y, w, h.
  float x,y;  // cell x,y location
  float w,h;  // cell width and height
  float data; // data for cell brightness
  
  // Cell Constructor
  Cell(float tempX, float tempY, float tempW, float tempH, float tempData) {
    x = tempX;
    y = tempY;
    w = tempW;
    h = tempH;
    data = tempData;// * 0.0622;
  }
  
  void display() {
    //colorMode(RGB, 12);
    stroke(100);
    // Color calculated based on live data
    if (data > 3)
    {
      fill(data);
    }
    else
    {
      fill(0);
    }
    //rect(477+x,235.5+y,w,h);
    rect(x + 730,y +10,w,h);
  }
}

