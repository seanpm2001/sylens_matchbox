uniform sampler2D input1;
uniform float adsk_input1_w, adsk_input1_h, adsk_input1_aspect;
uniform float kCoeff, kCube;
uniform float adsk_result_w, adsk_result_h;
uniform bool doRedisto;

vec2 redisto(vec2 pt) {
  float r, rp, f, rlim, rplim, raw, err, slope;
  float _aspect = adsk_input1_w / adsk_input1_h;
  vec2 res;
  
  rp = sqrt(_aspect * _aspect * pt.x * pt.x + pt.y * pt.y);
  if (kCoeff < 0.0) {
    rlim = sqrt((-1.0/3.0) / kCoeff);
    rplim = rlim * (1 + kCoeff*rlim*rlim);
    if (rp >= 0.99 * rplim) {
      f = rlim / rp;
      return pt * f;
    }
  }

  r = rp;
  for (int i = 0; i < 20; i++) {
    raw = kCoeff * r * r;
    slope = 1 + 3*raw;
    err = rp - r * (1 + raw);
    if (abs(err) < 0.00001) break;
    r += (err / slope);
  }
  f = r / rp;
  
  // For the pixel in the middle of the image the F can
  // be NaN, so check for that and leave it be.
  // http://stackoverflow.com/questions/570669/checking-if-a-float-or-float-is-nan-in-c
  // If a NaN F does crop up it creates a black pixel in the image - not something we love
  if(f == f) {
    res = pt * f;
  }
  return res;
}

vec2 undisto(vec2 pt) {
  
  // Skipping the square root speeds up things
  if (abs(kCube) > 0.00001) {
    f = 1 + r2*(kCoeff + kCube * sqrt(r2));
  } else {
    f = 1 + r2*(kCoeff);
  }
  float f = 1 + r2*(kCoeff);
  return uv * f;
}

void main(void)
{
   vec2 uv = gl_FragCoord.xy / vec2(adsk_input1_w, adsk_input1_h);
   uv = uv - 0.5;
   
   float _aspect = adsk_input1_w / adsk_input1_h;
   float r2 = _aspect * _aspect * uv.x * uv.x + uv.y * uv.y;
   if(doRedisto) {
     uv = undisto(uv);
   } else {
     uv = redisto(uv);
   }
   
   uv = uv + 0.5;
   vec4 tex0 = texture2D(input1, uv);
   gl_FragColor.rgba = vec4(tex0.rgb, 1.0 );
}
