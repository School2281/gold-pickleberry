#!/usr/bin/env python3
"""
Mandelbrot Fractal Generator - Resource Intensive for DoS Testing
WARNING: This consumes massive CPU and memory. Use only in controlled environments.
"""

from flask import Flask, request, Response
import numpy as np
import matplotlib
matplotlib.use('Agg')  # No GUI - server only
import matplotlib.pyplot as plt
import io
import time

app = Flask(__name__)

@app.route('/fractal')
def generate_fractal():
    """
    Generate Mandelbrot fractal. 
    WARNING: CPU intensive! Parameters control resource usage.
    """
    # Get parameters with safe defaults
    width = int(request.args.get('w', 800))
    height = int(request.args.get('h', 800))
    zoom = float(request.args.get('zoom', 1.0))
    max_iter = int(request.args.get('iter', 100))
    
    print(f"[Fractal] Generating {width}x{height} (zoom={zoom}, iter={max_iter})")
    
    # Generate coordinates
    x = np.linspace(-2.5/zoom, 1.5/zoom, width)
    y = np.linspace(-2.0/zoom, 2.0/zoom, height)
    c = x[:, np.newaxis] + 1j * y[np.newaxis, :]
    
    # Mandelbrot calculation - THE CPU-HEAVY PART
    z = np.zeros(c.shape, dtype=np.complex128)
    fractal = np.zeros(c.shape, dtype=int)
    
    for i in range(max_iter):
        mask = np.abs(z) < 50  # Points still in set
        z[mask] = z[mask]**2 + c[mask]
        fractal[mask] = i
    
    # Create image
    fig, ax = plt.subplots(figsize=(width/100, height/100), dpi=100)
    ax.imshow(fractal.T, cmap='hot', origin='lower')
    ax.axis('off')
    fig.tight_layout(pad=0)
    
    # Save to bytes buffer
    buf = io.BytesIO()
    fig.savefig(buf, format='png', bbox_inches='tight', pad_inches=0)
    plt.close(fig)  # Free memory
    buf.seek(0)
    
    return Response(buf.getvalue(), mimetype='image/png')

@app.route('/light')
def light_fractal():
    """Lightweight version for testing - minimal resource usage"""
    width, height = 400, 400
    x = np.linspace(-2.5, 1.5, width)
    y = np.linspace(-2.0, 2.0, height)
    c = x[:, np.newaxis] + 1j * y[np.newaxis, :]
    
    z = np.zeros(c.shape, dtype=np.complex128)
    fractal = np.zeros(c.shape, dtype=int)
    
    for i in range(50):  # Fewer iterations
        mask = np.abs(z) < 4
        z[mask] = z[mask]**2 + c[mask]
        fractal[mask] = i
    
    fig, ax = plt.subplots()
    ax.imshow(fractal.T, cmap='hot', origin='lower')
    ax.axis('off')
    
    buf = io.BytesIO()
    fig.savefig(buf, format='png', bbox_inches='tight')
    plt.close(fig)
    buf.seek(0)
    
    return Response(buf.getvalue(), mimetype='image/png')

@app.route('/status')
def status():
    """Check if fractal generator is running"""
    return "Fractal generator is running\nUse:\n  /light - Test image\n  /fractal?w=800&h=800&iter=100 - Normal\n  /fractal?w=4000&h=4000&iter=1000 - DoS test"

if __name__ == '__main__':
    # Run single-threaded to make it more vulnerable
    app.run(host='0.0.0.0', port=5000, threaded=False, debug=False)
