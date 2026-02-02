#!/usr/bin/env python3
"""
Mandelbrot Fractal Generator - Fixed version
"""

import os
os.environ['MPLCONFIGDIR'] = '/tmp/matplotlib'

from flask import Flask, request, Response
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import io
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1)

@app.route('/')
def root():
    """Root endpoint with instructions"""
    return """<h1>Fractal Generator</h1>
    <p>Access via:</p>
    <ul>
        <li><a href="/status">/status</a></li>
        <li><a href="/light">/light</a> (test)</li>
        <li><a href="/fractal?w=800&h=600">/fractal?w=800&h=600</a></li>
        <li><a href="/fractal?w=4000&h=4000&iter=1000">Heavy load test</a></li>
    </ul>"""

@app.route('/status')
def status():
    return "Fractal generator is running\nUse /light for test, /fractal?w=W&h=H&iter=I for generation"

@app.route('/light')
def light_fractal():
    """Lightweight test - minimal resources"""
    width, height = 400, 300
    x = np.linspace(-2.5, 1.5, width)
    y = np.linspace(-2.0, 2.0, height)
    c = x[:, np.newaxis] + 1j * y[np.newaxis, :]
    
    z = np.zeros(c.shape, dtype=np.complex128)
    fractal = np.zeros(c.shape, dtype=int)
    
    for i in range(30):
        mask = np.abs(z) < 4
        z[mask] = z[mask]**2 + c[mask]
        fractal[mask] = i
    
    fig, ax = plt.subplots(figsize=(4, 3))
    ax.imshow(fractal.T, cmap='hot', origin='lower')
    ax.axis('off')
    fig.tight_layout(pad=0)
    
    buf = io.BytesIO()
    fig.savefig(buf, format='png', bbox_inches='tight', pad_inches=0)
    plt.close(fig)
    buf.seek(0)
    
    return Response(buf.getvalue(), mimetype='image/png')

@app.route('/fractal')
def generate_fractal():
    """Generate Mandelbrot - CPU intensive!"""
    width = int(request.args.get('w', 800))
    height = int(request.args.get('h', 600))
    zoom = float(request.args.get('zoom', 1.0))
    max_iter = int(request.args.get('iter', 100))
    
    print(f"[Fractal] Generating {width}x{height} (iter={max_iter})")
    
    # Limit for safety (but you can remove for DoS testing)
    width = min(width, 5000)
    height = min(height, 5000)
    max_iter = min(max_iter, 2000)
    
    x = np.linspace(-2.5/zoom, 1.5/zoom, width)
    y = np.linspace(-2.0/zoom, 2.0/zoom, height)
    c = x[:, np.newaxis] + 1j * y[np.newaxis, :]
    
    z = np.zeros(c.shape, dtype=np.complex128)
    fractal = np.zeros(c.shape, dtype=int)
    
    for i in range(max_iter):
        mask = np.abs(z) < 50
        z[mask] = z[mask]**2 + c[mask]
        fractal[mask] = i
    
    fig, ax = plt.subplots(figsize=(width/100, height/100), dpi=100)
    ax.imshow(fractal.T, cmap='hot', origin='lower')
    ax.axis('off')
    fig.tight_layout(pad=0)
    
    buf = io.BytesIO()
    fig.savefig(buf, format='png', bbox_inches='tight', pad_inches=0)
    plt.close(fig)
    buf.seek(0)
    
    return Response(buf.getvalue(), mimetype='image/png')

if __name__ == '__main__':
    # Create matplotlib temp dir
    os.makedirs('/tmp/matplotlib', exist_ok=True)
    
    app.run(
        host='0.0.0.0', 
        port=5000, 
        threaded=False,  # Single-threaded = easier to DoS
        debug=False
    )
