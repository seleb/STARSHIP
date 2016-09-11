class ParticleSystem implements Updatable, Drawable {

  ArrayList<Particle> particles;

  Box2DProcessing mBox2D;
  ParticleSystem(Box2DProcessing _context) {
    mBox2D = _context;
    particles = new ArrayList<Particle>();
  }

  Particle addParticle(float _radius, float _x, float _y, color _c1, color _c2) {
    Particle t = new Particle(_radius, _x, _y, _c1, _c2, mBox2D);
    particles.add(t);
    t.parent = this;
    return t;
  }

  void update() {
    for (int i = particles.size ()-1; i >= 0; --i) {
      Particle p = particles.get(i);
      p.update();
      if (!p.alive) {
        p.destroy();
        particles.remove(i);
      }
    }
  }

  void draw() {
    for (Drawable p : particles) {
      p.draw();
    }
  }
}

