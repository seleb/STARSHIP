// box2D elements based on random convex polygons
public class RandomPolygon extends Box2DBase {

  private static final int minPolygonPoints = 3;
  private static final int maxPolygonPoints = 8;

  int numVerts;
  float radius;

  RandomPolygon(Box2DProcessing _context) {
    super(_context);
  }

  RandomPolygon(float _radius, int _numVerts, float _x, float _y, Box2DProcessing _context) {
    super(_context);
    numVerts = min(maxPolygonPoints, max(minPolygonPoints, _numVerts));
    radius = _radius;
    Shape s = setupShape(_radius);


    //fixture
    setupFixture(s, 0.0f, 1.f, 0.1f, new Filter(), false);
    setupPolyshape();
    setupBody(BodyType.DYNAMIC, new Vec2(_x, _y), 0.f);
    createBody();
  }

  Shape setupShape(float _radius) {
    // shape
    PolygonShape shape = new PolygonShape();

    Vec2[] verts = new Vec2[numVerts];

    for (int i = 0; i < numVerts; i++) {
      float angle = map(i, 0, numVerts-1, 0, TWO_PI);
      verts[i] = new Vec2();
      verts[i].x = _radius*cos(angle);
      verts[i].y = _radius*sin(angle);
    }
    shape.set(verts, numVerts);
    return shape;
  }

  void setupPolyshape() {
    polyShape = ReusablePShapes.getPolygon(numVerts);
  }

  void draw() {
    // easier to scale/reset the polyShape than to interfere with the existing matrix stack
    polyShape.scale(mBox2D.scalarWorldToPixels(radius));
    super.draw();
    polyShape.resetMatrix();
  }
}

