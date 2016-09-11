// game application

Game game;
void setup() {
  size(1280, 720, P2D);
  frameRate(60);

  // render settings
  noCursor();
  noSmooth();
  textureMode(NORMAL);
  ((PGraphicsOpenGL)g).textureSampling(2);

  // load font
  PFont hbFont = createFont("Hurly-Burly.ttf", 48, false);
  textFont(hbFont, 48);

  game = new Game(this);
}


void draw() {

  if (game.started) {
    // if the window isn't focused, pause automatically
    if (!focused) {
      game.paused = true;
    }

    // game loop
    game.update();
    game.draw();
  } else {
    // splashs creen
    pushMatrix();
    // setup for pixel effect
    clip(0, 0, width/4, height/4);
    scale(1.f/4);

    // draw menu
    background(0);
    textAlign(CENTER, CENTER);
    fill(255, 0, 108);
    text("STARSHIP", width/2, height/2);
    fill(255, 255, 200);
    text("click to play", width/2, height/2+60);

    // scale image to fill screen
    clip(0, 0, width, height);
    copy(0, 0, width/4, height/4, 0, 0, width, height);

    popMatrix();
    shape(game.gridShape);
  }
}

// gameplay controls
boolean lmb = false;
boolean rmb = false;
void mousePressed() {
  if (game.paused) {
    game.paused = false;
  }
  if (!game.started) {
    game.started = true;
  }
  if (mouseButton == LEFT) {
    lmb = true;
  }
  if (mouseButton == RIGHT) {
    rmb = true;
  }

  if (lmb || rmb) {
    game.player.thrustOn = true;
    if (rmb) {
      game.player.thrustBoostOn = true;
    }
  }
}
void mouseReleased() {
  if (mouseButton == LEFT) {
    lmb = false;
  }
  if (mouseButton == RIGHT) {
    rmb = false;
  }

  if (!rmb) {
    game.player.thrustBoostOn = false;
    if (!lmb) {
      game.player.thrustOn = false;
    }
  }
}
void keyPressed() {
  if (key == 'p') {
    game.paused = !game.paused;
  }
}
