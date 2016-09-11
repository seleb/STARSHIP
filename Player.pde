// main Player class
public class Player extends Box2DBase implements Updatable {
  // vectors: direction, speed, position, onlinePosition (slightly different coordinate system used)
  Vec2 dir, sp, pos, onlinePos;

  // thrust properties
  boolean thrustOn = false;
  boolean thrustBoostOn = false;
  float thrustBoost = 10;
  float throttle = 1;
  float throttleStep = 0.25;
  float thrustSpeed = 400;

  // particle properties
  ParticleSystem particleSystem;
  float bubbleCount = 5;
  float bubbleSize = 1;

  // player size
  float radius;

  // total score and score multiplier (applied to pickup scores)
  float score = 0; 
  int multiplier = 1; 

  // vertex buffers with two versions of ship graphic
  PShape displayShape; 
  PShape displayShapeDamaged;

  // id provided by server
  int id = -1; 

  // how in control of their actions the player is
  float control = 1; 

  Player(float _radius, Box2DProcessing _context) {
    super(_context);
    radius = mBox2D.scalarPixelsToWorld(_radius);
    displayShape = loadShape("ship.svg");
    displayShapeDamaged = loadShape("ship.svg");
    displayShapeDamaged.disableStyle(); // this is done so that we can recolour the graphic in Processing
    dir = new Vec2(0, 0);
    sp = new Vec2(0, 0);
    pos = new Vec2(0, 0);
    onlinePos = new Vec2(0, 0);

    Filter f = new Filter();
    f.categoryBits = FilterCategory.PLAYER;
    f.maskBits = FilterCategory.BOUNDARY | FilterCategory.PICKUP;
    // shape
    CircleShape shape = new CircleShape();
    shape.m_radius = radius;

    setupFixture(shape, 0.0f, 10.f, 0.1f, f, false);
    setupBody(BodyType.DYNAMIC, new Vec2(0, 0), 0.1f);
    createBody();

    particleSystem = new ParticleSystem(_context);
  }

  // picks up a pickup
  void pickup(Pickup _p) {
    if (!_p.used) {
      // edit pickup
      _p.used = true;
      _p.justUsed = true;
      _p.size = 1;
      _p.score *= multiplier;

      // thrust bonus
      throttleStep = min(1, throttleStep+0.1);
      if (throttleStep >= 0.99) {
        bubbleSize = min(4, bubbleSize+0.25);
        bubbleCount = min(10, bubbleCount+0.75);
      }
      // score bonus
      score += _p.score;
      multiplier += 1;
    }
  }

  // taking damage halves score, resets multiplier, causes the player to lose control temporarily, and reduces thrust
  void damage() {
    // only affect score if the player was hit while in full control (super unfair otherwise)
    if (control >= 0.99) {
      multiplier = 1;
      score /= 2;
      score -= score % 100;
    }

    // lose control
    control = 0;
    mBody.applyLinearImpulse(mBox2D.vectorPixelsToWorld(new Vec2(0, -1000 * mBody.getMass())), mBody.getPosition(), true);

    // lose thrust
    bubbleSize = max(1, bubbleSize-0.25);
    bubbleCount = max(5, bubbleCount-0.75);
    if (bubbleSize <= 1.001 && bubbleCount <= 5.001) {
      throttleStep = max(0.15, throttleStep-0.1);
    }
  }


  void update() {

    // store position (used in multiple areas)
    pos = mBox2D.coordWorldToPixels(mBody.getPosition());
    onlinePos = mBox2D.vectorWorldToPixels(mBody.getPosition());

    // update particle system 
    particleSystem.update();
    if (thrustOn && throttle <= 0 ) {
      int mult = (int)(random(bubbleCount/2, bubbleCount*1.5) * (thrustBoostOn ? 2 : 1));
      for (int i = 0; i < mult; ++i) {
        Particle x = particleSystem.addParticle(random(1, bubbleSize*5), pos.x+random(-mult, mult), pos.y+random(-mult, mult), color(255, 64, 108), color(61, 153, 153));
        x.mBody.applyLinearImpulse(new Vec2(-sp.x+random(-3, 3)*100, sp.y+random(-3, 3)*100), x.mBody.getPosition(), true);
        if (thrustBoostOn) {
          x.size *= 2;
        }
      }
    }

    // regain control
    if (control < 1) {
      control += 0.02;
    } else {
      control = 1;
    }

    // update direction
    float desiredAngle = atan2(-dir.y, dir.x);
    float nextAngle =  mBody.getAngle() + mBody.getAngularVelocity() / 10.0;
    float totalRotation = desiredAngle - nextAngle + map(control, 0, 1, 8*PI, 0);
    while ( totalRotation < -PI ) {
      totalRotation += TWO_PI;
    };
    while ( totalRotation >  PI ) {
      totalRotation -= TWO_PI;
    };
    float desiredAngularVelocity = totalRotation * 10;
    float torque = mBody.getInertia() * desiredAngularVelocity / (1/10.0);
    mBody.applyTorque( torque );

    // update speed
    sp.x = thrustSpeed * cos(mBody.getAngle()) * mBody.getMass();
    sp.y = -thrustSpeed * sin(mBody.getAngle()) * mBody.getMass();
    if (thrustOn) {
      if (throttle <= 0) {
        throttle = 1;
        if (thrustBoostOn) {
          throttle *= thrustBoost;
          sp.x *=thrustBoost;
          sp.y *= thrustBoost;
        }
        mBody.applyLinearImpulse(mBox2D.vectorPixelsToWorld(sp), mBody.getPosition(), true);
      } else {
        throttle -= throttleStep;
      }
    }
  }

  void draw() {
    particleSystem.draw();

    noStroke();
    pushMatrix();
    {

      Fixture t = mBody.getFixtureList();
      Shape s = (Shape) t.getShape();

      ShapeType type = s.getType();

      translate(pos.x, pos.y);

      // angle has to be corrected to avoid upside-down graphics
      float angle = mBody.getAngle();
      float correctedAngle = PI/2-angle;
      while (correctedAngle < 0) {
        correctedAngle += TWO_PI;
      } 
      while (correctedAngle > TWO_PI) {
        correctedAngle -= TWO_PI;
      }
      rotate(correctedAngle);
      if (correctedAngle > PI) {
        scale(-1, 1);
      }

      scale(size);

      float ts = mBox2D.scalarWorldToPixels(radius)*2;
      shape(displayShape, -ts/2, -ts/2, ts, ts);

      // draw a recoloured ship on top of the first to show damage
      fill(color(255, 64*control, 108*control, 255*(1-control)));
      shape(displayShapeDamaged, -ts/2, -ts/2, ts, ts);
    }
    popMatrix();
  }
}