// base class used for Box2D elements
class Box2DBase implements Drawable {
  // box2D context
  Box2DProcessing mBox2D;

  // box2D objects
  FixtureDef fixtureDef;
  BodyDef bodyDef;
  Body mBody;

  // vertex buffer
  PShape polyShape = null;

  float size = 1.f;
  color c = 0;

  Box2DBase(Box2DProcessing _context) {
    mBox2D = _context;
    c = color(255, 255, 235);
  }

  // this needs to be called when removing elements from the game or box2D will leak memory
  void destroy() {
    mBox2D.world.destroyBody(mBody);
    mBox2D = null;
    mBody = null;
  }


  void draw() {
    pushMatrix();
    {
      Vec2 pos = mBox2D.coordWorldToPixels(mBody.getPosition());
      float angle = mBody.getAngle();

      Fixture t = mBody.getFixtureList();
      Shape s = (Shape) t.getShape();

      ShapeType type = s.getType();

      translate(pos.x, pos.y);
      rotate(-angle);
      scale(size);

      switch(type) {
      case CIRCLE:
        pushMatrix();
        {
          // the vertex buffer for the circle contains a unit circle, so it needs to be scaled to match the radius
          scale(mBox2D.scalarWorldToPixels(((CircleShape)s).m_radius*2));
          shape(polyShape);
        }
        popMatrix();
        break;
      case POLYGON:
      case CHAIN:
        shape(polyShape);
      }
    }
    popMatrix();
  }

  // default fixture creation
  void setupFixture(Shape _shape) {
    setupFixture(_shape, 0.2f, 1.f, 0.1f, new Filter(), false);
  }

  // detailed fixture creation
  void setupFixture(Shape _shape, float _friction, float _density, float _restitution, Filter _filter, boolean _isSensor) {
    //fixture
    fixtureDef = new FixtureDef();
    fixtureDef.shape = _shape; // collider shape
    fixtureDef.friction = _friction; // friction against other objects
    fixtureDef.density = _density; // mass
    fixtureDef.restitution = _restitution; // "bounciness"
    fixtureDef.filter =_filter; // collision filter
    fixtureDef.isSensor = _isSensor; // sensors will produce contact information, but won't collide
  }

  // vertex buffer creation
  void setupPolyshape() {
    ShapeType type = fixtureDef.shape.getType();
    if (type == ShapeType.POLYGON) {
      PolygonShape ps = (PolygonShape) fixtureDef.shape;
      int numV = ps.getVertexCount();
      Vec2[] v = new Vec2[numV];
      for (int i = 0; i < numV; ++i) {
        v[i] = ps.getVertex(i);
      }

      polyShape = createShape();
      polyShape.beginShape();
      polyShape.noStroke();
      polyShape.fill(255, 255);
      for (int i = 0; i < numV; ++i) {
        Vec2 vert2 = v[i];
        polyShape.vertex(mBox2D.scalarWorldToPixels(vert2.x), mBox2D.scalarWorldToPixels(-vert2.y));
      }
      polyShape.endShape(CLOSE);
    } else if (type == ShapeType.CHAIN) {
      polyShape = createShape();
      polyShape.beginShape();
      polyShape.noFill();
      polyShape.stroke(255, 255);
      polyShape.strokeWeight(1);
      ChainShape cs = (ChainShape) fixtureDef.shape;
      int numV = cs.m_count;
      Vec2[] v = new Vec2[numV];
      for (int i = 0; i < numV-1; ++i) {
        Vec2 pos2 = mBox2D.vectorWorldToPixels(cs.m_vertices[i]);
        Vec2 pos3 = mBox2D.vectorWorldToPixels(cs.m_vertices[i+1]);
        polyShape.vertex(pos2.x, pos2.y);
        polyShape.vertex(pos3.x, pos3.y);
      }
      polyShape.endShape();
    } else if (type == ShapeType.CIRCLE) {
      polyShape = ReusablePShapes.getCircle();
    }
  }

  // box2D body setup
  void setupBody(BodyType _type, Vec2 _pos, float _linearDamping) {
    bodyDef = new BodyDef();
    bodyDef.type = _type; // DYNAMIC = reacts to gravity, STATIC does not move/react to gravity, KINEMATIC = user-moved
    bodyDef.position = mBox2D.coordPixelsToWorld(_pos.x, _pos.y);
    bodyDef.setLinearDamping(_linearDamping);
  }

  // box2D body creation (call setupBody and setupFixture first)
  void createBody() {
    mBody = mBox2D.world.createBody(bodyDef);
    mBody.createFixture(fixtureDef);
    mBody.setUserData(this);
  }
}

