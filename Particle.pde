public class Particle extends Box2DBase implements Updatable {
  boolean alive = true;
  ParticleSystem parent;
  float r1;
  float r2;
  float g1;
  float g2;
  float b1;
  float b2;
  float radius;
  float step = 0.04f;
  Particle(float _radius, float _x, float _y, color _c1, color _c2, Box2DProcessing _context) {
    super(_context);
    radius = _radius;
    r1 = red(_c1);
    r2 = red(_c2);
    g1 = green(_c1);
    g2 = green(_c2);
    b1 = blue(_c1);
    b2 = blue(_c2);


    //Shape s = setupShape(_radius);
    CircleShape s = new CircleShape();
    s.m_radius = _context.scalarPixelsToWorld(_radius);



    Filter f = new Filter();
    f.categoryBits = FilterCategory.PARTICLE;
    f.maskBits = FilterCategory.BOUNDARY | FilterCategory.PARTICLE;

    //fixture
    setupFixture(s, 0.0f, 1.f, 0.0f, f, false);
    setupPolyshape();
    setupBody(BodyType.DYNAMIC, new Vec2(_x, _y), 0.f);
    createBody();
  }

  void update() {
    if (size < step/2) {
      size = 0;
      alive = false;
    } else {
      size -= step;
    }
    mBody.applyLinearImpulse(new Vec2(0.f, 0.98f), mBody.getPosition(), true);
  }

  void draw() {
    float prev = size;

    polyShape.setFill(color(map(size, 1, 0, r1, r2), map(size, 1, 0, g1, g2), map(size, 1, 0, b1, b2), 255));

    size *= 3;
    super.draw();
    size  = prev;
  }
}

