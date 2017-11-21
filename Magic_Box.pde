import java.util.*;
import java.io.File;
import java.awt.Color;
import processing.sound.*;
import processing.video.*;

String SOUNDS_PATH = "/Users/gullumbroso/Google Drive/Texperience/Painting to Music/sounds/";
String PHOTOS_PATH = "/Users/gullumbroso/Google Drive/Texperience/Painting to Music/photos/";
int PIXELS_THRESHOLD = 15;
long PAUSE_BETWEEN_SOUNDS = 180; // Determines the rhythm
int BLUE_DELAY = 4;
int RED_DELAY = 4;
int GREEN_DELAY = 3;



static List<SoundFile> blackSounds = new ArrayList<SoundFile>();
static List<SoundFile> redSounds = new ArrayList<SoundFile>();
static List<SoundFile> greenSounds = new ArrayList<SoundFile>();
static List<SoundFile> blueSounds = new ArrayList<SoundFile>();

Capture cam;
PImage photo;
MusicGrid grid;
boolean tookPhoto, playing, drumsPlaying, drawingIn;
int colIndex;
SoundFile drums; // The drums in the background.
SoundFile begin;
long startTime, delayPhoto;


public class MusicGrid {
 
  public static final int numHorCells = 64;
  public static final int numVerCells = 22;

  public int cellWidth;
  public int cellHeight;
  public int remainderWidth;
  public int remainderHeight;
  public float rhythm = 1.0;
  public List<List> soundColumns = new ArrayList();

  public MusicGrid() {
    /*
    *
     */
    this.cellWidth = photo.width / MusicGrid.numHorCells;
    this.cellHeight = photo.height / MusicGrid.numVerCells;
    this.remainderWidth = photo.width % MusicGrid.numHorCells;
    this.remainderHeight = photo.height % MusicGrid.numVerCells;
  }

  public MusicGrid(float rhythm) {
    /*
    *
     */
    this.cellWidth = photo.width / MusicGrid.numHorCells;
    this.cellHeight = photo.height / MusicGrid.numVerCells;
    if (rhythm != 0.0f) this.rhythm = rhythm;
  }
}

void setup() {
  size(640, 480);
  loadSounds();
  drums = new SoundFile(this, SOUNDS_PATH + "drums/1.mp3");
  begin = new SoundFile(this, SOUNDS_PATH + "begin.mp3");
  loadCamera();
}

void loadCamera() {
  /*
  * Sets up the camera 
  */
  String[] cameras = Capture.list();
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    for (String camName : cameras) { //<>//
      if (camName.contains("name=Microsoft LifeCam")) { //<>//
        cam = new Capture(this, camName); //<>//
        cam.start();
        return;
      }
    }   
    println("Didn't find any camera!");
  }  
}

void buildMusicGrid(String file) {
  photo = loadImage(PHOTOS_PATH + file);
  grid = new MusicGrid();
  musicLoop();
  drawGrid();
}

boolean fileExists(String path) {
  return new File(path).isFile();
}

void loadSounds() {
  for (int i=1; i <= MusicGrid.numVerCells; i++) {
    
    blackSounds.add(null);
    
    // Blue sounds
    int k = i + 6; //<>//
    String numBlue = "0" + Integer.toString(k);
    String path = SOUNDS_PATH + "piano/" + numBlue + ".mp3"; // The new 36 notes files
    //String path = SOUNDS_PATH + "piano/" + Integer.toString(i) + ".mp3"; // The original 15 notes files
    if (fileExists(path)) {
      SoundFile file = new SoundFile(this, path);
      file.amp(1.0);
      blueSounds.add(file);
    } else {
     println("Path Error - No such sound file :(");
    }

    //Green sounds
    int q = i + 6;
    String numGreen = "0" + Integer.toString(q);
    path = SOUNDS_PATH + "viola/" + numGreen + ".wav"; // The new 36 notes files
    //path = SOUNDS_PATH +  "viola/" + Integer.toString(q) + ".mp3";
    if (fileExists(path)) {
    SoundFile file = new SoundFile(this, path);
    file.amp(0.1);
    greenSounds.add(file);
    }
    //greenSounds.add(null);
 
    // Red sounds  
    int j = i % 5;
    if (j == 0) {
      j = 1;
    }
    path = SOUNDS_PATH + "bass/" + Integer.toString(j) + ".mp3";
    if (fileExists(path)) {
    SoundFile file = new SoundFile(this, path);
    file.amp(0.25);
    redSounds.add(file);
    } else {
    println("Path Error - No such sound file :(");
    }
    //blueSounds.add(null);
  }
}

/*
String numRed = "0" + Integer.toString(i);
    path = SOUNDS_PATH + "bass/" + numRed + ".mp3";
    if (fileExists(path)) {
    SoundFile file = new SoundFile(this, path);
    file.amp(0.25);
    redSounds.add(file);
    } else {
    println("Path Error - No such sound file :(");
    }
*/

void musicLoop() {
  /*
  *
  */
  photo.loadPixels();
  
  int sumWidth = 0;
  int sumHeight = 0;
  
  int x = 0;
  int y = 0;
  
  boolean[] blueBuffers = new boolean[MusicGrid.numVerCells];
  int blueCounter = 0;
  
  boolean[] redBuffers = new boolean[MusicGrid.numVerCells];
  int redCounter = 0;
  
  boolean[] greenBuffers = new boolean[MusicGrid.numVerCells];
  int greenCounter = 0;
  boolean noteYesNoteNo = false;
  
  while (sumWidth + grid.cellWidth <= photo.width) {
    List<List> soundColumn = new ArrayList();
    while (sumHeight + grid.cellHeight <= photo.height) {
      boolean[] spottedColors = spotColorsInCell(sumWidth, sumHeight, grid.cellWidth, grid.cellHeight);
      List<SoundFile> cellSounds = new ArrayList();
      
      if (spottedColors[0]) {
        // There is black in the cell
        cellSounds.add(blackSounds.get(y));
      } else {
        cellSounds.add(null);
      }
      
      if (spottedColors[1]) {
        // There is red in the cell. Red is bass.
        if (redBuffers[y] && redCounter < RED_DELAY) {
          cellSounds.add(null);
          redCounter++;
        } else {
          cellSounds.add(redSounds.get(y));
          redBuffers[y] = true;
          redCounter = 0;
        }
      } else {
        cellSounds.add(null);
        redBuffers[y] = false;
      }
      
      if (spottedColors[2]) {
        // There is green in the cell. Green is viola.
        if (greenBuffers[y] && greenCounter < GREEN_DELAY) {
          cellSounds.add(null);
          greenCounter++;
          noteYesNoteNo = true;
        } else if (noteYesNoteNo) {
          cellSounds.add(null);
          noteYesNoteNo = false;
        } else {
          cellSounds.add(greenSounds.get(y));
          greenBuffers[y] = true;
          greenCounter = 0;
          noteYesNoteNo = true;
        }
      } else {
        cellSounds.add(null);
        greenBuffers[y] = false;
        noteYesNoteNo = false;
      }      
      
      if (spottedColors[3]) {
        // There is blue in the cell. Blue is piano.
        if (blueBuffers[y] && blueCounter < BLUE_DELAY) {
          cellSounds.add(null);
          blueCounter++;
        } else {
          cellSounds.add(blueSounds.get(y));
          blueBuffers[y] = true;
          blueCounter = 0;
        }
      } else {
        cellSounds.add(null);
        blueBuffers[y] = false;
      }
      soundColumn.add(cellSounds);
      sumHeight = grid.cellHeight * ++y;
    }
    grid.soundColumns.add(soundColumn);
    sumHeight = 0;
    y = 0;
    sumWidth = grid.cellWidth * ++x;
  }
}

void stopPlayingGreenNotes(List<SoundFile> playingNotes) {
  for (SoundFile note : playingNotes) {
    note.stop();
  }
  playingNotes.clear();
}

boolean[] spotColorsInCell(int startX, int startY, int cellWidth, int cellHeight) {
  /*
  * Returns an array of booleans in which the first element states if there's black, second if there's red, third green, and fourth blue.
  */
  int black = 0;
  int red = 0;
  int green = 0;
  int blue = 0;
  for (int x = startX; x < startX + cellWidth; x++) {
    for (int y = startY; y < startY + cellHeight; y++) {
      //Color pixel = new Color(photo.pixels[y * MusicGrid.numHorCells + x]);
      Color pixel = new Color(photo.get(x,y));
      float[] ch = Color.RGBtoHSB(pixel.getRed(), pixel.getGreen(), pixel.getBlue(), null);
      if (isWhite(ch)) {
        continue;
      } else if (isRed(ch)) {
        red++;
        continue;
      } else if (isGreen(ch)) {
        green++;
        continue;
      } else if (isBlue(ch)) {
        blue++;
      }
      photo.updatePixels();
    }
  }
  boolean[] colors = {false, false, false, false}; // {black, red, green, blue}
  if (black > PIXELS_THRESHOLD) colors[0] = true;
  if (red > PIXELS_THRESHOLD) colors[1] = true;
  if (green > PIXELS_THRESHOLD) colors[2] = true;
  if (blue > PIXELS_THRESHOLD) colors[3] = true;
  return colors;
}

boolean[] testSpotColorsInCell(int startX, int startY, int cellWidth, int cellHeight) {
  /*
  * Returns an array of booleans in which the first element states if there's black, second if there's red, third green, and fourth blue.
  */
  int black = 0;
  int red = 0;
  int green = 0;
  int blue = 0;
  for (int x = startX; x < startX + cellWidth; x++) {
    for (int y = startY; y < startY + cellHeight; y++) {
      //Color pixel = new Color(photo.pixels[y * MusicGrid.numHorCells + x]);
      Color pixel = new Color(photo.get(x,y));
      float[] ch = Color.RGBtoHSB(pixel.getRed(), pixel.getGreen(), pixel.getBlue(), null);
      if (isWhite(ch)) {
        continue;
      } else if (isRed(ch)) {
        //red++;
        photo.set(x, y, color(0,255,0));
        continue;
      } else if (isGreen(ch)) {
        photo.set(x, y, color(0,0,255));
        //green++;
        continue;
      } else if (isBlue(ch)) {
        photo.set(x, y, color(0));
        //blue++;
      }
      photo.updatePixels();
    }
  }
  boolean[] colors = {false, false, false, false}; // {black, red, green, blue}
  if (black > PIXELS_THRESHOLD) colors[0] = true;
  if (red > PIXELS_THRESHOLD) colors[1] = true;
  if (green > PIXELS_THRESHOLD) colors[2] = true;
  if (blue > PIXELS_THRESHOLD) colors[3] = true;
  return colors;
}

void drawGrid() {
  /*
  *
  */
  photo.loadPixels();
  int sumWidth = 0;
  int sumHeight = 0;
  int x = 0;
  int y = 0;
  while (sumWidth + grid.cellWidth <= photo.width) {
    while (sumHeight + grid.cellHeight <= photo.height) {
      boolean[] spottedColors = spotColorsInCell(sumWidth, sumHeight, grid.cellWidth, grid.cellHeight);
      boolean black = spottedColors[0];
      boolean red = spottedColors[1];
      boolean green = spottedColors[2];
      boolean blue = spottedColors[3];
      if (black) {
        drawCellBoarders(sumWidth, sumHeight, grid.cellWidth, grid.cellHeight, color(0));
      } else if (red) {
        drawCellBoarders(sumWidth, sumHeight, grid.cellWidth, grid.cellHeight, color(255,30,30));
      } else if (green) {
        drawCellBoarders(sumWidth, sumHeight, grid.cellWidth, grid.cellHeight, color(0,255,0));
      } else if (blue) {
        drawCellBoarders(sumWidth, sumHeight, grid.cellWidth, grid.cellHeight, color(50,50,255));
      }
      sumHeight = grid.cellHeight * ++y;
    }
    sumHeight = 0;
    y = 0;
    sumWidth = grid.cellWidth * ++x;
  }
}

void drawCellBoarders(int startX, int startY, int cellWidth, int cellHeight, color gridColor) {
  /*
  * Draws the boarders around the cell.
  */
  if (gridColor == 0) {
    gridColor = color(235 - startY/4, 235 - startY/4, 250 - startY/4);
  }
  for (int x = startX; x < startX + cellWidth; x++) {
    for (int y = startY; y < startY + cellHeight; y++) {
      if (y == startY) photo.set(x, y, gridColor);
      else if (y == startY + (cellHeight - 1)) photo.set(x, y, gridColor);
      else if (x == startX) photo.set(x, y, gridColor);
      else if (x == startX + (cellWidth - 1)) photo.set(x, y, gridColor);
    }
  }
  photo.updatePixels();
}

/*
boolean isBlack(float[] hsbValue) {
  
  float saturation = hsbValue[1];
  float brightness = hsbValue[2];
  if (brightness < 0.25 && saturation < 0.3) 
    return true;
  return false;
}
*/

boolean isWhite(float[] hsbValue) {
  /*
  *
  */
  float saturation = hsbValue[1];
  if (saturation <= 0.15) return true;
  return false;
}

boolean isRed(float[] hsbValue) {
  /*
  *g
  */
  float hue = hsbValue[0] * 360; // color hue in degrees
  float saturation = hsbValue[1];
  if ((hue < 5.0 || hue >= 315.0) && saturation >= 0.4) return true;
  return false;
}

boolean isGreen(float[] hsbValue) {
  /*
  *
  */
  float hue = hsbValue[0] * 360; // color hue in degrees
  float saturation = hsbValue[1];
  if ((hue < 180.0 && hue >= 100.0) && saturation > 0.255) 
    return true;
  return false;
}

boolean isBlue(float[] hsbValue) {
  /*
  *
  */
  float hue = hsbValue[0] * 360; // color hue in degrees
  float saturation = hsbValue[1];
  if ((hue < 315.0 && hue >= 180.0) && saturation > 0.28) 
    return true;
  return false;
}

void playMusic() {
 /*
 *
 */
  for (List column : grid.soundColumns) {
    long sleepTime = 294;
    if (!playColumn(column)) {
      println("key is not pressed, exited the column, now exit the enitre music loop.");
      return;  
    }
    sleep(sleepTime);
  }
}

boolean playColumn(List<List> column) {
  /*
  * Plays the music in the column. If the painting is pulled out, stops playing and returns false.
  */
  for (List<SoundFile> cellSounds : column) {
    if (!isPressed()) {
    println("The key is not pressed! stop the music");
    return false;
    }
    for (SoundFile sound : cellSounds) { 
      if (sound != null) {
        sound.play();
        }
      }
    }
  return true;
}

void sleep(long time) {
  try {
      Thread.sleep(time);
  } 
  catch(InterruptedException ex) {
    Thread.currentThread().interrupt();
  }
}

boolean isPressed() {
  /*
  * Checks if the selected key is pressed.
  */
  return keyPressed && (key == 'g' || key == 'G');
}

void takePic() {
  saveFrame(PHOTOS_PATH + "photo1.jpg");
  println("Took the pic!");
  // Give the photo a few seconds to be loaded...
  sleep(1000);
}

void stopEverything(String message) {
  if (drawingIn && System.currentTimeMillis() - delayPhoto > 500) {
    // The music is playing. Should stop and reset all parameters.
    println(message);
    photo = null;
    grid = null;
    playing = false;
    drawingIn = false;
    startTime = 0;
    delayPhoto = 0;
  } 
}

// Real things
void draw() {
  
  if (cam.available() == true) {
   cam.read();
  }
  set(0, 0, cam);
  
  if (isPressed()) {
    // The drawing is in.
    drawingIn = true;
    if (!playing) {
      // The drawing is in for the first time. Wait a second and then take a pic and build the music grid.
      if (delayPhoto == 0) { //<>//
        begin.play();
        delayPhoto = System.currentTimeMillis();
      } else if (System.currentTimeMillis() - delayPhoto > 1500) {
        takePic();
        buildMusicGrid("photo1.jpg");
        image(photo, 0, 0, photo.width, photo.height);  
        playing = true;
        colIndex = 0;
        startTime = System.currentTimeMillis();
      }
    
    } else if (System.currentTimeMillis() - startTime > 60 * 1000) {
        stopEverything("A minute have passed, stop music");      
    
    } else {
      // Music in play mode, play the next column.
      List column = grid.soundColumns.get(colIndex);
      playColumn(column);
      if (++colIndex == grid.soundColumns.size()) {
        colIndex = 0;  
      }
      sleep(PAUSE_BETWEEN_SOUNDS);
    }
  } else {
    stopEverything("The drawing is out, stop music");
  }
}

// For testing:
/*
void draw() {
  //scale(0.4);
  // The drawing is in.
  if (!playing) {
    // The drawing is in for the first time. Take a pic and build the music grid.
    //takePic();
    buildMusicGrid("photo1.jpg");
    image(photo, 0, 0, photo.width, photo.height);   //<>//
    playing = true;  
    colIndex = 0;
    startTime = System.currentTimeMillis();
    
  } else if (System.currentTimeMillis() - startTime > 65 * 1000) {
      // Stop this iteration.
  } else {
      // Music in play mode, play the next column.
      if (!drumsPlaying && System.currentTimeMillis() - startTime > 50) {
        // Start the drums in the background.
        drums.play();
        drums.rate(0.95);
        drumsPlaying = true;
      }
      List column = grid.soundColumns.get(colIndex);
      playColumn(column);
      if (++colIndex == grid.soundColumns.size()) {
        colIndex = 0;  
      }
      sleep(PAUSE_BETWEEN_SOUNDS);
  }
}
*/