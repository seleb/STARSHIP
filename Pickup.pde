// Stars which can be picked up by the player for points and additional thrust
class Pickup extends Box2DBase implements Updatable {
  ParticleSystem particleSystem;
  boolean growing = true;
  boolean used = false;
  boolean justUsed = false;
  boolean alive = true;
  int score = 100; // base score

  Pickup(Box2DProcessing _context, float _radius, float _x, float _y) {
    super(_context);
    c = color(255, 255, 200, 255);

    Filter f = new Filter();
    f.categoryBits = FilterCategory.PICKUP;
    f.maskBits = FilterCategory.PLAYER;

    // shape
    CircleShape shape = new CircleShape();
    shape.m_radius = mBox2D.scalarPixelsToWorld(_radius);

    setupFixture(shape, 0.0f, 10.f, 0.1f, f, true);

    polyShape = ReusablePShapes.getStar((int)random(8, 30));

    setupBody(BodyType.STATIC, new Vec2(_x, _y), 0.1f);
    createBody();

    particleSystem = new ParticleSystem(_context);
    mBody.setTransform(mBody.getPosition(), random(0, TWO_PI));
  }

  void update() {
    if (alive) {
      // if the pickup was just picked up, add some particles
      if (justUsed) {
        size = 1;
        Vec2 pos = mBox2D.getBodyPixelCoord(mBody);
        justUsed = false;
        for (int i = 0; i < random (5, 10); ++i) {
          particleSystem.addParticle(random(3, 5), pos.x, pos.y, color(255, 255, random(100, 255)), color(255, 255, random(100)));
          for (Particle p : particleSystem.particles) {
            p.polyShape = polyShape;
            p.mBody.applyLinearImpulse(new Vec2(-random(-10, 10), random(-10, 10)), p.mBody.getPosition(), true);
            p.step = 0.02f;
          }
        }
      }

      // if the pickup hasn't been used, animate it
      if (!used) {
        if (growing) {
          size += 0.01f;
          if (size > 1.5) {
            growing = false;
          }
        } else {
          size -= 0.01f;
          if (size < 0.5) {
            growing = true;
          }
        }
        float angle = mBody.getAngle();
        angle += 0.01;
        if (angle > TWO_PI) {
          angle -= TWO_PI;
        }
        mBody.setTransform(mBody.getPosition(), angle);
      } else { 
        size -= 0.01;
      }
      particleSystem.update();

      // if the pickup has been picked up, the particles have all died, and the text has faded out, the pickup is no longer needed
      if (used && (particleSystem.particles.size() == 0 || size <= 0)) {
        alive = false;
      }
    }
  }
  void draw() {
    if (alive) {
      if (!used) {
        polyShape.setFill(c);
        super.draw();
      } else {
        // if the pickup has been picked up, draw a fading text indicator showing how many points were scored
        fill(c, size*255);
        pushMatrix();
        Vec2 pos = mBox2D.getBodyPixelCoord(mBody);
        translate(pos.x, pos.y);
        text((score+"!"), 0, 0);
        popMatrix();
        particleSystem.draw();
      }
    }
  }
}