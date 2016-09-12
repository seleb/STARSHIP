import ddf.minim.*;
import ddf.minim.analysis.*;
import shiffman.box2d.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.contacts.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.collision.*;
import org.jbox2d.collision.shapes.*;

// main Game class
class Game implements Drawable, Updatable {

  boolean started = false;
  boolean paused = true;

  Box2DProcessing mBox2D;
  Connection connection;
  ChunkManager ground;
  Player player;

  // display/update properties
  float prevPlayerX = 0, prevPlayerY = 0;
  float zoom = 1;
  float camX = 0, camY = 0;
  final int effectScale = 4;
  PShape gridShape;
  ArrayList<Drawable>  mDrawables;
  ArrayList<Updatable>  mUpdatables;

  // audio properties
  final boolean audioOn = true;
  FFT fft;
  Minim minim;
  AudioPlayer pop;
  AudioPlayer popLoud;
  AudioPlayer hit;
  AudioPlayer starGet;
  AudioPlayer bgMusic;
  int popThrottle = 5;


  Game(PApplet _context) {
    // init box2D
    mBox2D = new Box2DProcessing(_context);
    mBox2D.createWorld();
    mBox2D.setGravity(0.0, -98);
    mBox2D.listenForCollisions();

    // pass context to PShapes helper
    ReusablePShapes.init(_context);

    // create player
    player = new Player(50, mBox2D);
    player.mBody.setTransform(new Vec2(0, mBox2D.scalarPixelsToWorld(height)), 0);

    // initialize connection
    connection = new Connection(player, _context);
    ground = new ChunkManager(mBox2D, connection);

    // initialize display/update lists
    mDrawables = new ArrayList<Drawable>();
    mUpdatables = new ArrayList<Updatable>();
    mDrawables.add(player);
    mUpdatables.add(player);
    mDrawables.add(ground);
    mUpdatables.add(ground);

    // initialize audio
    if (audioOn) {
      minim = new Minim(_context);
      bgMusic = minim.loadFile("custom thing.mp3");
      pop = minim.loadFile("pop-quiet.wav");
      popLoud = minim.loadFile("pop.wav");
      hit = minim.loadFile("hit.wav");
      starGet = minim.loadFile("starGet.wav");
      bgMusic.loop();
      fft = new FFT( bgMusic.bufferSize(), bgMusic.sampleRate() );
    }

    gridShape = ReusablePShapes.getGridShape(width, height, effectScale);
    gridShape.setStroke(color(0, 50, 50, 255/4));
  }


  void update() {
    connection.update();

    // if a chunk was received from the server, process it here
    if (connection.chunkReceived) {
      ground.addChunk();
    }

    if (!paused) {
      // ask the server for a chunk if necessary
      if (!connection.waitingForChunk) {
        ground.checkForChunks(prevPlayerX);
      }

      // calculate zoom factor
      zoom += (map(dist(player.pos.x, player.pos.y, prevPlayerX, prevPlayerY), 0, 50, 1.f, 0.2f) * (player.thrustOn ? 0.75 : 1) - zoom)*0.2 ;

      // save previous position for next time
      prevPlayerX = player.pos.x;
      prevPlayerY = player.pos.y;

      // update the camera
      camX += (-player.pos.x+width/(2*zoom) - (max(0, min(mouseX, width)) - width*0.5)/zoom*0.5 - camX) * 0.5;
      camY += (-player.pos.y+height/(2*zoom) - (max(0, min(mouseY, height)) - height*0.5)/zoom*0.5 - camY) * 0.5;

      // calculate player control vector
      Vec2 dir = new Vec2((mouseX/zoom-camX) - player.pos.x, (mouseY/zoom-camY) - player.pos.y);
      player.dir = dir;

      // sfx
      popThrottle -= 1;
      if (player.thrustOn && player.throttle <= player.throttleStep) {
        if (audioOn) {
          if (popThrottle < 0) {
            if (player.thrustBoostOn) {
              popLoud.rewind();
              popLoud.play();
            } else {
              pop.rewind();
              pop.play();
            }
            popThrottle = 3;
          }
        }
      }

      // update game elements
      for (Updatable u : mUpdatables) {
        u.update();
      }

      // update box2D
      mBox2D.step();

      // interpolate data from server
      if (connection.playerDataDisplay != null) {
        for (int i = 0; i < connection.playerDataDisplay.length && i < connection.playerDataNew.length; ++i) {
          connection.playerDataDisplay[i] += (connection.playerDataNew[i] - connection.playerDataDisplay[i])/10;
        }
      }
    }

    // process audio
    if (audioOn) {
      fft.forward( bgMusic.mix );
    }
  }
  void draw() {
    // draw scene
    noSmooth();
    pushMatrix();
    {
      // setup for pixel effect
      clip(0, 0, width/effectScale, height/effectScale);
      scale(1.f/effectScale);

      // audio-visual sky
      noStroke();
      fill(0, 50, 50);
      beginShape();
      if (audioOn) {
        fill(fft.getBand(8)/100 * 150, fft.getBand(4)/100 * 125 + 50, fft.getBand(0)/100 * 125 + 50);
      }
      vertex(0, 0);
      if (audioOn) {
        fill(fft.getBand(12)/100 * 150, fft.getBand(8)/100 * 125 + 50, fft.getBand(4)/100 * 125 + 25);
      }
      vertex(0, height);
      if (audioOn) {
        fill(fft.getBand(16)/100 * 150, fft.getBand(12)/100 * 125 + 50, fft.getBand(8)/100 * 125 + 25);
      }
      vertex(width, height);
      if (audioOn) {
        fill(fft.getBand(20)/100 * 150, fft.getBand(16)/100 * 125 + 50, fft.getBand(12)/100 * 125 + 50);
      }
      vertex(width, 0);
      endShape(CLOSE);

      pushMatrix();
      {
        scale(zoom);
        translate(camX, camY);

        // draw direction control line
        pushMatrix(); 
        {
          strokeWeight(7);
          translate(player.pos.x, player.pos.y);
          beginShape(LINES);
          stroke(61, 153, 153);
          vertex(0, 0);
          stroke(255, 64, 108);
          vertex(player.dir.x, player.dir.y);
          endShape();
        }
        popMatrix();

        // draw game elements
        for (Drawable t : mDrawables) {
          t.draw();
        }

        // draw player position/score indicators
        textAlign(CENTER, CENTER);
        noFill();
        for (int i = 0; i < connection.playerDataDisplay.length; i+=4) {
          pushMatrix();
          {
            float xMouseOffset = (max(0, min(mouseX, width)) - width*0.5)/zoom*0.5;
            float yMouseOffset = (max(0, min(mouseY, height)) - height*0.5)/zoom*0.5;
            float x = max(player.pos.x-width/(2.2*zoom) + xMouseOffset, min(player.pos.x+width/(2.2*zoom) + xMouseOffset, connection.playerDataDisplay[i] + width/2));
            float y = max(player.pos.y-height/(2.2*zoom) + yMouseOffset, min(player.pos.y+height/(2.2*zoom) + yMouseOffset, connection.playerDataDisplay[i+1] + height/2));
            int score = round(connection.playerDataDisplay[i+2]);
            translate(x, y);
            scale(1/zoom);

            strokeWeight(5);
            stroke(255, 64, 108);
            noFill();
            ellipse(0, 0, 75, 75);
            translate(0, 20);
            int scoreMod = score % 100;
            if (scoreMod == 0) {
              scoreMod = 100;
            }
            scale(map(scoreMod, 1, 100, 2, 0.75));
            fill(255, 255, map(scoreMod, 100, 1, 100, 0));
            text(score, 0, -30);
          }
          popMatrix();
        }
      }

      popMatrix();

      // draw paused text
      if (paused) {
        fill(255);
        textAlign(CENTER, CENTER);
        text("PAUSED", width/2, height/2);
        text("click to resume", width/2, height/2 + 32);
      }

      // draw pointer
      strokeWeight(5);
      stroke(255, 64, 108);
      if (player.thrustOn) {
        if (player.thrustBoostOn) {
          fill(255, 0, 0);
        } else {
          fill(255, 64, 108);
        }
      } else {
        fill(61, 153, 153);
      }
      ellipse(mouseX, mouseY, 16, 16);
    }
    popMatrix();

    // draw damage glitch effect
    float dmg = map(player.control, 1, 0, 0, 2);
    for (int i = 0; i < dmg; ++i) {
      int x = (int)random(width/effectScale);
      copy(x, (int)random(height/effectScale), (int)random(width/effectScale - x), (int)random(dmg)*3+1, 0, (int)random(height/effectScale), width/effectScale, (int)random(dmg)*3+1);
    }

    // scale image to fill screen to complete pixel effect
    clip(0, 0, width, height);
    copy(0, 0, width/effectScale, height/effectScale, 0, 0, width, height);

    // dull colours if paused
    if (paused) {
      fill(255, 255/2);
      rect(0, 0, width, height);
    }

    // draw pixel grid outline
    if (audioOn) {
      gridShape.setStroke(color(fft.getBand(3)/100 * 255 * sin(player.pos.x/(width*2)), fft.getBand(2)/100 * 150 + 50 * cos(player.pos.x/(width*2.1)), fft.getBand(1)/100 * 150 + 50, 128-64*player.control));
    } else {
      gridShape.setStroke(color(0, 50 * sin(player.pos.x/(width*2)), 50 * cos(player.pos.x/(width*2.1)), 128-64*player.control));
    }
    shape(gridShape);
  }
};


// box2D contact listener
void beginContact(Contact cp) {
  Fixture f1 = cp.getFixtureA();
  Fixture f2 = cp.getFixtureB();
  Body b1 = f1.getBody();
  Body b2 = f2.getBody();

  Object o1 = b1.getUserData();
  Object o2 = b2.getUserData();

  if (o1.getClass() == Player.class) {
    if (o2.getClass() == Pickup.class) {
      Pickup p = (Pickup)o2;
      ((Player)o1).pickup(p);
    }

    if ((f2.getFilterData().categoryBits & FilterCategory.BOUNDARY) != 0) {
      ((Player)o1).damage();
      game.hit.rewind();
      game.hit.play();
    }
  } else if (o2.getClass() == Player.class) {
    if (o1.getClass() == Pickup.class) { 
      Pickup p = (Pickup)o1;
      ((Player)o2).pickup(p);
    }

    if ((f1.getFilterData().categoryBits & FilterCategory.BOUNDARY) != 0) {
      ((Player)o2).damage();
      game.hit.rewind();
      game.hit.play();
    }
  }
}

void endContact(Contact cp){
}