// box2D element which uses a prismatic joint to shoot random polygonal obstacles vertically
class Cannon extends Box2DBase implements Updatable {
  Box2DBase base;
  RandomPolygon obstacle;
  PrismaticJoint joint;

  Cannon(float _x, float _y, Box2DProcessing _context) {
    super(_context);

    base = new Box2DBase(_context);

    PolygonShape shape = new PolygonShape();
    shape.setAsBox(mBox2D.scalarPixelsToWorld(0), mBox2D.scalarPixelsToWorld(0));

    base.setupFixture(shape, 0.0f, 10.f, 0.1f, new Filter(), false);
    base.setupBody(BodyType.STATIC, new Vec2(_x, _y), 0.1f);
    base.createBody();

    obstacle = new RandomPolygon(random(5, 10), (int)random(5, 8), 0, 0, _context);
    obstacle.c = color(181, 181, 186);
    obstacle.polyShape.setFill(obstacle.c);

    Filter f = new Filter();
    f.categoryBits = FilterCategory.BOUNDARY;
    f.maskBits = FilterCategory.PLAYER | FilterCategory.PARTICLE;
    obstacle.mBody.getFixtureList().setFilterData(f);


    PrismaticJointDef djd = new PrismaticJointDef();
    djd.bodyA = base.mBody;
    djd.bodyB = obstacle.mBody;
    djd.collideConnected = false;
    djd.localAxisA.x = 0;
    djd.localAxisA.y = mBox2D.scalarPixelsToWorld(1);
    djd.referenceAngle = random(0, TWO_PI);
    djd.enableLimit = true;
    djd.lowerTranslation = 0;
    djd.upperTranslation = mBox2D.scalarPixelsToWorld(height*20);

    joint = (PrismaticJoint) _context.world.createJoint(djd);
  }

  void destroy() {
    base.destroy();
    obstacle.destroy();
  }

  void draw() {
    obstacle.draw();
  }

  boolean launched = false;
  void update() {
    Vec2 p1 = new Vec2();
    Vec2 p2 = new Vec2();
    joint.getAnchorA(p1);
    joint.getAnchorB(p2);
    // if the obstacle isn't in the air already, randomly decide whether to launch it or not
    if (dist(p1.x, p1.y, p2.x, p2.y) < 1) {
      if (random(0, 1) > 0.99) {
        obstacle.mBody.applyLinearImpulse(new Vec2(0, 10000*obstacle.mBody.getMass()), obstacle.mBody.getPosition(), true);
      }
    }
  }
}

